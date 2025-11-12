# Novant Connector for SkySpark

The `novantExt` implements [SkySpark](https://skyfoundry.com) connector support
for the [Novant](https://novant.io) Digital Foundation:

  * Read live data from Novant projects
  * Write values back to Novant projects
  * Sync trend data from Novant projects

## Installing

[rel]: https://github.com/novant-io/novant-skyspark/releases

The recommended method to install the `novantExt` is using the Install Manager
tool in SkySpark. You may also manually download the pod from [Releases][rel]
and copy into the `lib/fan/` folder. A restart is required for the extension to
take effect.

## API Keys

API keys are required to access data from Novant projects.  It's recommended
you create a specific API key just for SkySpark access.  See Novant
documentation for how to create an API key for your project.


## Connectors

Each connector in SkySpark maps 1:1 to a Novant project. To create and map a
new connector:

    novantConn
    dis: "My Device"
    novantApiKey: "***********"

Where `novantApiKey` is the key you generated from the Novant platform.

## Cur/Write/His

Current values are configured using the `novantCur` tag on a point. Writable
points use the `novantWrite` tag.  Likewise histories use the `novantHis` tag.
The value of these tags maps to the point ID for the Novant point, which will
be in the format of `"s.{sourceId}.{pointId}"`.

    point
    dis: "My Point"
    novantCur: "s.1.5"
    novantWrite: "s.1.5"
    novantHis: "s.1.5"
    equipRef: @equip-id
    siteRef: @site-id
    kind: "Number"
    unit: "kW"

The SkySpark write level will be carried over directly into the downstream
I/O device under the Novant gateway.  For protocols that support priority, like
Bacnet, this means the Bacnet priority array level matches the SkySpark write
level. For protocols that do not support priority (such as Modbus) this value
is ignored.

## Learn

The Novant connector supports learning.  Once a connector has been added, you
can use the Site Builder to walk the device tree and add any or all points.

## His Sync

Novant connectors do not support `hisCollect`.  History can be synced using the
standard SkySpark tools and with Axon using `novantSyncHis`.  For example:

    readAll(point and novantHis).novantSyncHis(2023-02-01)

History sync operates by queueing `syncHis` requests and attempting to batch
request points in bulk to optimize API requests.

## API Funcs

Several funcs are available to access the [Novant API](https://docs.novant.io/api)
from Axon:

 * `novantZones`
 * `novantSpaces`
 * `novantAssets`
 * `novantSources`

Where each takes a connector instance as an argument:

    read(novantConn).novantAssets
