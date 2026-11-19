# UtilityCore

Deterministic parsing utilities for Hominem and other Apple apps.

UtilityCore provides:

- RFC-style CSV parsing with quoted fields and CRLF handling
- repeatable stable ID hashing

Generic parsing helpers are added only when two consumers prove a need.
SQL and sqlite3 process use stays with the consuming app: it is database
infrastructure, not a portable utility.

```swift
import UtilityCore

let rows = try CSVTable.parse(data)
let id = StableID.hash("walk", route.startDate)
```
