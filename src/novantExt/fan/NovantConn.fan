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

  override Obj? receive(ConnMsg msg)
  {
    NovantExt ext := ext
    switch (msg.id)
    {
      case "nvSync": ext.syncActor.dispatchSync(this, msg.a); return null
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
    // onSyncHis is a no-op; all his sync is handled internally
    null
  }

  ** Request points list from configured device.
  private Str:Obj reqPoints()
  {
    c := WebClient(`https://api.novant.io/v1/points`)
    c.reqHeaders["Authorization"] = "Basic " + "${apiKey}:".toBuf.toBase64
    c.postForm(["device_id": deviceId])
    return JsonInStream(c.resStr.in).readJson
  }

  internal Str apiKey()     { ext.proj.passwords.get(rec.id.toStr) ?: "" }
  internal Str deviceId()   { rec->deviceId }
  internal Date? hisStart() { rec["novantHisStart"] }
  internal Date? hisEnd()   { rec["novantHisEnd"]   }
}

