//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019  Andy Frank   Creation
//    8 Dec 2022  Andy Frank  Update to Apollo
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
  static Obj? novantSyncHis(Obj proxies, Obj? range := null)
  {
    NovantExt.cur.syncHis(proxies, range)
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
}

