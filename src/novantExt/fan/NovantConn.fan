//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019   Andy Frank   Creation
//    8 Dec 2022  Andy Frank  Update to Apollo
//

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

      // request by source and update curVals
      smap := NovantUtil.toSourceMap(points, "novantCur")
      smap.each |pmap,sid|
      {
        pids := pmap.keys
        vals := client.vals(sid, pids)
        vals.each |res,id|
        {
          ConnPoint? pt
          try
          {
            // point not found
            pt = pmap[id]
            if (pt == null) return

            // sanity check to disallow his collection
            if (pt.rec.has("hisCollectCov") || pt.rec.has("hisCollectInterval"))
              throw ArgErr("hisCollect not allowed")

            // check remote status
            val := res["val"]
            status := res["status"]
            if (status != "ok") throw ArgErr("Remote fault")

            // convert and update
            pval := NovantUtil.toConnPointVal(pt, val)
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
    /*
    try
    {
      // convert to float
      Float? fval
      if (val is Number) fval = ((Number)val).toFloat
      if (val is Bool)   fval = val==true ? 1f : 0f

      // cap priority to max 16
      pri := level.toInt
      if (pri > 16) pri = 16

      // issue write
      pid := point.rec["novantWrite"]
      client.write(deviceId, pid, fval, pri)

      // update ok
      point.updateWriteOk(val, level)
    }
    catch (Err err) { point.updateWriteErr(val, level, err) }
    */
  }

//////////////////////////////////////////////////////////////////////////
// His
//////////////////////////////////////////////////////////////////////////

  override Obj? onSyncHis(ConnPoint p, Span origSpan)
  {
    // update status to pending
    proj.commit(Diff(p.rec, pending, Diff.forceTransient))

    // floor span to nearest minute to align queue keys
    span := Span(floorTsMin(origSpan.start), floorTsMin(origSpan.end))

    // queue for next sync
    acc := hisSyncQueue[span] ?: ConnPoint[,]
    if (acc.find |x| { x.id == p.id } == null) acc.add(p)
    hisSyncQueue[span] = acc
    return null
  }

  override Void onHouseKeeping()
  {
    try
    {
      // short-circuit if nothing to sync
      if (hisSyncQueue.isEmpty) return

      // iterate queue
      hisSyncQueue.each |points, span|
      {
        // batch by source
        smap := NovantUtil.toSourceMap(points, "novantHis")
        smap.each |pmap,sid| { doSyncHis(span, sid, pmap) }
      }
    }
    catch (Err err) { close(err) }
    finally
    {
      // for now to be safe always flush queue
      hisSyncQueue.clear
    }
  }

  private Void doSyncHis(Span span, Str sid, Str:ConnPoint pmap)
  {
    try
    {
      pids  := pmap.keys          // point_id list
      refs  := Ref[,]             // list of backing rec ids
      hmap  := Str:HisItem[][:]   // map of point_id:HisItem[]
      tz    := TimeZone(pmap.vals.first.rec["tz"])  // points should have same tz
      start := Duration.now

      // update hisStatus to 'syncing'
      pmap.vals.each |p| {
        refs.add(p.rec.id)
        proj.commit(Diff(p.rec, syncing, Diff.forceTransient))
      }

      // refresh backing rec for each point (the conn.point.rec instance
      // gets cached on conn.open; so we need to update to latest copy
      // so we can inspect hisStar/hisEnd
      recs := proj.readByIdsList(refs)
      rmap := Ref:Dict[:].setList(recs) |r| { r.id }

      // TODO FIXIT: support for date span
      // request trend data and append to his item array
      span.eachDay |date|
      {
        client.trendsEach(date, sid, pids, tz) |ts,pid,val|
        {
          // skip 'null' and 'na' vals
          pt   := pmap[pid]
          pval := NovantUtil.toConnPointVal(pt, val, false)
          if (pval == null) return

          // skip ts if < hisEnd; must use rmap; see above
          rec    := rmap[pt.rec.id]
          hisEnd := rec["hisEnd"] as DateTime
          if (hisEnd != null && ts <= hisEnd) return

          // append his item
          items := hmap[pid] ?: HisItem[,]
          items.add(HisItem(ts, pval))
          hmap[pid] = items
        }
      }

      // update his
      hmap.each |items,pid|
      {
        pt := pmap[pid]
        pt.updateHisOk(items, span)
      }

      end := Duration.now
      dur := (end - start).toLocale
      log.info("syncHis OK: [${sid}, ${span}, ${pmap.size} points, ${dur}]")
    }
    catch (Err err)
    {
      // if req fails mark all points in fault
      pmap.vals.each |p| { p.updateHisErr(err) }
      log.err("syncHis failed: [${sid}, ${span}]", err)
    }
  }

  private DateTime floorTsMin(DateTime orig)
  {
    t := Time(orig.hour, orig.min, 0)
    return orig.date.toDateTime(t, orig.tz)
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
        aid := a["id"]
        rows.add(Etc.makeDict(["dis":dis, "learn":aid]))
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
  private Span:ConnPoint[] hisSyncQueue := [:]   // his sync queue
}