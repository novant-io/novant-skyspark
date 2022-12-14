//
// Copyright (c) 2021, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Jul 2021  Andy Frank  Creation
//

using connExt
using haystack

**
** NovantUtil
**
internal class NovantUtil
{
  ** Convert Novant API value to SkySpark ConnPoint value.
  static Obj? toConnPointVal(ConnPoint p, Obj val, Bool checked := true)
  {
    // check fault (TODO: pull thru error codes?)
    if (val isnot Float)
    {
      if (checked) throw IOErr("Fault")
      return null
    }

    // convert based on rec->kind
    kind := p.rec["kind"]
    switch (kind)
    {
      case "Bool":   return val == 0f ? false : true
      case "Number": return Number.make(val)
      default:       throw IOErr("Unsupported kind '${kind}'")
    }
  }
}

