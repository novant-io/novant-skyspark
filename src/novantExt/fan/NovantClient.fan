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
  new make(Str apiKey) { this.apiKey = apiKey }

  ** Request project metadata. Throws 'IOErr' if request fails.
  Str:Obj? proj()
  {
    invoke("project", [:])
  }

  ** Request source list for project. Throws 'IOErr' if request fails.
  [Str:Obj?][] sources()
  {
    res := invoke("sources", [:])
    return res["sources"]
  }

  ** Request point list for given source. Throws 'IOErr' if request fails.
  [Str:Obj?][] points(Str sourceId)
  {
    res := invoke("points", ["source_id":sourceId])
    return res["points"]
  }

  **
  ** Request current values for given source. Throws 'IOErr' if request fails.
  **
  Str:Map vals(Str sourceId)
  {
    map := Str:Obj[:]
    res := invoke("values", ["source_id":sourceId])
    List list := res["values"]
    list.each |Map r|
    {
      id := r["id"]
      map[id] = r
    }
    return map
  }

  ** Invoke API request or throw IOErr if error.
  private Str:Obj? invoke(Str op, Str:Str args)
  {
    c := WebClient(`https://api2.novant.io/v1/${op}`)
    c.reqHeaders["Authorization"] = "Basic " + "${apiKey}:".toBuf.toBase64
    c.reqHeaders["Accept-Encoding"] = "gzip"
    c.postForm(args)

    // check for error
    Str:Obj? json := JsonInStream(c.resStr.in).readJson
    if (c.resCode != 200)
    {
      msg := json["err_msg"] ?: "Unexpected error"
      throw IOErr(msg)
    }

    return json
  }

  private static const Str:Obj? empty := [:]

  private const Str apiKey
}