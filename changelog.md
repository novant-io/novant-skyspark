# Changelog

## Version 0.8 (working)
* Fix `yesterday` syncs to wait till `2:00am` to ensure full data

## Version 0.7 (22-Oct-2020)
* Update WebClient to use gzip compression
* Fix hisWrite clipping to using point tz

## Version 0.6 (18-Oct-2020)
* Improve handling of `na` data

## Version 0.5 (7-Jul-2020)
* Update learn to use source > point nesting
* Change `novantHis` tag to use `p` prefix

## Version 0.4 (17-Jun-2020)
* Add pod-doc
* Fix NPE with `dispatchSync` on background actor

## Version 0.3 (16-Jun-2020)
* Misc fixes to make sync more reliable
* Rework `novantSync` to skip already synced days be default
* Update `novantSync` to allow taking multiple conns
* Fix sync behavoir to never sync past `Date.yesterday`
* Add `{force}` option support to `novantSync`
* Add `novantHisClear` func
* Add simple ConnTool to sync/clear his using UI

## Version 0.2 (4-Jun-2020)
* Remove icon.png (not needed for StackHub)
* Fix `deviceId` -> `novantDeviceId` rename in NovantConn

## Version 0.1 (11-May-2020)
* Initial version with basic API learn and sync functionality