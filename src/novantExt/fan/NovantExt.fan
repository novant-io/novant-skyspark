//
// Copyright (c) 2019, Novant LLC
// All Rights Reserved
//
// History:
//   18 Nov 19   Andy Frank   Creation
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
  icon24  = `fan://frescoRes/img/iconMissing24.png`
  icon72  = `fan://frescoRes/img/iconMissing72.png`
  depends = ["conn"]
}
const class NovantExt : ConnImplExt
{
  static NovantExt? cur(Bool checked := true)
  {
    Context.cur.ext("novant", checked)
  }

  @NoDoc new make() : super(NovantModel()) {}
}
