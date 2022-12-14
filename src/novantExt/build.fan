#! /usr/bin/env fan
//
// Copyright (c) 2019, Novant LLC
// Licensed under the MIT License
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
    version = Version("0.33")
    meta    = [
      "org.name":     "Novant LLC",
      "license.name": "MIT",
      "skyarc.icons": "true",
      "skyspark.docExt": "true"
    ]
    depends = [
      "sys 1.0",
      "util 1.0",
      "concurrent 1.0",
      "web 1.0",
      "dom 1.0",
      "graphics 1.0",
      "domkit 1.0",
      "haystack 3.1",
      "folio 3.1",
      "axon 3.1",
      "skyarcd 3.1",
      "connExt 3.1",
      "ui 3.1"
    ]
    srcDirs = [`fan/`, `test/`]
    resDirs = [`locale/`, `lib/`, `svg/`]
    index   =
    [
      "skyarc.ext": "novantExt::NovantExt",
      "skyarc.lib": "novantExt::NovantLib",
    ]
  }
}
