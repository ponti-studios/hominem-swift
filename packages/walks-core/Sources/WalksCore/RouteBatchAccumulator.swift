import Foundation

public final class RouteBatchAccumulator<Location: Sendable>: @unchecked Sendable {
  private let lock = NSLock()
  private var locations: [Location] = []
  private var remainingSeries: Int
  private var finished = false

  public init(routeSeriesCount: Int) {
    remainingSeries = routeSeriesCount
  }

  public func append(_ locations: [Location]?, completed: Bool) -> (
    locations: [Location]?, finished: Bool
  ) {
    lock.lock()
    defer { lock.unlock() }
    guard !finished else { return (nil, false) }
    if let locations { self.locations.append(contentsOf: locations) }
    guard completed else { return (nil, false) }
    remainingSeries -= 1
    guard remainingSeries == 0 else { return (nil, false) }
    finished = true
    return (self.locations, true)
  }
}
