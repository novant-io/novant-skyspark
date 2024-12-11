//
// Copyright (c) 2021, Novant LLC
// Licensed under the MIT License
//
// History:
//   12 Nov 2021  Andy Frank  Creation
//    8 Dec 2022  Andy Frank  Update to Apollo
//

using util
using web

**
** NovantClient
**
class NovantClient
{
  ** Constructor.
  new make(Str apiKey)
  {
    this.apiKey = apiKey
    this.skyVer = Pod.find("skyarcd").version.toStr
    this.extVer = NovantExt#.pod.version.toStr
  }

  ** Request project metadata. Throws 'IOErr' if request fails.
  Str:Obj? proj()
  {
    invoke("project", [:])
  }

  ** Request asset list for project. Throws 'IOErr' if request fails.
  [Str:Obj?][] assets()
  {
    res := invoke("assets", [:])
    return res["assets"]
  }

  ** Request source list for project. Throws 'IOErr' if request fails.
  [Str:Obj?][] sources()
  {
    res := invoke("sources", [:])
    return res["sources"]
  }

  ** Request point list for given asset or source. Throws 'IOErr' if request fails.
  [Str:Obj?][] points(Str id)
  {
    req := id.startsWith("a.") ? ["asset_id":id] : ["source_id":id]
    res := invoke("points", req)
    return res["points"]
  }

  ** Request current values for given source. Throws 'IOErr' if request fails.
  Str:Map vals(Str sourceId, Str[]? pointIds := null)
  {
    args := ["source_id":sourceId]
    if (pointIds != null) args["point_ids"] = pointIds.join(",")

    res := invoke("values", args)
    map := Str:Obj[:]
    List list := res["values"]
    list.each |Map r|
    {
      id := r["id"]
      map[id] = r
    }
    return map
  }

  ** Request trend date for given date. Throws 'IOErr' if request fails.
  Void trendsEach(Date date, Str sourceId, Str[] pointIds, TimeZone tz, |DateTime ts, Str pid, Obj? val| f)
  {
    args := [
      "date":      date.toStr,
      "source_id": sourceId,
      "point_ids": pointIds.join(","),
      "tz":        tz.name
    ]

    res := invoke("trends", args)
    List trends := res["trends"]
    trends.each |Map tr|
    {
      ts := DateTime.fromIso(tr["ts"]).toTimeZone(tz)
      tr.each |v,k|
      {
        if (k == "ts") return
        f(ts, k, v)
      }
    }
  }

  ** Invoke API request or throw IOErr if error.
  private Str:Obj? invoke(Str op, Str:Str args)
  {
    c := WebClient(`https://api.novant.io/v1/${op}`)
    c.reqHeaders["Authorization"] = "Basic " + "${apiKey}:".toBuf.toBase64
    c.reqHeaders["Accept-Encoding"] = "gzip"
    c.reqHeaders["User-Agent"] = "SkySpark/${skyVer} novantExt/${extVer}"
    c.postForm(args)

    // check for error
    Str:Obj? json := JsonInStream(c.resStr.in).readJson
    if (c.resCode != 200)
    {
      msg := json["msg"] ?: "Unexpected error (${c.resCode}); $json"
      throw IOErr(msg)
    }

    return json
  }

  private static const Str:Obj? empty := [:]

  private const Str apiKey
  private const Str skyVer
  private const Str extVer
}