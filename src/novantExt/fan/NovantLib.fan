//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019   Andy Frank   Creation
//

using axon
using connExt
using folio
using haystack
using skyarcd

**
** Axon functions for novant
**
const class NovantLib
{
  **
  ** Perform a synchronous learn read on the given connector.
  ** Following columns are returned:
  **   - 'dis': display name of point
  **   - 'point': point marker
  **   - 'kind': point kind
  **   - 'novantHis': address to sync trend data for point
  **
  @Axon { admin = true }
  static Grid novantLearn(Obj conn, Obj? arg := null)
  {
    NovantExt.cur.connActor(conn).learn(arg)
  }

  **
  ** Import the latest data from an connector to the local
  ** history database.  This will import history for all
  ** points under given 'conn'. The import will be queued
  ** a background actor, and this method will return
  ** immeditatly.
  **
  @Axon { admin = true }
  static Void novantSync(Obj conns, Obj? span := null, Obj? opts := null)
  {
    Etc.toRecs(conns).each |conn|
    {
      dopts := Etc.makeDict(opts)
      NovantExt.cur.connActor(conn).send(ConnMsg("nvSync", span, dopts))
    }
  }

  **
  ** Import the latest data for one or more points to the local
  ** history database. The import will be queued a background actor,
  ** and this method will return immeditatly.
  **
  @Axon { admin = true }
  static Void novantSyncPoints(Obj points, Obj? span := null, Obj? opts := null)
  {
    // get connector reference recs
    cx    := Context.cur
    cmap  := Ref:Dict[:]
    precs := Etc.toRecs(points)
    precs.each |p|
    {
      ref := p["novantConnRef"]
      if (ref != null && !cmap.containsKey(ref))
        cmap[ref] = cx.proj.readById(ref)
    }

    // merge all pointIds into opts; we'll filter these out downstream
    dopts := Etc.makeDict(opts)
    dopts = Etc.dictSet(dopts, "pointIds", precs.map |r| { r.id })

    // invoke sync per conn
    cmap.vals.each |conn|
    {
      NovantExt.cur.connActor(conn).send(ConnMsg("nvSync", span, dopts))
concurrent::Actor.sleep(1sec)
    }
  }

  **
  ** Clear all history for all points for given conn.
  **
  @Axon { admin=true }
  static Void novantHisClear(Obj conns)
  {
    cx   := Context.cur
    recs := Etc.toRecs(conns)
    recs.each |c|
    {
      pts := cx.readAll("point and novantConnRef==${c.id.toCode}")
      cx.call("hisClear", [pts, null])
    }
  }

  ** UI support.
  @NoDoc @Axon { admin=true }
  static Grid novantReadConns()
  {
    g := GridBuilder()
    g.addColNames([
      "id","deviceId","disabled","numPoints","syncFreq","hisInterval",
      "hisStart","hisEnd","numHisDays"])

    cx := Context.cur
    cx.readAll("novantConn").each |r|
    {
      // hisStart/End is min/max of all points underneath
      DateTime? hisStart
      DateTime? hisEnd
      pts := cx.readAll("point and novantConnRef == ${r.id.toCode}")
      pts.each |p|
      {
        hisStart = NovantUtil.minDateTime(hisStart, p["hisStart"] as DateTime)
        hisEnd   = NovantUtil.maxDateTime(hisEnd,   p["hisEnd"] as DateTime)
      }

      // get his days
      hisDays := NovantUtil.numDays(hisStart, hisEnd)

      g.addRow([
        r.id,
        r->novantDeviceId,
        r["disabled"],
        Number.makeInt(pts.size),
        r->novantSyncFreq,
        r["novantHisInterval"] ?: "15min",
        hisStart,
        hisEnd,
        hisDays == null ? null : Number.makeDuration(hisDays),
      ])
    }

    return g.toGrid
  }
}

