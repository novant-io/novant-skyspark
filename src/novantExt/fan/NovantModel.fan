//
// Copyright (c) 2019, Novant LLC
// All Rights Reserved
//
// History:
//   18 Nov 19   Andy Frank   Creation
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
      "dis":        "Novant Conn",
      "novantConn": Marker.val,
      "uri":        `http://host/novant/`,
      "deviceId":   "",
      "apiKey":     "",
    ])
  }

  override const Dict connProto
  override Type? pointAddrType() { Str# }
  override Bool isPollingSupported() { true }
  override Bool isCurSupported() { true }
}

