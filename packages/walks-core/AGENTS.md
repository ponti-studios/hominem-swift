# WalksCore

Reusable Swift package for walking-route archives.

## Commands
- Build: `swift build`
- Test: `swift test`

## Rules
- Keep HealthKit permission and app-entitlement code in host apps.
- Persistence may use Core Data and private CloudKit.
- Keep GPX, manifests, sync checkpoints, and route batching host-independent.
- No SwiftUI, UIKit, AppKit, app view models, or device presentation code in the package.