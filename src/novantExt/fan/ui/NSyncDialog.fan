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

*************************************************************************
** NSyncDialog
*************************************************************************

@Js class NSyncDialog : ContentDialog
{
  new make(Dict[] conns)
  {
    this.conns = conns

    start := Date.yesterday
    conns.each |c|
    {
      Date? d := c["hisStart"] // NOTE: this is novantReadConns; not real rec
      if (d == null) return
      if (d >= start) return
      start = d
    }

    end    := Date.yesterday
    endDis := end.toLocale("MMM D, YYYY")

    this.input = Input.makeForTag(UiSession.cur, "date", start)

    box := Box
    {
      it.style->padding  = "8px 0 10px 20px"
      it.style->minWidth = "400px"
      Icon.outline("sync", Colors.green).resize("32px").with {
        it.style->float = "left"
        it.style->paddingTop   = "4px"
        it.style->paddingRight = "0px"
      },
      Elem {
        it.style->margin   = "5px 0 20px 52px"
        it.style->maxWidth = "450px"
        it.text = "History data for Novant connectors is automatically
                   synced daily.  Use this form if you need to sync
                   older history that was not originally acquired."
      },
      FlowBox {
        it.style->marginLeft = "52px"
        it.gaps = ["8px"]
        Label { it.text="Sync from" },
        input.with { it.style->width="auto" },
        Label { it.text="to ${endDis}" },
      },
    }

    this.title   = "Sync"
    this.width   = "auto"
    this.content = box
    this.addButton("ok", "$<ui::sync>", true)
    this.addButton("cancel")
    this.onAction |key|
    {
      if (key == "cancel") return true
      span := DateSpan(input.save, end)
      cbOk?.call(this, span)
      return false
    }
  }

  This onOk(|NSyncDialog,DateSpan| f)
  {
    this.cbOk = f
    return this
  }

  private const Dict[] conns
  private Input input
  private Func? cbOk
}
