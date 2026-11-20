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

The monorepo floors are macOS 12, iOS 15, and watchOS 10. These keep domain packages and HominemAuth usable by apps with older deployment targets. Waveform APIs require macOS 15 / iOS 18, and its atomic ring APIs require watchOS 11; per-API availability annotations preserve those higher floors without raising the minimum for every product.
