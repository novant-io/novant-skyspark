//
// Copyright (c) 2021, Novant LLC
// All Rights Reserved
//
// History:
//   18 Jul 2021  Andy Frank  Creation
//

using connExt
using haystack

**
** NovantUtil
**
class NovantUtil
{
  ** Convert Novant API value to SkySpark ConnPoint value.
  static Obj toConnPointVal(ConnPoint p, Obj val)
  {
    // check fault (TODO: pull thru error codes?)
    if (val isnot Float) throw IOErr("Fault")

    // convert based on rec->kind
    kind := p.rec["kind"]
    switch (kind)
    {
      case "Bool":   return val == 0f ? false : true
      case "Number": return Number.make(val, p.unit)
      default:       throw IOErr("Unsupported kind '${kind}'")
    }
  }
}

