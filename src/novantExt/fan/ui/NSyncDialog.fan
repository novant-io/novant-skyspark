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

*************************************************************************
** NSyncDialog
*************************************************************************

@Js internal class NSyncDialog : ContentDialog
{
  new make(Dict[] conns)
  {
    this.conns = conns

    start := Date.yesterday
    end   := Date.yesterday
    conns.each |c|
    {
      // NOTE: this is from novantReadConns(); not real rec
      DateTime? d := c["hisEnd"] as DateTime
      if (d == null) return
      if (d.date >= start) return
      start = d.date
    }

    this.inputStart = Input.makeForTag(UiSession.cur, "date", start)
    this.inputEnd   = Input.makeForTag(UiSession.cur, "date", end)

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
        inputStart.with { it.style->width="auto" },
        Label { it.text="to" },
        inputEnd.with { it.style->width="auto" },
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
      Date s := inputStart.save
      Date e := inputEnd.save
      span := DateSpan(s, e)
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
  private Input inputStart
  private Input inputEnd
  private Func? cbOk
}
