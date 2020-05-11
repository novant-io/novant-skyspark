# NovantExt Spec

The `novantExt` provides integration support for sync trend data from one
or more Novant devices into SkySpark easily and efficiently.

## novantConn

Each Novant device is modeled 1:1 with a `novantConn` rec, which stores API
access credentials and information used to maintain synchronization:

  * `apiKey`: the Novant API key used to access this device
  * `novantDeviceId`: the Novant device id to synchronize
  * `novantSyncFreq`: how often a device should sync
       - `none`: do not automatically keep this device synced
       - `daily`: sync data daily
  * `novantHisStart`: Date of start of his data, or `null` for none
  * `novantHisEnd`: Date of end of his data, or `null` for none

## ProjActor

Enabling `novantExt` will start a project-wide `ProjActor` instance to manage
running background work for all conns in a project.

## Sync Design

The SkySpark connector framework provides an API for doing his syncs, however
this API works at the point level, which would be a very inefficient
implementation using the Novant REST API. So instead this extension includes a
custom implementation for managing trend data syncs.

The primary API is `NovantSyncActor` and `NovantSyncWorker`, which performe the
sync on a background actor. All syncs, for all conns, route to single ActorPool
managed by the `NovantExt` to allow fine tuning performance.






