//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019   Andy Frank   Creation
//

using haystack
using folio
using skyarcd

*************************************************************************
** NovantUtilTest
*************************************************************************

class NovantUtilTest : Test
{
  Void testHisSpan()
  {
    ny  := TimeZone("New_York")
    now := DateTime.nowUtc.toTimeZone(ny).floor(1min)

    // staggered hisEnd
    p1 := [
      Etc.makeDict(["dis":"P1", "tz":"New_York", "hisEnd":null]),
      Etc.makeDict(["dis":"P2", "tz":"New_York", "hisEnd":DateTime("2025-11-25T10:25:00-05:00 New_York")]),
      Etc.makeDict(["dis":"P3", "tz":"New_York", "hisEnd":DateTime("2025-11-15T23:16:00-05:00 New_York")]),
    ]

    // no existing hisEnd
    p2 := [
      Etc.makeDict(["dis":"P1", "tz":"New_York", "hisEnd":null]),
      Etc.makeDict(["dis":"P2", "tz":"New_York", "hisEnd":null]),
      Etc.makeDict(["dis":"P3", "tz":"New_York", "hisEnd":null]),
    ]

    // empty point list
    s := NovantUtil.toHisSpan([,])
    verifyEq(s, Span.defVal)

    // "last" sync with staggerd hisEnd
    s = NovantUtil.toHisSpan(p1)
    verifyEq(s.start, DateTime("2025-11-15T23:17:00-05:00 New_York")) // +1min
    verifyEq(s.end,   DateTime.nowUtc.toTimeZone(ny).floor(1min))     // now

    // "last" sync with no hisEnd
    s = NovantUtil.toHisSpan(p2)
    verifyEq(s.start, now - 5day + 1min)
    verifyEq(s.end,   now)
  }
}

