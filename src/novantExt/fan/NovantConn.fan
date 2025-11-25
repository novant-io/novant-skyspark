//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019  Andy Frank  Creation
//    8 Dec 2022  Andy Frank  Update to Apollo
//

using concurrent
using connExt
using folio
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
      // API access
      case "novant_proj":    return NovantUtil.toGrid([client.proj])
      case "novant_zones":   return NovantUtil.toGrid(client.zones)
      case "novant_spaces":  return NovantUtil.toGrid(client.spaces)
      case "novant_assets":  return NovantUtil.toGrid(client.assets)
      case "novant_sources": return NovantUtil.toGrid(client.sources)
      case "novant_points":  return NovantUtil.toGrid(client.points(msg.a))

      // SkySpark
      case "novant_batch_sync_his": doBatchSyncHis(msg.a, msg.b); return null

      default: return super.receive(msg)
    }
  }

  override Void onOpen() {}

  override Void onClose() {}

  override Dict onPing()
  {
    meta := client.proj
    return Etc.makeDict([
      "novantProj": meta["proj_name"]
    ])
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
      now := Duration.now
      if (now - lastVals < 1min) return
      this.lastVals = now

      // batch points into source_id buckets
      NovantUtil.eachSource(points, "novantCur") |sid, srcPoints|
      {
        // map points to lookup by novantCur point id
        pmap := Str:Dict[:]
        srcPoints.each |r| { pmap[r->novantCur] = r }
        pids := pmap.keys

        // request live data
        vals := client.vals(sid, pids)
        vals.each |res,id|
        {
          ConnPoint? pt
          try
          {
            // point not found
            rec := pmap[id]
            pt = point(rec.id)
            if (pt == null) return

            // sanity check to disallow his collection
            if (rec.has("hisCollectCov") || rec.has("hisCollectInterval"))
              throw ArgErr("hisCollect not allowed")

            // check remote status
            val := res["val"]
            status := res["status"]
            if (status != "ok") throw ArgErr("Remote fault")

            // convert and update
            pval := NovantUtil.toConnPointVal(rec, val)
            pt.updateCurOk(pval)
          }
          catch (Err err) { pt?.updateCurErr(err) }
        }
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
      if (pri < 1)  pri = 1
      if (pri > 16) pri = 16

      // issue write
      pid := point.rec["novantWrite"]
      sid := NovantUtil.toSourceId(pid)
      client.write(sid, pid, fval, pri)

      // update ok
      point.updateWriteOk(val, level)
    }
    catch (Err err) { point.updateWriteErr(val, level, err) }
  }

//////////////////////////////////////////////////////////////////////////
// His
//////////////////////////////////////////////////////////////////////////

  override Obj? onSyncHis(ConnPoint p, Span origSpan)
  {
    //
    // NOTE: we do not use this method since we need to see the
    // entire request in order to batch points by source_id to
    // optimize API requests
    //
    // It seems all the tooling uses reflection to invoke
    // {ext}.{ext}SyncHis; so we use that method to route to our
    // batch impl on the parent connector actor
    //
    // See: doBatchSyncHis()
    //

    throw ArgErr("NovantConn.onSyncHis not supported; use novantHisSync()")
    return null
  }

  private Void doBatchSyncHis(Dict[] allPoints, Span? range)
  {
    log.info("syncHis $allPoints.size records [range:$range] ...")

    // track success/failure
    oks   := 0
    fails := 0

    // update to pending
    setStatus(allPoints, pending)

    // batch points into source_id buckets
    NovantUtil.eachSource(allPoints, "novantHis") |sid,srcPoints|
    {
      try
      {
        start := Duration.now
        span  := range ?: NovantUtil.toHisSpan(srcPoints)
        log.info("syncHis source:${sid} [$srcPoints.size points, span:$span] ...")

        // update to in syncing
        setStatus(srcPoints, syncing)

        // map points to lookup by novantHis point id
        pmap := Str:Dict[:]
        srcPoints.each |r| { pmap[r->novantHis] = r }
        pids := pmap.keys.sort
        tz   := TimeZone(srcPoints.first->tz)

        // pre-populate hmap since we need an entry
        // for every point in order to reset status
        hmap := Str:HisItem[][:]
        pids.each |pid| { hmap[pid] = HisItem[,] }

        // TODO FIXIT: support for date span
        // request trend data and append to his item array
        span.eachDay |date|
        {
          // throttle requests to keep under 1000/reqs/5min
          Actor.sleep(500ms)

          // request trends for date
          client.trendsEach(date, pids, tz) |ts,pid,val|
          {
            // skip 'null' and 'na' vals
            rec  := pmap[pid]
            pval := NovantUtil.toConnPointVal(rec, val, false)
            if (pval == null) return

            // skip ts if < hisEnd
            hisEnd := rec["hisEnd"] as DateTime
            if (hisEnd != null && ts <= hisEnd) return

            // append his item
            items := hmap[pid]
            items.add(HisItem(ts, pval))
            hmap[pid] = items
          }
        }

        // update his
        hmap.each |items,pid|
        {
          rec := pmap[pid]
          pt  := point(rec.id)
          pt.updateHisOk(items, span)
        }

        // update oks
        oks += srcPoints.size
        dur := Duration.now - start
        log.info("syncHis source:${sid} OK [${dur.toLocale}]")
      }
      catch (Err err)
      {
        log.err("syncHis FAIL ${sid}: $err.msg", err)
        fails += srcPoints.size
      }
    }

    // all done!
    log.info("syncHis DONE: $oks OK; $fails FAIL")
  }

  ** Set transient status on given points.
  private Void setStatus(Dict[] points, Dict status)
  {
    diffs := Diff[,]
    points.each |r| { diffs.add(Diff(r, status, Diff.forceTransient)) }
    proj.commitAll(diffs)
  }

//////////////////////////////////////////////////////////////////////////
// Learn
//////////////////////////////////////////////////////////////////////////

  override Grid onLearn(Obj? arg)
  {
    rows := Dict[,]

    if (arg == null)
    {
      // root
      rows.add(Etc.makeDict(["dis":"Assets",  "learn":"assets"]))
      rows.add(Etc.makeDict(["dis":"Sources", "learn":"sources"]))
    }
    else if (arg == "assets")
    {
      // asset list
      client.assets.each |a|
      {
        dis := a["name"]
        sid := a["id"]
        row := Str:Obj?["dis":dis, "learn":sid]

        // add extra tags (but never clobber if exists)
        tags := learnTags(a)
        tags.each |tag| {
          if (!row.containsKey(tag)) row[tag] = Marker.val
        }

        rows.add(Etc.makeDict(row))
      }
    }
    else if (arg == "sources")
    {
      // source list
      client.sources.each |s|
      {
        dis := s["name"]
        sid := s["id"]
        rows.add(Etc.makeDict(["dis":dis, "learn":sid]))
      }
    }
    else
    {
      // point list
      client.points(arg).each |p|
      {
        id   := p["id"]
        dis  := p["name"]
        addr := p["addr"]
        kind := p["kind"] == "bool" ? "Bool" : "Number"
        cur  := "${id}"
        wrt  := p["writable"] == true ? "${id}" : null
        his  := "${id}"
        unit := p["unit"]?.toStr?.trimToNull

        row := [
          "dis":         dis,
          "learn":       null,
          "point":       Marker.val,
          "pointAddr":   addr,
          "kind":        kind,
          "novantCur":   cur,
          "novantWrite": wrt,
          "novantHis":   his,
          "unit":        unit,
        ]

        // add extra tags (but never clobber if exists)
        tags := learnTags(p)
        tags.each |tag| {
          if (!row.containsKey(tag)) row[tag] = Marker.val
        }

        rows.add(Etc.makeDict(row))
      }
    }

    // find col names
    cols := Str:Str[:]
    rows.each |r| {
      Etc.dictNames(r).each |n| {
        cols[n] = n
      }
    }

    // create grid
    gb := GridBuilder()
    gb.addColNames(cols.vals)
    gb.addDictRows(rows)
    return gb.toGrid
  }

  private Str[] learnTags(Map map)
  {
    o := map["ontology"] as Map
    if (o == null) return Str#.emptyList

    h := o["haystack"] as Str
    return h?.split(',') ?: Str#.emptyList
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  ** Get an authenicated NovantClient instance.
  private NovantClient client()
  {
    apiKey := ext.proj.passwords.get("${rec.id} novantApiKey")
    if (apiKey == null) throw ArgErr("novantApiKey not found")
    return NovantClient(apiKey)
  }

  private static const Dict pending := Etc.makeDict(["hisStatus":"pending"])
  private static const Dict syncing := Etc.makeDict(["hisStatus":"syncing"])

  private Duration lastVals := Duration.defVal   // vals counter to throttle /values API reqs
  // private Span:ConnPoint[] hisSyncQueue := [:]   // his sync queue
}