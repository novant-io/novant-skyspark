//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
//
// History:
//   18 Nov 2019   Andy Frank   Creation
//

using haystack
using skyarcd
using connExt

**
** Novant Extension
**
@ExtMeta
{
  name    = "novant"
  icon    = "novant"
  depends = ["conn"]
}
const class NovantExt : ConnImplExt
{
  static NovantExt? cur(Bool checked := true)
  {
    Context.cur.ext("novant", checked)
  }

  @NoDoc new make() : super(NovantModel())
  {
  }
}
