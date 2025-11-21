//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019  Andy Frank   Creation
//    8 Dec 2022  Andy Frank  Update to Apollo
//

using axon
using concurrent
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
  **   - 'novantCur': address to read live data for point
  **   - 'novantWrite': address to write values back for point
  **   - 'novantHis': address to sync trend data for point
  **
  @Axon { admin = true }
  static Grid novantLearn(Obj conn, Obj? arg := null)
  {
    NovantExt.cur.connActor(conn).learn(arg)
  }

  **
  ** Asynchronously sync given points with the current values.
  ** The proxies may be any value suppored by `toRecList`.
  **
  @Axon { admin = true }
  static Obj? novantSyncCur(Obj points)
  {
    NovantExt.cur.syncCur(points)
  }

  **
  ** Import the latest historical data from one or more external
  ** points. The proxies may be any value suppored by `toRecList`.
  **
  ** Each proxy record must contain:
  **  - `novantConnRef`: references the haystack connector
  **  - `novantHis`: Str identifier of the Novant point id
  **  - `his`: all the standard historized point tags
  **
  ** If the range is unspecified, then an attempt is made to
  ** synchronize any data after 'hisEnd' (last timestamp read).
  **
  ** This method is designed to be run in the context of a
  ** job via the `ext-job::doc`.
  **
  @Axon { admin = true }
  static Void novantSyncHis(Obj proxies, Obj? range := null)
  {
    // TODO FIXIT: since we have this logic here; should
    // we remove the delayed logic in NovantConn?

    log := NovantExt.cur.log
    eachBatch(proxies) |sid, batch|
    {
      // throttle API calls to avoid rate limits
      Actor.sleep(5sec)

      // queue onto actor
      log.info("batchSyncHis [$sid, $batch.size points]")
      NovantExt.cur.syncHis(batch, range)
    }
  }

  ** Request project information for given connector from the backing Novant project.
  @Axon { admin = true }
  static Grid novantProj(Obj conn)
  {
    NovantExt.cur.connActor(conn).send(ConnMsg("novant_proj")).get
  }

  ** Request zone list for given connector from the backing Novant project.
  @Axon { admin = true }
  static Grid novantZones(Obj conn)
  {
    NovantExt.cur.connActor(conn).send(ConnMsg("novant_zones")).get
  }

  ** Request space list for given connector from the backing Novant project.
  @Axon { admin = true }
  static Grid novantSpaces(Obj conn)
  {
    NovantExt.cur.connActor(conn).send(ConnMsg("novant_spaces")).get
  }

  ** Request asset list for given connector from the backing Novant project.
  @Axon { admin = true }
  static Grid novantAssets(Obj conn)
  {
    NovantExt.cur.connActor(conn).send(ConnMsg("novant_assets")).get
  }

  ** Request source list for given connector from the backing Novant project.
  @Axon { admin = true }
  static Grid novantSources(Obj conn)
  {
    NovantExt.cur.connActor(conn).send(ConnMsg("novant_sources")).get
  }

  ** Request source list for given connector from the backing Novant project.
  @Axon { admin = true }
  static Grid novantPoints(Obj conn, Str sourceId)
  {
    NovantExt.cur.connActor(conn).send(ConnMsg("novant_points", sourceId)).get
  }

  **
  ** Batch a list of points into buckets based on the common
  ** parent source id, and iterate each patch with callback
  ** function.
  **
  private static Void eachBatch(Obj points, |Str sourceId, Dict[] batch| f)
  {
    // map to parent source
    map  := Str:Dict[][:]
    recs := Etc.toRecs(points)
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
}

