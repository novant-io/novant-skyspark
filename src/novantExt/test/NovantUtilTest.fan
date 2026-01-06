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

//////////////////////////////////////////////////////////////////////////
// ConnPoint
//////////////////////////////////////////////////////////////////////////

  Void testConnPoint()
  {
    p1 := Etc.makeDict(["kind":"Bool"])
    p2 := Etc.makeDict(["kind":"Number"])
    p3 := Etc.makeDict(["kind":"Str"])

    // bool
    verifyEq(NovantUtil.toConnPointVal(p1, null), null)
    verifyEq(NovantUtil.toConnPointVal(p1, 0f),   false)
    verifyEq(NovantUtil.toConnPointVal(p1, 1f),   true)
    verifyEq(NovantUtil.toConnPointVal(p1, 5f),   true)  // any non-zero is true
    verifyEq(NovantUtil.toConnPointVal(p1, -1f),  true)  // any non-zero is true

    // number
    verifyEq(NovantUtil.toConnPointVal(p2, null),   null)
    verifyEq(NovantUtil.toConnPointVal(p2, 0f),     Number(0f))
    verifyEq(NovantUtil.toConnPointVal(p2, 1f),     Number(1f))
    verifyEq(NovantUtil.toConnPointVal(p2, -0.25f), Number(-0.25f))
    verifyEq(NovantUtil.toConnPointVal(p2, 100f),   Number(100f))

    // TODO: Str#
    verifyEq(NovantUtil.toConnPointVal(p3, null),   null)
    verifyErr(IOErr#) { x := NovantUtil.toConnPointVal(p3, 0f) }
    verifyErr(IOErr#) { x := NovantUtil.toConnPointVal(p3, 1f) }
    // checked
    verifyEq(NovantUtil.toConnPointVal(p3, 0f, false), null)
    verifyEq(NovantUtil.toConnPointVal(p3, 1f, false), null)
  }

//////////////////////////////////////////////////////////////////////////
// HisSpan
//////////////////////////////////////////////////////////////////////////

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

