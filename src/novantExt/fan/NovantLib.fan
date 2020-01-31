//
// Copyright (c) 2019, Novant LLC
// All Rights Reserved
//
// History:
//   18 Nov 2019   Andy Frank   Creation
//

using haystack
using axon

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
  ** history database, for each point provided.
  **
  @Axon { admin = true }
  static Obj? novantSyncHis(Obj points, Obj? span := null)
  {
    NovantExt.cur.syncHis(points, span)
  }
}

