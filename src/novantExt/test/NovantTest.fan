//
// Copyright (c) 2019, Novant LLC
// All Rights Reserved
//
// History:
//   18 Nov 2019   Andy Frank   Creation
//

using haystack
using folio
using skyarcd

**
** NovantTest
**
class NovantTest : Test
{
  Void testDefSpan()
  {
    verifySpan(null,               Date.today,         Date.today)
    verifySpan(Date("2020-05-03"), Date("2020-05-04"), Date.today)
    verifySpan(Date.today-1day,    Date.today,         Date.today)
    verifyNull(NovantSyncActor.defSpan(Date.today))
  }

  private Void verifySpan(Date? hisEnd, Date start, Date end)
  {
    span := NovantSyncActor.defSpan(hisEnd)
// echo("> $span [$span.start .. $span.end]")
    verifyEq(span.start, start)
    verifyEq(span.end,   end)
  }
}

