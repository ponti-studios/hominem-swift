# HominemAuth

Better Auth email OTP authentication for Hominem and other Apple apps.

HominemAuth provides:

- `AuthClient` (actor) — email OTP request, verify, session refresh, sign-out,
  and authenticated requests with automatic cookie handling
- `AuthConfiguration` — base URL, origin, Keychain service and optional shared
  access group, request timeout, user-agent
- `SessionStore` — cookie storage backed by Keychain, with shared access-group
  support for multi-app SSO
- `KeychainStore` — type-safe Keychain wrapper
- `HominemAuthError` and `AuthProblem` — typed errors grouped into the
  categories a screen cares about (network, server, session-expired, etc.)
- `AuthUser` — decoded from the Better Auth `/session` endpoint

HominemAuthUI adds SwiftUI controls for sign-in (`SignInView`) and status
display (`AuthStatusControl`). UI types use `@Observable` and are gated at
iOS 17 / macOS 14.

The consuming app owns its entitlements and Keychain group. The package does
not embed app-specific entitlements or environment assumptions.

```swift
import HominemAuth

let client = AuthClient(
  baseURL: URL(string: "https://auth.example.com")!
)
try await client.requestOTP(email: "hello@example.com")
let session = try await client.verifyOTP(email: "hello@example.com", otp: "123456")
let user = try await client.getSession()
```

## Platform floors

- Core (`HominemAuth`): iOS 15, macOS 12
- UI (`HominemAuthUI`): iOS 17, macOS 14 (uses `@Observable`)
