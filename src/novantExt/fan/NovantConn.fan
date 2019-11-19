//
// Copyright (c) 2019, Novant LLC
// All Rights Reserved
//
// History:
//   18 Nov 19   Andy Frank   Creation
//

using haystack
using connExt

**
** NovantConn
**
class NovantConn : Conn
{
  new make(ConnActor actor, Dict rec) : super(actor, rec) {}

  override Obj? receive(ConnMsg msg) { return super.receive(msg) }

  override Void onOpen() {}

  override Void onClose() {}

  override Dict onPing() { Etc.emptyDict }

  override Grid onLearn(Obj? arg)
  {
    gb := GridBuilder()
    gb.addColNames(["dis","point","kind","novantHis"])
    return gb.toGrid
  }
}

