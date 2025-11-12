//
// Copyright (c) 2021, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Jul 2021  Andy Frank  Creation
//

using connExt
using haystack

**
** NovantUtil
**
internal class NovantUtil
{
  ** Convert Novant API value to SkySpark ConnPoint value.
  static Obj? toConnPointVal(ConnPoint p, Obj? val, Bool checked := true)
  {
    // check fault (TODO: pull thru error codes?)
    if (val isnot Float)
    {
      if (checked) throw IOErr("Fault")
      return null
    }

    // convert based on rec->kind
    kind := p.rec["kind"]
    switch (kind)
    {
      case "Bool":   return val == 0f ? false : true
      case "Number": return Number.make(val)
      default:       throw IOErr("Unsupported kind '${kind}'")
    }
  }

  ** Given a list of 'ConnPoint' return a map organized by source
  ** id using the specified reference tag.
  static Str:[Str:ConnPoint] toSourceMap(ConnPoint[] points, Str tag)
  {
    smap := Str:[Str:ConnPoint][:]
    points.each |p|
    {
      id := p.rec[tag]
      if (id != null)
      {
        sid  := "s." + id.toStr.split('.')[1]
        pmap := smap[sid] ?: Str:ConnPoint[:]
        pmap[id] = p
        smap[sid] = pmap
      }
    }
    return smap
  }

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

