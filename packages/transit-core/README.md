# TransitCore

TfL station and JamCam types for Hominem and other Apple apps.

TransitCore provides:

- JamCam values with coordinates, view, image, and availability
- a `JamCamProviding` seam
- a `TFLJamCamClient` with typed HTTP errors
- payload parsing tolerant of TfL's escaped-slash JSON

The default test suite makes no live network calls. An optional TfL app key is
attached as the `app_key` query parameter; pass it through `init` or the
`TFL_APP_KEY` environment variable, which must hold a TfL-issued key, never a
secret the app owns. The consuming app owns live refresh scheduling, cache
policy, and UI presentation.

```swift
import TransitCore

let client = TFLJamCamClient()
let cameras = try await client.fetchCameras()
```
