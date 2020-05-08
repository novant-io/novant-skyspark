//
// Copyright (c) 2020, Novant LLC
// All Rights Reserved
//
// History:
//   8 May 2020  Andy Frank  Creation
//

using haystack
using util
using web

*************************************************************************
** NovantSync
*************************************************************************

const class NovantSync
{
  ** Sync all points under given conn for the given 'span'.
  static Void syncHis(NovantConn conn, Span? span, Log log)
  {
    // TODO: this needs to moved to a background actor
    // TODO:
    //   - support for dates={start..end} param?
    //   - support for point_id(s) filter?
    //   - support for passing in time_zone?
    //   - support for non-Number types?

    try
    {
      span.eachDay |date|
      {
        // request data
        c := WebClient(`https://api.novant.io/v1/trends`)
        c.reqHeaders["Authorization"] = "Basic " + "${conn.apiKey}:".toBuf.toBase64
        c.postForm(["device_id": conn.deviceId, "date": date.toStr])

        // parse and cache response
        Map map   := JsonInStream(c.resStr.in).readJson
        List data := map["data"]
        dayspan   := Span(date.toLocale("YYYY-MM-DD")) // TODO: why is this so painful?

        // iterate by point to add his
        conn.points.each |point|
        {
          try
          {
            items := HisItem[,]
            data.each |Map entry|
            {
              id  := point.rec["novantHis"].toStr.toInt
              ts  := DateTime.fromIso(entry["ts"]).toTimeZone(point.tz)
              val := entry["p${id}"]
              if (val != null) items.add(HisItem(ts, Number.make(val)))
            }
            point.updateHisOk(items, dayspan)
          }
          catch (Err err) { point.updateHisErr(err) }
        }
      }
    }
    catch (Err err) { log.err("syncHis failed", err) }
  }
}