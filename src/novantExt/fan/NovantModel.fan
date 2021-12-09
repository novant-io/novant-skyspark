//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019   Andy Frank   Creation
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
      "dis":            "Novant Conn",
      "novantConn":     Marker.val,
      "novantDeviceId": "dv_",
      "apiKey":         "ak_",
      "novantSyncFreq": "daily",
      "novantHisInterval": "15min",
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

