# GeoCore

Geographic values and route geometry for Hominem and other Apple apps.

GeoCore provides:

- `GeoCoordinate` with Haversine distance, bearing, and great-circle sampling
- `GeoBounds` with viewport and kilometer expansion
- `GeoCoordinateRegion` with route fitting and containment
- Douglas-Peucker route simplification with a point-count budget
- route length over any coordinate list

Antipodal great-circle sampling is undefined; `greatCircle` returns the
endpoints for coincident and antipodal pairs.

The consuming app owns MapKit camera state, projection, and viewport culling.

```swift
import GeoCore

let distance = RouteGeometry.length(points)
let simplified = RouteGeometry.simplify(points, maxPoints: 480)
```
