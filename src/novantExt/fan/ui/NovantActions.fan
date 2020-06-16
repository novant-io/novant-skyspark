//
// Copyright (c) 2020, Novant LLC
// All Rights Reserved
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
  static Void sync()
  {
    Win.cur.alert("TODO: sync")
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
                  action"
      it.addButton("yes", null, false)
      it.addButton("no",  null, true)
      it.onAction |key|
      {
        if (key != "yes") return true

        sel  := view.sel.map |r| { r.id }
        expr := UiUtil.makeAxonCall("novantHisClear", [sel])
        req  := Etc.makeMapGrid(null, ["expr":expr.toStr])
        ax   := Flash.showActivity(view, "$<ui::working>...")
        view.session.api.call("eval", req)
          .onOk  |res| { ax.onClose { dlg.close; view.update }; ax.close }
          .onErr |err| { ax.close; Flash.showErr(dlg, err)  }
        return false
      }
    }.open
  }
}
