# hominem-swift

Published Swift packages for Hominem and other Apple applications.

## Packages

- [`WalksCore`](packages/walks-core) — route models, HealthKit-neutral sync state,
  Core Data and CloudKit persistence, GPX parsing/export, and iCloud publication
  for Apple apps.
- [`PlaceCore`](packages/place-core) — Apple Maps place search, portable result
  models, and stable place identities.
- [`GeoCore`](packages/geo-core) — coordinates, regions, bounds, and route geometry.
- [`UtilityCore`](packages/utility-core) — CSV parsing and stable identifiers.
- [`FlightCore`](packages/flight-core) — flight values and airport lookup.
- [`ParcelCore`](packages/parcel-core) — parcel values and provider seams.
- [`TransitCore`](packages/transit-core) — TfL stations and JamCam feed types.
- [`HominemAuth`](packages/hominem-auth) / [`HominemAuthUI`](packages/hominem-auth) — Better Auth email OTP and SwiftUI sign-in.

The monorepo floors are macOS 15, iOS 18, and watchOS 10. The watchOS floor keeps HominemAuth consumable by Thames's watchOS 10 target. HominemAuth's older iOS 15/macOS 12 support is not available through this monorepo release; consumers needing those older floors should continue using standalone HominemAuth `v0.2.0` until package layout supports per-product platform floors.
