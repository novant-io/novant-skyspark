//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019   Andy Frank   Creation
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
      case "nvSync": ext.syncActor.dispatchSync(this, msg.a, msg.b); return null
      default:       return super.receive(msg)
    }
  }

  override Void onOpen() {}

  override Void onClose() {}

  override Dict onPing()
  {
    NovantClient(apiKey).ping(deviceId)
    return Etc.emptyDict
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
      if (now - lastValuesTicks < 1min.ticks) return
      this.lastValuesTicks = now

      // TODO: can this be cached somewhere?
      // get comma-sep point id list
      pointIds := StrBuf()
      points.each |p|
      {
        id := p.rec["novantCur"]
        if (id != null) pointIds.join(id, ",")
      }

      // request values
      Str:Obj? res := NovantClient(apiKey).vals(deviceId, pointIds.toStr, lastValuesTs)
      this.lastValuesTs = DateTime.fromIso(res["ts"])

      // TODO: can this be cached somewhere?
      map := Str:ConnPoint[:]
      points.each |p| { map.set(p.rec["novantCur"], p) }

      // update curVals
      Obj[] data := res["data"]
      data.each |Map r|
      {
        ConnPoint? pt
        try
        {
          id  := r["id"]
          val := r["val"]

          // point not found
          pt = map[id]
          if (pt == null) return

          // sanity check to disallow his collection
          if (pt.rec.has("hisCollectCov") || pt.rec.has("hisCollectInterval"))
            throw ArgErr("hisCollect not allowed")

          // convert and update
          pval := NovantUtil.toConnPointVal(pt, val)
          pt.updateCurOk(pval)
        }
        catch (Err err) { pt?.updateCurErr(err) }
      }
    }
    catch (Err err) { close(err) }
  }

//////////////////////////////////////////////////////////////////////////
// Write
//////////////////////////////////////////////////////////////////////////

  override Void onWrite(ConnPoint point, Obj? val, Number level)
  {
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
      NovantClient(apiKey).write(deviceId, pid, fval, pri)

      // update ok
      point.updateWriteOk(val, level)
    }
    catch (Err err) { point.updateWriteErr(val, level, err) }
  }

//////////////////////////////////////////////////////////////////////////
// His
//////////////////////////////////////////////////////////////////////////

  override Obj? onSyncHis(ConnPoint point, Span span)
  {
    // onSyncHis is a no-op; all his sync is handled internally
    null
  }

//////////////////////////////////////////////////////////////////////////
// Learn
//////////////////////////////////////////////////////////////////////////

  override Grid onLearn(Obj? arg)
  {
    gb := GridBuilder()
    gb.addColNames(["dis","learn","point","kind","novantCur","novantWrite","novantHis","unit"])

    // cache points results for 1min
    now := Duration.nowTicks
    if (now-lastPointsTicks > 1min.ticks) this.pointsReq = NovantClient(apiKey).points(deviceId)
    this.lastPointsTicks = now

    Obj[] sources := pointsReq["sources"]
    if (arg is Number)
    {
      Int i := ((Number)arg).toInt
      Map s := sources[i]
      Obj[] points := s["points"]
      points.each |Map p|
      {
        id   := p["id"]
        dis  := p["name"]
        kind := p["kind"] == "bool" ? "Bool" : "Number"
        cur  := "${id}"
        wrt  := p["writable"] == true ? "${id}" : null
        his  := "${id}"
        unit := p["unit"]
        gb.addRow([dis, null, Marker.val, kind, cur, wrt, his, unit])
      }
    }
    else
    {
      sources.each |Map s, Int i|
      {
        dis  := s["name"]
        learn := Number.makeInt(i)
        gb.addRow([dis, learn, null, null, null, null, null, null])
      }
    }

    return gb.toGrid
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Str:Obj? pointsReq := [:]
  private Int lastPointsTicks

  // lastTicks is our interal counter; lastTs is API argument
  private Int lastValuesTicks
  private DateTime lastValuesTs := DateTime.defVal

  // prior to 3.0.29 (?) apiKey was stored as plain-text tag; so allow
  // fallback if not found in the password manager
  internal Str apiKey()     { ext.proj.passwords.get(rec.id.toStr) ?: rec->apiKey }
  internal Str deviceId()   { rec->novantDeviceId }
  internal Date? hisStart() { rec["novantHisStart"] }
  internal Date? hisEnd()   { rec["novantHisEnd"]   }
}