//
// Copyright (c) 2020, Novant LLC
// Licensed under the MIT License
//
// History:
//   16 Jun 2020   Andy Frank   Creation
//

using dom
using domkit
using haystack
using ui

@Js const class NovantActions
{
  static Void sync(UiView view)
  {
    NSyncDialog(view.sel)
      .onOk |d,span| {
        sel := view.sel.map |r| { r.id }
        invoke(view, d, "novantSync", [sel,span])
      }
      .open
  }

  static Void clearHis(UiView view)
  {
    NAlertDialog
    {
      dlg := it
      it.title = null
      it.icon  = Icon.outline("warn", Colors.yellow)
      it.msg   = "Delete all history for this device?"
      it.info  = "This will delete history for all points under this device.
                  History will be resynced automatically starting today moving
                  forward. To resync older history, use the <b>Sync History</b>
                  action."
      it.addButton("yes", null, false)
      it.addButton("no",  null, true)
      it.onAction |key|
      {
        if (key != "yes") return true
        sel  := view.sel.map |r| { r.id }
        invoke(view, dlg, "novantHisClear", [sel])
        return false
      }
    }.open
  }

  static Void invoke(UiView view, Dialog dlg, Str func, Obj[] args)
  {
    expr := UiUtil.makeAxonCall(func, args)
    req  := Etc.makeMapGrid(null, ["expr":expr.toStr])
    ax   := Flash.showActivity(view, "$<ui::working>...")
    view.session.api.call("eval", req)
      .onOk  |res| { ax.onClose { dlg.close; view.update }; ax.close }
      .onErr |err| { ax.close; Flash.showErr(dlg, err)  }
  }
}
