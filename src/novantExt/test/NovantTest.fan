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
    verifySpan(null,               Date.yesterday,     Date.yesterday)
    verifySpan(Date("2020-05-03"), Date("2020-05-04"), Date.yesterday)
    verifySpan(Date.today-2day,    Date.today-1day,    Date.yesterday)
    verifySpan(Date.today-3day,    Date.today-2day,    Date.yesterday)
    verifySpan(Date.today-4day,    Date.today-3day,    Date.yesterday)
    verifyNull(NovantSyncActor.defSpan(Date.yesterday))
    verifyNull(NovantSyncActor.defSpan(Date.today))
    verifyNull(NovantSyncActor.defSpan(Date.today+1day))
  }

  private Void verifySpan(Date? hisEnd, Date start, Date end)
  {
    span := NovantSyncActor.defSpan(hisEnd)
// echo("> $span [$span.start .. $span.end]")
    verifyEq(span.start, start)
    verifyEq(span.end,   end)
  }
}

