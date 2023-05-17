# Changelog

## Version 0.36 (working)

## Version 0.35 (17-May-2023)
* Rename `apiKey` -> `novantApiKey`

## Version 0.34 (28-Feb-2023)
* Optimize `curVal` to use `point_ids` allowlist
* Optimize `syncHis` to use queue design to batch requests
* Add `User-Agent` to API requests

## Version 0.33 (13-Jan-2023)
* Fix `novantLearn` to trimToNull `"unit"` as sanity check
* Simplify `NovantUtil.toConnPointVal` use

## Version 0.32 (14-Dec-2022)
* Update `onSyncHis` to skip `NaN` values during sync

## Version 0.31 (8-Dec-2022)
* Doc fixes

## Version 0.30 (8-Dec-2022)
* Inital version for Apollo