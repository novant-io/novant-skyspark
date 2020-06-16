//
// Copyright (c) 2020, Novant LLC
// All Rights Reserved
//
// History:
//   11 May 2020  Andy Frank  Creation
//

using concurrent
using folio
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

  **
  ** Dispatch a new background actor to perform a trend sync for
  ** the given 'conn' and 'span' range.  If 'span' is 'null', a
  ** sync will be performed from 'Date.today - novantLasySync'.
  ** If 'novantLastSync' is not defined, only 'Date.today' will
  ** be synced.
  ***
  Void dispatchSync(NovantConn conn, DateSpan? span)
  {
    // if span not defined, determine the range based on hisEnd;
    // if still null then this conn is already synced thru today
    // and we can short-circuit
    if (span == null) span = defSpan(conn.hisEnd)
    if (span == null) return

    worker := NovantSyncWorker(conn, span, ext.log)
    actor  := Actor(pool) |m| { worker.sync; return null }
    actor.send("run")
  }

  ** Get default span based on given 'hisEnd' date, or return 'null'
  ** if the span is already up-to-date.
  internal static DateSpan? defSpan(Date? hisEnd)
  {
    // short-circuit if already up-to-date
    yesterday := Date.yesterday
    if (hisEnd >= yesterday) return null

    // find range
    start := hisEnd==null ? yesterday : hisEnd+1day
    return DateSpan(start, yesterday)
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
  new make(NovantConn conn, DateSpan span, Log log)
  {
    this.connUnsafe = Unsafe(conn)
    this.span = span
    this.log  = log
  }

  ** Performance REST API call and updateHisOk/Err work.
  Void sync()
  {
    // TODO:
    //   - support for point_id(s) filter?
    //   - support for passing in time_zone?
    //   - support for non-Number types?

    try
    {
      conn := this.conn
      span.eachDay |date|
      {
        start := Duration.now

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

        // update hisStart/End
        if (conn.hisStart == null) commit("novantHisStart", date)
        if (conn.hisEnd == null || conn.hisEnd < date) commit("novantHisEnd", date)

        // log metrics
        end := Duration.now
        dur := (end - start).toMillis
        log.info("syncHis successful for '${conn.dis}' @ ${dayspan}" +
                 " [${conn.points.size} points, ${dur.toLocale}ms]")
      }
    }
    catch (Err err) { log.err("syncHis failed for '${conn.dis}'", err) }
  }

  ** Update conn tag.
  private Void commit(Str tag, Obj val)
  {
    // pull rec to make sure we have the most of up-to-date
    rec := conn.ext.proj.readById(conn.rec.id)
    conn.ext.proj.commit(Diff(rec, [tag:val]))
  }

  private NovantConn conn() { connUnsafe.val }
  private const Unsafe connUnsafe
  private const DateSpan span
  private const Log log
}
