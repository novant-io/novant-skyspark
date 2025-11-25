# Changelog

## Version 0.41 (25-Nov-2025)
* New optimized his sync design to stay under rate limits
* Add write back support

## Version 0.40 (20-Nov-2025)
* Add func: `novantProj()`
* Add func: `novantPoints()`

## Version 0.39 (11-Nov-2025)
* Add funcs: `novantZones/Spaces/Assets/Sources`

## Version 0.38 (11-Dec-2024)
* Update endpoint to `api.novant.io`
* Fix error handling to pickup proper `msg` field

## Version 0.37 (19-Jan-2024)
* Support for learning points from `asset` tree

## Version 0.36 (12-Jun-2023)
* Support for new `ontology` field for predefined learn tags

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