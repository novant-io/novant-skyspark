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
  new make(ConnActor actor, Dict rec) : super(actor, rec) {}

  override Obj? receive(ConnMsg msg) { return super.receive(msg) }

  override Void onOpen() {}

  override Void onClose() {}

  override Dict onPing()
  {
    // TODO: add a low-cost / ping endpoint
    reqPoints
    return Etc.emptyDict
  }

  override Grid onLearn(Obj? arg)
  {
    Obj[] points := reqPoints["points"]
    gb := GridBuilder()
    gb.addColNames(["dis","point","kind","novantHis"])
    points.each |Map p|
    {
      id   := p["id"]
      dis  := p["name"]
      kind := "Number"
      his  := "${id}"
      gb.addRow([dis, Marker.val, kind, his])
    }
    return gb.toGrid
  }

  override Obj? onSyncHis(ConnPoint point, Span span)
  {
    try
    {
      // TODO:
      //   - support for dates={start..end} param
      //   - support for point_id flag
      //   - support for passing in time_zone?
      //   - support for non-Number types?
      items := HisItem[,]
      span.eachDay |date|
      {
        c := WebClient(`https://api.novant.io/v1/trends`)
        c.reqHeaders["Authorization"] = "Basic " + "${apiKey}:".toBuf.toBase64
        c.postForm(["device_id": deviceId, "date": date.toStr])

        Map map := JsonInStream(c.resStr.in).readJson
        (map["data"] as List).each |Map entry|
        {
          id  := point.rec["novantHis"].toStr.toInt
          ts  := DateTime.fromIso(entry["ts"]).toTimeZone(point.tz)
          val := entry["p${id}"]
          if (val != null) items.add(HisItem(ts, Number.make(val)))
        }
      }
      return point.updateHisOk(items, span)
    }
    catch (Err err)
    {
      return point.updateHisErr(err)
    }
  }

  ** Request points list from configured device.
  private Str:Obj reqPoints()
  {
    c := WebClient(`https://api.novant.io/v1/points`)
    c.reqHeaders["Authorization"] = "Basic " + "${apiKey}:".toBuf.toBase64
    c.postForm(["device_id": deviceId])
    return JsonInStream(c.resStr.in).readJson
  }

  private Str apiKey()   { ext.proj.passwords.get(rec.id.toStr) ?: "" }
  private Str deviceId() { rec->deviceId }
}

