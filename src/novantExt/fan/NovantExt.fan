//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019   Andy Frank   Creation
//

using haystack
using skyarcd
using connExt

**
** Novant Extension
**
@ExtMeta
{
  name    = "novant"
  icon    = "novant"
  depends = ["conn"]
}
const class NovantExt : ConnImplExt
{
  static NovantExt? cur(Bool checked := true)
  {
    Context.cur.ext("novant", checked)
  }

  @NoDoc new make() : super(NovantModel())
  {
    this.projActor = NovantProjActor(this)
    this.syncActor = NovantSyncActor(this)
  }

  ** The project actor for the current project.
  internal const NovantProjActor projActor

  ** The sync actor for the current project.
  internal const NovantSyncActor syncActor
}
