import Foundation

// MARK: - Data source protocol (platform capability passed via constructor)

@MainActor
public protocol WalkLibraryDataSource: AnyObject {
  func waitUntilReady() async
  func fetchWalkMonths(calendar: Calendar) async throws -> [WalkMonth]
  func fetchRouteSummaryPage(
    limit: Int,
    before cursor: WalkRoutePageCursor?,
    in month: WalkMonth?,
    filter: WalkSearchFilter?
  ) async throws -> WalkRouteSummaryPage
  func fetchRoute(id: UUID) async throws -> WalkRoute?
}

// MARK: - In-memory fixture store (used by CLI + tests; no network, no device)

@MainActor
public final class InMemoryWalkStore: WalkLibraryDataSource {
  private let summaries: [WalkRouteSummary]
  private let routes: [UUID: WalkRoute]
  private let months: [WalkMonth]

  public init(summaries: [WalkRouteSummary] = [], routes: [UUID: WalkRoute] = [:]) {
    self.summaries = summaries.sorted { $0.startDate > $1.startDate }
    self.routes = routes
    // group months from summaries
    let dates = summaries.map(\.startDate)
    self.months = WalkMonth.group(startDates: dates)
  }

  public func waitUntilReady() async {}

  public func fetchWalkMonths(calendar: Calendar = .current) async throws -> [WalkMonth] {
    months
  }

  public func fetchRouteSummaryPage(
    limit: Int,
    before cursor: WalkRoutePageCursor?,
    in month: WalkMonth?,
    filter: WalkSearchFilter?
  ) async throws -> WalkRouteSummaryPage {
    var list = summaries
    if let month {
      list = list.filter { $0.startDate >= month.startDate && $0.startDate < month.endDate }
    }
    if let filter {
      list = list.filter { filter.matches($0) }
    }
    if let cursor {
      list = list.filter {
        $0.startDate < cursor.startDate
          || ($0.startDate == cursor.startDate && $0.id.uuidString < cursor.id.uuidString)
      }
    }
    let page = Array(list.prefix(limit))
    let hasMore = list.count > limit
    let nextCursor: WalkRoutePageCursor? =
      hasMore && !page.isEmpty
      ? WalkRoutePageCursor(startDate: page.last!.startDate, id: page.last!.id)
      : nil
    return WalkRouteSummaryPage(summaries: page, nextCursor: nextCursor, hasMore: hasMore)
  }

  public func fetchRoute(id: UUID) async throws -> WalkRoute? {
    routes[id]
  }
}
