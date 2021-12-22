//
// Copyright (c) 2020, Novant LLC
// Licensed under the MIT License
//
// History:
//   11 May 2020  Andy Frank  Creation
//

using concurrent
using connExt
using folio
using haystack
using util
using web

*************************************************************************
** NovantSyncActor
*************************************************************************

** NovantSyncActor manages dispatching NovantSyncWorkers.
internal const class NovantSyncActor
{
  new make(NovantExt ext)
  {
    this.ext  = ext
    this.pool = ActorPool { it.name="NovantSyncActorPool"; it.maxThreads=10 }
  }

  **
  ** Dispatch a new background actor to perform a trend sync for
  ** the given 'conn' and 'span' range.
  ***
  Void dispatchSync(NovantConn conn, Obj? span, Dict? opts)
  {
    // default opts
    if (opts == null) opts = Etc.emptyDict

    // convert to Span
    if (span is Date) span = DateSpan.make(span)
    if (span is DateSpan) span = ((DateSpan)span).toSpan(conn.tz)

    worker := NovantSyncWorker(conn, span, opts, ext.log)
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
  new make(NovantConn conn, Span? span, Dict opts, Log log)
  {
    this.connUnsafe = Unsafe(conn)
    this.span = span
    this.log  = log
  }

  ** Perform REST API call and updateHisOk/Err work.
  Void sync()
  {
    try
    {
      // short-circuit if disabled
      conn := this.conn
      if (conn.isDisabled) return

      // short-circuit if no points
      if (conn.points.isEmpty) return

      // map his points to working data structure
      points := NovantSyncPoint[,]
      refs   := Ref[,]
      tz     := conn.tz
      tm     := Date.today(tz).midnight
      conn.points.each |p|
      {
        if (p.rec["novantHis"] is Str)
        {
          points.add(NovantSyncPoint(p))
          refs.add(p.id)
        }
      }

      // refresh backing rec for each point (the conn.point.rec instance
      // gets cached on conn.open; so we need to update to latest copy;
      // also use this loop to find last hisStart/End across all points
      recs := conn.ext.proj.readByIdsList(refs)
      rmap := Ref:Dict[:].setList(recs) |r| { r.id }

      // collect points and recs into working sync point set
      DateTime? hstart
      DateTime? hend
      points.each |p|
      {
        p.rec  = rmap[p.ref]
        hstart = NovantUtil.minDateTime(hstart, p.hisStart)
        hend   = NovantUtil.maxDateTime(hstart, p.hisEnd)
      }

      // if span is null, fallback to default which is hend+interval..today;
      // or if hend is 'null' then yesterday..today
      span := this.span
      if (span == null)
      {
        span = hend != null
          ? Span(hend + conn.hisIntervalDur, tm)
          : Span(Date.yesterday(tz).midnight, tm)
      }

      // clamp span.end to today
      if (span.end > tm) span = Span(span.start, tm)

      // sync each date
      span.eachDay |date|
      {
        ts1 := Duration.now

        // collect points that need to be synced for this date
        syncPoints := points.findAll |p| { p.needSync(date) }
        syncIds    := syncPoints.join(",") |p| { p.novantHis }

        // skip this day if no points found
        if (syncPoints.isEmpty) return

        // request trend data
        res := conn.client.trends(conn.deviceId, syncIds, date, conn.hisInterval)
        List data := res["data"]

        // cache updateHisOk clip param
        cstart := date.midnight(tz)
        cend   := (date+1day).midnight(tz)
        clip   := Span.makeAbs(cstart, cend)

        // iterate by point to add his items
        syncPoints.each |p|
        {
          try
          {
            items := HisItem[,]
            data.each |Map entry|
            {
              ts  := DateTime.fromIso(entry["ts"]).toTimeZone(tz)
              val := entry["${p.novantHis}"] as Float
              if (val != null)
              {
                pval := NovantUtil.toConnPointVal(p.cp, val)
                items.add(HisItem(ts, pval))
              }
            }
            p.cp.updateHisOk(items, clip)
          }
          catch (Err err) { p.cp.updateHisErr(err) }
        }

        // log metrics
        ts2 := Duration.now
        dur := (ts2 - ts1).toMillis
        log.info("syncHis successful for '${conn.dis}' @ ${date}" +
                 " [${syncPoints.size} points, ${dur.toLocale}ms]")
      }
    }
    catch (Err err) { log.err("syncHis failed for '${conn.dis}'", err) }
  }

  private NovantConn conn() { connUnsafe.val }
  private const Unsafe connUnsafe
  private const Span? span
  private const Log log
}

*************************************************************************
** NovantSyncPoint
*************************************************************************

internal class NovantSyncPoint
{
  new make(ConnPoint p) { this.cp = p }

  ConnPoint cp   // backing ConnPoint
  Dict? rec      // working copy of backing rec

  Ref ref()            { cp.id }              // skyspark point id
  Str novantHis()      { rec["novantHis"] }   // 'pxx' point id
  DateTime? hisStart() { rec["hisStart"]  }   // 'hisStart' or null
  DateTime? hisEnd()   { rec["hisEnd"]    }   // 'hisEnd' or null
  Duration hisInterval() { ((NovantConn)cp.conn).hisIntervalDur }

  ** Return true if this point needs to sync given date.
  Bool needSync(Date d)
  {
    // always sync if no his yet
    if (hisStart == null || hisEnd == null) return true

    // sync if date is before or after current his range
    if (d.midnight(cp.tz) < hisStart) return true
    if ((d+1day).midnight(cp.tz) > (hisEnd + hisInterval)) return true

    // no sync needed
    return false
  }
}

