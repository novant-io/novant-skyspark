//
// Copyright (c) 2020, Novant LLC
// All Rights Reserved
//
// History:
//   16 Jun 2020   Andy Frank   Creation
//

using dom
using domkit
using ui

*************************************************************************
** NAlertDialog
*************************************************************************

@Js class NAlertDialog : Dialog
{
  ** Constructor.
  new make() : super()
  {
    this.onKeyDown |e|
    {
      if (e.key == Key.enter && defButton != null)
        fireAction(defButton)
    }
  }

  ** Icon to display in dialog.
  Icon? icon := null

  ** Primary message text in dialog.
  Str msg := ""

  ** Optional informational text to display below message.
  Str info := ""

  ** Add an action button to dialog. If 'dis' is null, then lookup
  ** display name using 'key' as the locale key.
  This addButton(Str key, Str? dis := null, Bool def := false)
  {
    buttons.add(key, dis ?: lookupDis(key))
    if (def) defButton = key
    return this
  }

  ** Callback when dialog is closed, where 'key' is the button
  ** used to dismiss the dialog.  Return 'true' to close dialog
  ** or 'false' prevent close and keep dialog open.
  Void onAction(|Str key->Bool| f) { this.cbAction = f }

  protected override Void onBeforeOpen()
  {
    // leave a top gap if no title
    if (title == null) this.style->paddingTop = "10px"


    Button[] buts := [,]
    buttons.each |dis,key|
    {
      buts.add(Button {
        it.style["min-width"] = "60px"
        it.text = dis
        it.onAction { fireAction(key) }
      })
      if (defButton == key) buts.last.style.addClass("def-action")
    }

    msgBox := makeMsgBox(icon, msg, info)
    butBox := FlowBox
    {
      it.style.setCss("padding: 0 10px 10px 10px")
      it.halign = Align.right
      it.gaps = ["4px"]
      it.addAll(buts)
    }

    this.removeAll.add(SashBox
    {
      it.dir = Dir.down
      it.sizes = ["auto", "auto"]
      msgBox,
      butBox,
    })
  }

  internal static Elem makeMsgBox(Icon? icon, Str msg, Str info)
  {
    msgBox := Box
    {
      it.style->padding = "10px 20px 10px 10px"
      it.style->minWidth = icon==null ? "400px" : "500px"
    }

    if (icon != null)
    {
      icon.resize("48px")
      icon.style->float = "left"
      icon.style->paddingTop   = "6px"
      icon.style->paddingRight = "10px"
      msgBox.style["min-height"] = "72px"
      msgBox.add(icon)
    }

    msgBox.add(Elem {
      if (icon != null) it.style["padding-top"] = "6px"
      it.style.addClass("font-black")
      it.text = msg
    })

    if (info.size > 0)
      msgBox.add(Elem {
        it.style.setCss("padding-top: 10px")
        it.style->paddingTop = "10px"
        it.style->maxWidth   = "450px"
        it.style->marginLeft = "58px"
        it.html = info
      })

    return msgBox
  }

  private Void fireAction(Str key)
  {
    if (cbAction?.call(key) ?: true == true) close
  }

  ** Lookup up dis using locale key.
  internal static Str lookupDis(Str key)
  {
    // simple name
    if (!key.contains("::")) return ContentDialog#.pod.locale(key) ?: key

    // check for qname
    ix   := key.index("::")
    pod  := key[0..<ix]
    name := key[ix+2..-1]
    return Pod.find(pod, false)?.locale(name) ?: key
  }

  private Str:Str buttons := [:] { ordered=true }
  private Str? defButton  := null
  private Func? cbAction  := null
}