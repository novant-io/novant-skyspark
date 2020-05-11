//
// Copyright (c) 2020, Novant LLC
// All Rights Reserved
//
// History:
//   9 May 2020  Andy Frank  Creation
//

using concurrent

*************************************************************************
** NovantProjActor
*************************************************************************

** NovantProjActor manages background work for entire project.
const class NovantProjActor
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
    now  := Duration.nowTicks
    nextSync := Actor.locals["s"] as Int

    if (now > nextSync)
    {
      Actor.locals["s"] = now + syncFreq
      ext.syncActor.checkSyncs
    }
  }

  private const NovantExt ext
  private const ActorPool pool
  private const Actor actor

  private const Duration pollFreq := 1sec   // freq to poll for work
  private const Int syncFreq := 1min.ticks  // freq to check for sync jobs
}
