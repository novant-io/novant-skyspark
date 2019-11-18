#!/bin/bash

# convience to run sketchc and build together

SS_BASE="/Users/andy/proj/sf/ss3/src/ui3/uiIcons"
EXT_BASE="/Users/andy/proj/novant/eng/skyspark/src/novantExt"

cd "$(dirname "$0")"
$SS_BASE/sketchc.fan -input $EXT_BASE/icons.sketch \
  -outDir $EXT_BASE/svg/ all && ./build.fan


