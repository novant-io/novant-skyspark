//
// Copyright (c) 2021, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Jul 2021  Andy Frank  Creation
//

using connExt
using folio
using haystack
using hisExt
using skyarcd

**
** NovantUtil
**
internal class NovantUtil
{

//////////////////////////////////////////////////////////////////////////
// Iterators
//////////////////////////////////////////////////////////////////////////

  **
  ** Batch a list of points into buckets based on the common
  ** parent connector, and iterate each batch with callback.
  **
   static Void eachConn(Obj proxies, |Obj conn, Dict[] points| f)
  {
    // map to parent source
    map  := Ref:Dict[][:]
    recs := Etc.toRecs(proxies)
    recs.each |r|
    {
      // skip if no conn or sync tag
      if (r->novantConnRef == null) return
      if (r->novantHis == null) return

      ref := r->novantConnRef
      acc := map[ref] ?: Dict[,]
      acc.add(r)
      map[ref] = acc
    }

    // iterate
    map.each |v,k| { f(k, v) }
  }

  **
  ** Batch a list of points into buckets based on the common
  ** parent source id, and iterate each patch with callback.
  **
  static Void eachSource(Obj proxies, |Str sourceId, Dict[] points| f)
  {
    // map to parent source
    map  := Str:Dict[][:]
    recs := Etc.toRecs(proxies)
    recs.each |r|
    {
      sid := toSourceId(r->novantHis)
      acc := map[sid] ?: Dict[,]
      acc.add(r)
      map[sid] = acc
    }

    // iterate
    map.each |v,k| { f(k, v) }
  }

  ** Given a point id return the parent source id.
  private static Str toSourceId(Str pointId)
  {
    off := pointId.indexr(".")
    return pointId[0..<off]
  }

//////////////////////////////////////////////////////////////////////////
// His
//////////////////////////////////////////////////////////////////////////

  ** Given a list of points find the span
  ** needed to satisfy a his sync.
  static Span toHisSpan(Dict[] points)
  {
    if (points.isEmpty) return Span.defVal

    // all points should have the timezone
    tz := FolioUtil.hisTz(points.first)

    // find the "youngest" hisEnd time
    now := DateTime.now.toTimeZone(tz).floor(1min)
    DateTime? last
    points.each |p|
    {
      hisEnd := p["hisEnd"] as DateTime
      if (hisEnd == null) return
      if (last == null) last = hisEnd
      else last = (last < hisEnd) ? last : hisEnd
    }

    // if not hisEnd found default to last 5days
    if (last == null) last = now - 5day

    // Novant use 1min granulatiry; so add 1min from last sync
    return Span(last+1min, now)
  }

  ** Convert Novant API value to SkySpark ConnPoint value.
  static Obj? toConnPointVal(Dict rec, Obj? val, Bool checked := true)
  {
    // check fault (TODO: pull thru error codes?)
    if (val isnot Float)
    {
      if (checked) throw IOErr("Fault")
      return null
    }

    // convert based on rec->kind
    kind := rec["kind"]
    switch (kind)
    {
      case "Bool":   return val == 0f ? false : true
      case "Number": return Number.make(val)
      default:       throw IOErr("Unsupported kind '${kind}'")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Grid
//////////////////////////////////////////////////////////////////////////

  ** Convert list of rows to grid.
  static Grid toGrid([Str:Obj?][] rows)
  {
    drows := Dict[,]
    rows.each |r| { drows.add(NovantUtil.apiToDict(r)) }

    // find col names
    cmap:= Str:Str[:]
    drows.each |r| {
      Etc.dictNames(r).each |n| { cmap[n] = n }
    }

    // reorder
    cols := cmap.vals.sort
    NovantUtil.reorderCols(cols, [
      "id",
      "name",
      "type",
      "parent_zone_id",
      "parent_zone_ids",
      "parent_space_id",
      "fed_by_asset_ids",
      "contains_asset_ids",
      "source_ids",
      "addr",
      "parent_asset_id",
      "haystack",
    ])

    // create grid
    gb := GridBuilder()
    gb.addColNames(cols)
    drows.each |r| { gb.addDictRow(r) }
    return gb.toGrid
  }

  ** Convert an API response map to a SkySpark-compatible Dict.
  internal static Dict apiToDict(Str:Obj? map)
  {
    cmap := Str:Obj?[:]
    map.each |v,k|
    {
      switch (k)
      {
        // pull only and only include haystack
        case "ontology":
          cmap.add("haystack", ((Map)v).get("haystack"))

        case "props":
          Map p := v
          p.each |pv,pk| { cmap.add(pk, toVal(pv)) }

        default:
          cmap.add(k, toVal(v))
      }
    }
    return Etc.makeDict(cmap)
  }

  **
  ** Reorders `cols` to match the order defined in `desired`.
  ** Column names in `desired` that are not present in `cols`
  ** are ignored. Any remaining columns not listed in `desired`
  ** keep their existing order.
  **
  internal static Void reorderCols(Str[] cols, Str[] desired)
  {
    offset := 0
    desired.each |dc|
    {
      if (!cols.contains(dc)) return
      cols.moveTo(dc, offset++)
    }
  }

  private static Obj? toVal(Obj? orig)
  {
    if (orig is Int)   return Number.makeInt(orig)
    if (orig is Float) return Number.make(orig)
    return orig
  }
}

