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
  static Obj toConnPointVal(ConnPoint p, Obj val)
  {
    // check fault (TODO: pull thru error codes?)
    if (val isnot Float) throw IOErr("Fault")

    // convert based on rec->kind
    kind := p.rec["kind"]
    switch (kind)
    {
      case "Bool":   return val == 0f ? false : true
      case "Number": return Number.make(val)
      default:       throw IOErr("Unsupported kind '${kind}'")
    }
  }

  ** Get min of given dates, or 'null' if either is 'null'.
  static DateTime? minDateTime(DateTime? a, DateTime? b)
  {
    if (a == null || b == null) return a ?: b
    return a <= b ? a : b
  }

  ** Get max of given dates, or 'null' if either is 'null'.
  static DateTime? maxDateTime(DateTime? a, DateTime? b)
  {
    if (a == null || b == null) return a ?: b
    return a >= b ? a : b
  }

  ** Get number of days between given dates, or 'null' if either is 'null'.
  static Duration? numDays(DateTime? a, DateTime? b)
  {
    if (a == null || b == null) return null
    dur := b - a
    day := dur.ticks / 1day.ticks
    if (dur.ticks % 1day.ticks > 0) day++
    return Duration.fromStr("${day}day")
  }
}

