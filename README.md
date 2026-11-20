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
- [`WaveformCore`](packages/waveform), [`WaveformUI`](packages/waveform), [`WaveformCapture`](packages/waveform) — audio waveform, spectrum orb, and recording engine. See the [Waveform README](packages/waveform/README.md) for the live demo and coverage gate.

The monorepo platform floors are macOS 15 and iOS 18, set by Waveform's audio implementation. This means HominemAuth's iOS 15/macOS 12 support is not available through this monorepo release; consumers needing those older floors should continue using the standalone HominemAuth `v0.2.0` package until the package layout supports per-product platform floors.
