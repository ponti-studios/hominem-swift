import Foundation

public struct WalkSyncCheckpoint: Codable, Equatable, Sendable {
    public var lastSyncDate: Date?
    public var pendingRouteIDs: Set<UUID>
    public var deletedRouteIDs: Set<UUID>
    public var pendingExportRouteIDs: Set<UUID>
    public var pendingExportDeletionIDs: Set<UUID>
    public var fullHistoryBackfillComplete: Bool

    public init(
        lastSyncDate: Date? = nil,
        pendingRouteIDs: Set<UUID> = [],
        deletedRouteIDs: Set<UUID> = [],
        pendingExportRouteIDs: Set<UUID> = [],
        pendingExportDeletionIDs: Set<UUID> = [],
        fullHistoryBackfillComplete: Bool = false
    ) {
        self.lastSyncDate = lastSyncDate
        self.pendingRouteIDs = pendingRouteIDs
        self.deletedRouteIDs = deletedRouteIDs
        self.pendingExportRouteIDs = pendingExportRouteIDs
        self.pendingExportDeletionIDs = pendingExportDeletionIDs
        self.fullHistoryBackfillComplete = fullHistoryBackfillComplete
    }

    public mutating func markSynced(at date: Date = .now) {
        lastSyncDate = date
    }

    public mutating func queueExport(for ids: Set<UUID>) {
        pendingExportRouteIDs.formUnion(ids)
        pendingExportDeletionIDs.subtract(ids)
    }

    public mutating func queueExportDeletion(for ids: Set<UUID>) {
        pendingExportDeletionIDs.formUnion(ids)
        pendingExportRouteIDs.subtract(ids)
    }

    public mutating func acknowledgeExport(for ids: Set<UUID>) {
        pendingExportRouteIDs.subtract(ids)
    }

    public mutating func acknowledgeExportDeletion(for ids: Set<UUID>) {
        pendingExportDeletionIDs.subtract(ids)
    }
}
