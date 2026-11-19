# ParcelCore

Parcel values and a carrier-neutral provider seam for Hominem and other Apple apps.

ParcelCore provides:

- parcel values with tracking number, carrier, status, and last known location
- a `ParcelProviding` seam for carrier implementations

The consuming app owns carrier credentials, the carrier API implementation,
refresh scheduling, notifications, and persistence. No real carrier
implementation is added to the package without a mock-first test suite and a
credential design.

```swift
import ParcelCore

let parcel = Parcel(trackingNumber: "AB123456789", carrier: "Royal Mail", status: "In transit")
```
