//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019   Andy Frank   Creation
//    8 Dec 2022  Andy Frank  Update to Apollo
//

using connExt
using haystack
using util
using web

**
** NovantConn
**
class NovantConn : Conn
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  new make(ConnActor actor, Dict rec) : super(actor, rec) {}

  override Obj? receive(ConnMsg msg)
  {
    NovantExt ext := ext
    switch (msg.id)
    {
      default: return super.receive(msg)
    }
  }

  override Void onOpen() {}

  override Void onClose() {}

  override Dict onPing()
  {
    meta := client.proj
    return Etc.makeDict([
      "novantProj": meta["proj_name"]
    ])
  }

//////////////////////////////////////////////////////////////////////////
// Cur
//////////////////////////////////////////////////////////////////////////

  override Void onSyncCur(ConnPoint[] points)
  {
    try
    {
      // short-circuit if no points
      if (points.size == 0) return

      // short-circuit if polling under 1min
      now := DateTime.nowTicks
      if (now - lastValsTicks < 1min.ticks) return
      this.lastValsTicks = now

      // get source ids from points list
      pmap := Str:ConnPoint[:]
      smap := Str:Str[:]
      points.each |p|
      {
        id := p.rec["novantCur"]
        if (id != null)
        {
          pmap[id] = p
          sid := "s." + id.toStr.split('.')[1]
          smap[sid] = sid
        }
      }

      // request each source and update curVals
      smap.vals.each |sid|
      {
        vals := client.vals(sid)
        vals.each |res,id|
        {
          ConnPoint? pt
          try
          {
            // point not found
            pt = pmap[id]
            if (pt == null) return

            // sanity check to disallow his collection
            if (pt.rec.has("hisCollectCov") || pt.rec.has("hisCollectInterval"))
              throw ArgErr("hisCollect not allowed")

            // check remote status
            val := res["val"]
            status := res["status"]
            if (status != "ok") throw ArgErr("Remote fault")

            // convert and update
            pval := NovantUtil.toConnPointVal(pt, val)
            pt.updateCurOk(pval)
          }
          catch (Err err) { pt?.updateCurErr(err) }
        }
      }
    }
    catch (Err err) { close(err) }
  }

//////////////////////////////////////////////////////////////////////////
// Write
//////////////////////////////////////////////////////////////////////////

  override Void onWrite(ConnPoint point, Obj? val, Number level)
  {
    /*
    try
    {
      // convert to float
      Float? fval
      if (val is Number) fval = ((Number)val).toFloat
      if (val is Bool)   fval = val==true ? 1f : 0f

      // cap priority to max 16
      pri := level.toInt
      if (pri > 16) pri = 16

      // issue write
      pid := point.rec["novantWrite"]
      client.write(deviceId, pid, fval, pri)

      // update ok
      point.updateWriteOk(val, level)
    }
    catch (Err err) { point.updateWriteErr(val, level, err) }
    */
  }

//////////////////////////////////////////////////////////////////////////
// His
//////////////////////////////////////////////////////////////////////////

  override Obj? onSyncHis(ConnPoint p, Span span)
  {
    try
    {
      // get args
      pid := p.rec["novantHis"] ?: throw Err("Missing novantHis tag")
      sid := "s." + pid.toStr.split('.')[1]
      tz  := TimeZone(p.rec["tz"])

      // iterate span by date to request trends
      items := HisItem[,]
      span.eachDay |date|
      {
        client.trendsEach(date, sid, pid, tz) |ts,val|
        {
          if (val != null)
          {
            pval := NovantUtil.toConnPointVal(p, val)
            items.add(HisItem(ts, pval))
          }
        }
      }
      return p.updateHisOk(items, span)
    }
    catch (Err err) { return p.updateHisErr(err) }
  }

//////////////////////////////////////////////////////////////////////////
// Learn
//////////////////////////////////////////////////////////////////////////

  override Grid onLearn(Obj? arg)
  {
    gb := GridBuilder()
    gb.addColNames([
      "dis","learn","point","pointAddr","kind","novantCur","novantWrite","novantHis","unit"
    ])

    if (arg == null)
    {
      client.sources.each |s|
      {
        sid := s["id"]
        dis := s["name"]
        gb.addRow([dis, sid, null, null, null, null, null, null, null])
      }
    }
    else
    {
      client.points(arg).each |p|
      {
        id   := p["id"]
        dis  := p["name"]
        addr := p["addr"]
        kind := p["kind"] == "bool" ? "Bool" : "Number"
        cur  := "${id}"
        wrt  := p["writable"] == true ? "${id}" : null
        his  := "${id}"
        unit := p["unit"]
        gb.addRow([dis, null, Marker.val, addr, kind, cur, wrt, his, unit])
      }
    }

    return gb.toGrid
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // vals counter to throttle /values API reqs
  private Int lastValsTicks

  ** Get an authenicated NovantClient instance.
  internal NovantClient client()
  {
    apiKey := ext.proj.passwords.get("${rec.id} apiKey")
    if (apiKey == null) throw ArgErr("apiKey not found")
    return NovantClient(apiKey)
  }
}