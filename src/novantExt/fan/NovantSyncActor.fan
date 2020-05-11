//
// Copyright (c) 2020, Novant LLC
// All Rights Reserved
//
// History:
//   11 May 2020  Andy Frank  Creation
//

using concurrent
using haystack
using util
using web

*************************************************************************
** NovantSyncActor
*************************************************************************

** NovantSyncActor manages dispatching NovantSyncWorkers.
const class NovantSyncActor
{
  new make(NovantExt ext)
  {
    this.ext  = ext
    this.pool = ActorPool { it.name="NovantSyncActorPool"; it.maxThreads=10 }
  }

  ** Check for any connectors that need to be synced.
  Void checkSyncs()
  {
    // TODO
  }

  **
  ** Dispatch a new background actor to perform a trend sync for
  ** the given 'conn' and 'span' range.  If 'span' is 'null', a
  ** sync will be performed from 'Date.today - novantLasySync'.
  ** If 'novantLastSync' is not defined, only 'Date.today' will
  ** be synced.
  ***
  Void dispatchSync(NovantConn conn, Span? span)
  {
// TODO
if (span == null) span = Span.today

    worker := NovantSyncWorker(conn, span, ext.log)
    actor  := Actor(pool) |m| { worker.sync; return null }
    actor.send("run")
  }

  private const NovantExt ext
  private const ActorPool pool
}

*************************************************************************
** NovantSyncWorker
*************************************************************************

** NovantSyncActor peforms the trend sync work.
const class NovantSyncWorker
{
  ** Constructor.
  new make(NovantConn conn, Span span, Log log)
  {
    this.connUnsafe = Unsafe(conn)
    this.span = span
    this.log  = log
  }

  ** Performance REST API call and updateHisOk/Err work.
  Void sync()
  {
    conn := this.conn
    log.info("---> sync ${conn.dis} @ ${span}")

    /*
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
    */
  }

  private NovantConn conn() { connUnsafe.val }
  private const Unsafe connUnsafe
  private const Span span
  private const Log log
}
