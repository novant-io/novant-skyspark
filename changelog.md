# Changelog

## Version 0.4 (working)
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