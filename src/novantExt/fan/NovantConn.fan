//
// Copyright (c) 2019, Novant LLC
// All Rights Reserved
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
    // TODO: add a low-cost / ping endpoint
    reqPoints
    return Etc.emptyDict
  }

//////////////////////////////////////////////////////////////////////////
// Cur
//////////////////////////////////////////////////////////////////////////

  override Void onSyncCur(ConnPoint[] points)
  {
    try
    {
      // short-circuit if polling under 1min
      now := DateTime.nowTicks
      if (now - lastValuesTicks < 1min.ticks) return
      this.lastValuesTicks = now

      // request values
      c := makeWebClient(`https://api.novant.io/v1/values`)
      c.postForm([
        "device_id": deviceId,
        "last_ts":   lastValuesTs.toIso,
      ])

      // check response codes
      if (c.resCode == 304) return
      if (c.resCode == 503) throw IOErr("Unavailable")

      // WebClient will throw internally for non-200 when we read `in`
      Str:Obj res := JsonInStream(c.resStr.in).readJson
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

          // read fault (TODO: pull thru error codes?)
          if (val isnot Float) throw IOErr("Fault")

          // ok
          pt.updateCurOk(Number.make(val, pt.unit))
        }
        catch (Err err) { pt?.updateCurErr(err) }
      }
    }
    catch (Err err) { close(err) }
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
    // TODO: cache this data for ~1-5min?
    gb := GridBuilder()
    gb.addColNames(["dis","learn","point","kind","novantCur","novantHis","unit"])

    Obj[] sources := reqPoints["sources"]
    if (arg is Number)
    {
      Int i := ((Number)arg).toInt
      Map s := sources[i]
      Obj[] points := s["points"]
      points.each |Map p|
      {
        id   := p["id"]
        dis  := p["name"]
        kind := "Number"
        cur  := "${id}"
        his  := "${id}"
        unit := p["unit"]
        gb.addRow([dis, null, Marker.val, kind, cur, his, unit])
      }
    }
    else
    {
      sources.each |Map s, Int i|
      {
        dis  := s["name"]
        learn := Number.makeInt(i)
        gb.addRow([dis, learn, null, null, null,null, null])
      }
    }

    return gb.toGrid
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  ** Request points list from configured device.
  private Str:Obj reqPoints()
  {
    now := Duration.nowTicks
    if (lastReq == null || now-lastPointsTicks > 1min.ticks)
    {
      c := makeWebClient(`https://api.novant.io/v1/points`)
      c.postForm(["device_id": deviceId])
      this.lastReq = JsonInStream(c.resStr.in).readJson
    }
    this.lastPointsTicks = now
    return lastReq
  }

  ** Create an authorizd WebClient instance for given endpoint.
  private WebClient makeWebClient(Uri uri)
  {
    c := WebClient(uri)
    c.reqHeaders["Authorization"] = "Basic " + "${apiKey}:".toBuf.toBase64
    c.reqHeaders["Accept-Encoding"] = "gzip"
    return c
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Obj? lastReq
  private Int lastPointsTicks

  // lastTicks is our interal counter; lastTs is API argument
  private Int lastValuesTicks
  private DateTime lastValuesTs := DateTime.defVal

  internal Str apiKey()     { ext.proj.passwords.get(rec.id.toStr) ?: "" }
  internal Str deviceId()   { rec->novantDeviceId }
  internal Date? hisStart() { rec["novantHisStart"] }
  internal Date? hisEnd()   { rec["novantHisEnd"]   }
}

