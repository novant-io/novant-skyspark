//
// Copyright (c) 2020, Novant LLC
// Licensed under the MIT License
//
// History:
//   9 May 2020  Andy Frank  Creation
//

using concurrent
using connExt

*************************************************************************
** NovantProjActor
*************************************************************************

** NovantProjActor manages background work for entire project.
internal const class NovantProjActor
{
  new make(NovantExt ext)
  {
    this.ext   = ext
    this.pool  = ActorPool { it.name="NovantProjActor"; it.maxThreads=1 }
    this.actor = Actor(pool) |m| { _receive(m) }
    this.actor.send("init")
  }

  ** Actor local receive proc handler.
  private Obj? _receive(Obj msg)
  {
    try
    {
      switch (msg)
      {
        case "init": _init; return null
        case "poll": _poll; return null
        default:     return null
      }
    }
    finally { actor.sendLater(pollFreq, "poll") }
  }

  ** Handle _init callback.
  private Void _init()
  {
    now := Duration.nowTicks
    Actor.locals["s"] = now + syncFreq
  }

  ** Handle poll callback
  private Void _poll()
  {
    now := Duration.nowTicks
    nextSync := Actor.locals["s"] as Int

    if (now > nextSync && ext.proj.isSteadyState)
    {
      Actor.locals["s"] = now + syncFreq
      ext.proj.readAll("novantConn").each |rec|
      {
        // SyncActor will short-circuit if we are already up-to-date
        // so design is simpiler to just force the sync check and let
        // downstream handle the no-op
        if (rec["novantSyncFreq"] == "daily")
          ext.connActor(rec).send(ConnMsg("nvSync"))
      }
    }
  }

  private const NovantExt ext
  private const ActorPool pool
  private const Actor actor

  private const Duration pollFreq := 1sec   // freq to poll for work
  private const Int syncFreq := 1hr.ticks   // freq to check for sync jobs

}
