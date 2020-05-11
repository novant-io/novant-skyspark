#! /usr/bin/env fan
//
// Copyright (c) 2019, Novant LLC
// All Rights Reserved
//
// History:
//   18 Nov 2019   Andy Frank   Creation
//

using build

**
** Build: novantExt
**
class Build : BuildPod
{
  new make()
  {
    podName = "novantExt"
    summary = "Novant Connector"
    version = Version("0.1")
    meta    = [
                "org.name":     "Novant LLC",
                "license.name": "Commercial",
                "skyarc.icons": "true",
              ]
    depends = ["sys 1.0",
               "util 1.0",
               "concurrent 1.0",
               "web 1.0",
               "haystack 3.0",
               "folio 3.0",
               "axon 3.0",
               "skyarcd 3.0",
               "connExt 3.0",
               "fresco 3.0"]
    srcDirs = [`fan/`,
               `test/`]
    resDirs = [`doc/`,
               `locale/`,
               `lib/`,
               `svg/`]
    index   =
    [
      "skyarc.ext": "novantExt::NovantExt",
      "skyarc.lib": "novantExt::NovantLib",
    ]
  }
}
