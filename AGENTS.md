# Hominem Swift Monorepo

## Packages

Add reusable Swift packages under `packages/<package-name>/`.

Each package must contain its own `Package.swift`, README, sources, and tests.
Keep platform and app entitlement code in the consuming app.

## Checks

Run package checks from the package directory:

```sh
swift test
swift build
```
