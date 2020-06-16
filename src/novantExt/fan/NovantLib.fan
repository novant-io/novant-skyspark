//
// Copyright (c) 2019, Novant LLC
// All Rights Reserved
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
    if (span is Date) span = DateSpan.make(span)
    SysLib.toRecList(conns).each |conn|
    {
      dopts := Etc.makeDict(opts)
      NovantExt.cur.connActor(conn).send(ConnMsg("nvSync", span, dopts))
    }
  }

  **
  ** Clear all history for all points for given conn.
  **
  @Axon { admin=true }
  static Void novantHisClear(Obj conns)
  {
    cx   := Context.cur
    recs := SysLib.toRecList(conns)
    recs.each |c|
    {
      pts := cx.readAll("point and novantConnRef==${c.id.toCode}")
      cx.call("hisClear", [pts, null])

      tags := ["novantHisStart":Remove.val, "novantHisEnd":Remove.val]
      cx.proj.commit(Diff(c, tags))
    }
  }

  @NoDoc @Axon { admin=true }
  static Grid novantReadConns()
  {
    g := GridBuilder()
    g.addColNames(["id","deviceId","numPoints","hisStart","hisEnd","numHisDays"])

    cx := Context.cur
    cx.readAll("novantConn").each |r|
    {
      numPoints := cx.readAll("point and novantConnRef == ${r.id.toCode}").size

      Date? start := r["novantHisStart"]
      Date? end   := r["novantHisEnd"]
      numHis := start == null || end == null ? null : end-start+1day

      g.addRow([
        r.id,
        r->novantDeviceId,
        Number.makeInt(numPoints),
        start,
        end,
        numHis == null ? null : Number.makeDuration(numHis),
      ])
    }

    return g.toGrid
  }
}

