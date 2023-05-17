//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019  Andy Frank   Creation
//    8 Dec 2022  Andy Frank  Update to Apollo
//

using haystack
using connExt

**
** NovantModel
**
@Js
const class NovantModel : ConnModel
{
  new make() : super(NovantModel#.pod)
  {
    connProto = Etc.makeDict([
      "dis":          "Novant Conn",
      "novantConn":   Marker.val,
      "novantApiKey": "ak_",
    ])
  }

  override const Dict connProto
  override Type? pointAddrType()     { Str#  }
  override PollingMode pollingMode() { PollingMode.buckets }
  override Bool isLearnSupported()   { true  }
  override Bool isCurSupported()     { true  }
  override Bool isWriteSupported()   { true  }
  override Bool isHisSupported()     { true  }
}

