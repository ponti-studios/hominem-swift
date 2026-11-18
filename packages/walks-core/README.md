# WalksCore

Reusable Swift package for walking-route archives.

WalksCore owns the data and export boundaries shared by Apple apps:

- route and workout value models
- paged walk libraries and filters
- Core Data plus optional private CloudKit persistence
- GPX parsing and serialization
- versioned iCloud/Files export manifests
- resumable sync checkpoint state
- route-series batching

## Use

Add `WalksCore` as a local Swift package dependency, or point an app at this repository.

```swift
import WalksCore

let gpx = GPXExporter.data(for: route)
let manifest = WalkExportManifest(routes: routes)
```

HealthKit is read from the host app. The package provides route models and durable
sync/export state, but does not request HealthKit permissions or embed app entitlements.
