# FlightCore

Flight values and airport lookup for Hominem and other Apple apps.

FlightCore provides:

- flight values with origin, destination, and duration
- an airport catalog with IATA lookup
- great-circle distances through GeoCore

No live airline APIs are included. The catalog moves to a structured airport
dataset before this package is considered mature.

```swift
import FlightCore

let flight = Flight(
  number: "BA117",
  origin: "LHR",
  destination: "JFK",
  departure: departure,
  arrival: arrival
)
let london = AirportCatalog.coordinate(for: "LHR")
```
