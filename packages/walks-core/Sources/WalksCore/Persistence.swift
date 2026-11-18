import CoreData
import Foundation
import CloudKit

// MARK: - Core Data entity

@objc(PersistedWalk)
public final class PersistedWalk: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var locationsData: Data?
    @NSManaged public var routeAvailable: NSNumber?
    @NSManaged public var routeLookupComplete: NSNumber?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PersistedWalk> {
        NSFetchRequest<PersistedWalk>(entityName: "PersistedWalk")
    }

    public var route: WalkRoute? {
        guard let locationsData,
              let locations = try? JSONDecoder().decode([RouteLocation].self, from: locationsData)
        else { return nil }
        return WalkRoute(id: id, startDate: startDate, endDate: endDate, locations: locations)
    }
}

// MARK: - Real store (Core Data + optional CloudKit)

@MainActor
public final class WalkStore: WalkLibraryDataSource {
    public static let shared = WalkStore()

    public let container: NSPersistentCloudKitContainer
    public private(set) var loadError: Error?
    private var isReady = false
    private var readinessContinuations: [CheckedContinuation<Void, Never>] = []

    public init(
        inMemory: Bool = false,
        storeURL: URL? = nil,
        cloudKitContainerIdentifier: String? = ICloudExportConfiguration.containerIdentifier
    ) {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "PersistedWalk"
        entity.managedObjectClassName = NSStringFromClass(PersistedWalk.self)

        func attribute(_ name: String, type: NSAttributeType) -> NSAttributeDescription {
            let description = NSAttributeDescription()
            description.name = name
            description.attributeType = type
            description.isOptional = true
            return description
        }

        entity.properties = [
            attribute("id", type: .UUIDAttributeType),
            attribute("startDate", type: .dateAttributeType),
            attribute("endDate", type: .dateAttributeType),
            attribute("locationsData", type: .binaryDataAttributeType),
            attribute("routeAvailable", type: .booleanAttributeType),
            attribute("routeLookupComplete", type: .booleanAttributeType)
        ]
        model.entities = [entity]

        container = NSPersistentCloudKitContainer(name: "WalksGPX", managedObjectModel: model)
        let resolvedURL: URL?
        if inMemory {
            resolvedURL = nil
        } else {
            let applicationSupportURL = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
            let persistentStoreURL = storeURL ?? applicationSupportURL.appendingPathComponent("WalksGPX.sqlite")
            resolvedURL = persistentStoreURL
            try? FileManager.default.createDirectory(
                at: persistentStoreURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        }
        let description = Self.makePersistentStoreDescription(
            storeURL: resolvedURL,
            inMemory: inMemory,
            cloudKitContainerIdentifier: Self.resolvedCloudKitContainerIdentifier(
                configured: cloudKitContainerIdentifier,
                environment: ProcessInfo.processInfo.environment
            )
        )
        container.persistentStoreDescriptions = [description]
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        container.loadPersistentStores { _, error in
            Task { @MainActor in
                self.loadError = error
                self.isReady = true
                for continuation in self.readinessContinuations {
                    continuation.resume()
                }
                self.readinessContinuations.removeAll()
                if let error {
                    let nsError = error as NSError
                    print("WalkStore failed to load: \(nsError), userInfo: \(nsError.userInfo)")
                }
            }
        }
    }

    public static func resolvedCloudKitContainerIdentifier(
        configured: String?,
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> String? {
        let cloudKitDisabledForTests = arguments.contains("--walksgpx-disable-cloudkit")
            || environment["WALKSGPX_DISABLE_CLOUDKIT"] == "1"
            || environment["XCTestConfigurationFilePath"] != nil
        guard !cloudKitDisabledForTests else { return nil }
        return configured
    }

    public static func makePersistentStoreDescription(
        storeURL: URL?,
        inMemory: Bool,
        cloudKitContainerIdentifier: String?
    ) -> NSPersistentStoreDescription {
        let description = NSPersistentStoreDescription()
        if inMemory {
            description.type = NSInMemoryStoreType
        } else {
            description.type = NSSQLiteStoreType
            description.url = storeURL
        }
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        if !inMemory, let cloudKitContainerIdentifier {
            let options = NSPersistentCloudKitContainerOptions(
                containerIdentifier: cloudKitContainerIdentifier
            )
            options.databaseScope = .private
            description.cloudKitContainerOptions = options
        }
        return description
    }

    public func waitUntilReady() async {
        guard !isReady else { return }
        await withCheckedContinuation { continuation in
            readinessContinuations.append(continuation)
        }
    }

    // MARK: WalkLibraryDataSource

    public func fetchWalkMonths(calendar: Calendar = .current) async throws -> [WalkMonth] {
        if let loadError { throw loadError }
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = NSFetchRequest<NSDictionary>(entityName: "PersistedWalk")
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["startDate"]
            let dates = try context.fetch(request).compactMap { $0["startDate"] as? Date }
            return WalkMonth.group(startDates: dates, calendar: calendar)
        }
    }

    public func fetchRoute(id: UUID) async throws -> WalkRoute? {
        if let loadError { throw loadError }
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = PersistedWalk.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
            request.fetchLimit = 1
            return try context.fetch(request).first?.route
        }
    }

    public func fetchRouteSummaryPage(
        limit: Int,
        before cursor: WalkRoutePageCursor? = nil,
        in month: WalkMonth? = nil,
        filter: WalkSearchFilter? = nil
    ) async throws -> WalkRouteSummaryPage {
        if let loadError { throw loadError }

        let pageSize = max(1, limit)
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = NSFetchRequest<NSDictionary>(entityName: "PersistedWalk")
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["id", "startDate", "endDate", "routeAvailable"]
            request.sortDescriptors = [
                NSSortDescriptor(key: #keyPath(PersistedWalk.startDate), ascending: false),
                NSSortDescriptor(key: #keyPath(PersistedWalk.id), ascending: true)
            ]
            var predicates: [NSPredicate] = []
            if let month {
                predicates.append(NSPredicate(
                    format: "startDate >= %@ AND startDate < %@",
                    month.startDate as NSDate,
                    month.endDate as NSDate
                ))
            }
            if let startDate = filter?.startDate {
                predicates.append(NSPredicate(format: "startDate >= %@", startDate as NSDate))
            }
            if let endDate = filter?.endDate {
                predicates.append(NSPredicate(format: "startDate < %@", endDate as NSDate))
            }
            if let requiresGPSRoute = filter?.requiresGPSRoute {
                predicates.append(requiresGPSRoute
                    ? NSPredicate(format: "routeAvailable == YES OR routeAvailable == nil")
                    : NSPredicate(format: "routeAvailable == NO"))
            }
            if !predicates.isEmpty {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }

            let scanBatchSize = max(100, pageSize + 1)
            var scanCursor = cursor
            var matches: [WalkRouteSummary] = []
            var exhausted = false
            while matches.count <= pageSize && !exhausted {
                var scanPredicates = predicates
                if let scanCursor {
                    scanPredicates.append(NSPredicate(
                        format: "startDate < %@ OR (startDate == %@ AND id > %@)",
                        scanCursor.startDate as NSDate,
                        scanCursor.startDate as NSDate,
                        scanCursor.id as NSUUID
                    ))
                }
                request.predicate = scanPredicates.isEmpty
                    ? nil
                    : NSCompoundPredicate(andPredicateWithSubpredicates: scanPredicates)
                request.fetchLimit = scanBatchSize
                let rows = try context.fetch(request)
                guard !rows.isEmpty else {
                    exhausted = true
                    break
                }
                for row in rows {
                    guard
                        let id = row["id"] as? UUID,
                        let startDate = row["startDate"] as? Date,
                        let endDate = row["endDate"] as? Date
                    else { continue }
                    let hasGPSRoute = (row["routeAvailable"] as? NSNumber)?.boolValue ?? true
                    let summary = WalkRouteSummary(
                        id: id,
                        startDate: startDate,
                        endDate: endDate,
                        hasGPSRoute: hasGPSRoute
                    )
                    scanCursor = WalkRoutePageCursor(startDate: startDate, id: id)
                    if filter?.matches(summary) ?? true { matches.append(summary) }
                    if matches.count > pageSize { break }
                }
                exhausted = rows.count < scanBatchSize
            }
            let hasMore = matches.count > pageSize
            let summaries = Array(matches.prefix(pageSize))
            let nextCursor = hasMore ? summaries.last.map {
                WalkRoutePageCursor(startDate: $0.startDate, id: $0.id)
            } : nil
            return WalkRouteSummaryPage(summaries: summaries, nextCursor: nextCursor, hasMore: hasMore)
        }
    }

    // MARK: Additional persistence API used by the app

    public func save(_ routes: [WalkRoute]) throws {
        guard !routes.isEmpty else { return }
        if let loadError { throw loadError }
        let context = container.viewContext
        try context.performAndWait {
            let request = PersistedWalk.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", routes.map(\.id))
            let existing = try context.fetch(request)
            let byID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
            for route in routes {
                let walk = byID[route.id] ?? PersistedWalk(context: context)
                walk.id = route.id
                walk.startDate = route.startDate
                walk.endDate = route.endDate
                walk.locationsData = try JSONEncoder().encode(route.locations)
                walk.routeAvailable = true
                walk.routeLookupComplete = true
            }
            if context.hasChanges { try context.save() }
        }
    }

    public func saveWorkoutMetadata(_ metadata: [WalkMetadata]) async throws {
        guard !metadata.isEmpty else { return }
        if let loadError { throw loadError }
        let context = container.newBackgroundContext()
        try await context.perform {
            let request = PersistedWalk.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", metadata.map(\.id))
            let existing = try context.fetch(request)
            let byID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            for item in metadata {
                let walk = byID[item.id] ?? PersistedWalk(context: context)
                walk.id = item.id
                walk.startDate = item.startDate
                walk.endDate = item.endDate
                if walk.routeLookupComplete == nil {
                    if walk.locationsData != nil {
                        walk.routeAvailable = true
                        walk.routeLookupComplete = true
                    } else if walk.routeAvailable?.boolValue == false {
                        walk.routeLookupComplete = true
                    } else {
                        walk.routeAvailable = false
                        walk.routeLookupComplete = false
                    }
                }
            }
            if context.hasChanges { try context.save() }
        }
    }

    public func markRoutesUnavailable(ids: Set<UUID>) async throws {
        guard !ids.isEmpty else { return }
        if let loadError { throw loadError }
        let context = container.newBackgroundContext()
        try await context.perform {
            let request = PersistedWalk.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", Array(ids))
            for walk in try context.fetch(request) where walk.locationsData == nil {
                walk.routeAvailable = false
                walk.routeLookupComplete = true
            }
            if context.hasChanges { try context.save() }
        }
    }

    public func saveRoutes(_ routes: [WalkRoute]) async throws {
        guard !routes.isEmpty else { return }
        if let loadError { throw loadError }
        let encodedRoutes = try await Task.detached(priority: .utility) {
            try routes.map { route in
                (route, try JSONEncoder().encode(route.locations))
            }
        }.value
        let context = container.newBackgroundContext()
        try await context.perform {
            let request = PersistedWalk.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", encodedRoutes.map { $0.0.id })
            let existing = try context.fetch(request)
            let byID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            for (route, data) in encodedRoutes {
                let walk = byID[route.id] ?? PersistedWalk(context: context)
                walk.id = route.id
                walk.startDate = route.startDate
                walk.endDate = route.endDate
                walk.locationsData = data
                walk.routeAvailable = true
                walk.routeLookupComplete = true
            }
            if context.hasChanges { try context.save() }
        }
    }

    public func delete(ids: Set<UUID>) throws {
        guard !ids.isEmpty else { return }
        if let loadError { throw loadError }
        let context = container.viewContext
        try context.performAndWait {
            let request = PersistedWalk.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", ids)
            for walk in try context.fetch(request) {
                context.delete(walk)
            }
            if context.hasChanges { try context.save() }
        }
    }

    public func fetchRoutes() -> [WalkRoute] {
        let request = PersistedWalk.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(PersistedWalk.startDate), ascending: false)]
        return ((try? container.viewContext.fetch(request)) ?? []).compactMap(\.route)
    }

    public func fetchRouteIDs(for workoutIDs: Set<UUID>) async throws -> Set<UUID> {
        guard !workoutIDs.isEmpty else { return [] }
        if let loadError { throw loadError }
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = NSFetchRequest<NSDictionary>(entityName: "PersistedWalk")
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["id", "routeAvailable"]
            request.predicate = NSPredicate(format: "id IN %@", Array(workoutIDs))
            return Set(try context.fetch(request).compactMap { row in
                guard let id = row["id"] as? UUID else { return nil }
                let available = (row["routeAvailable"] as? NSNumber)?.boolValue ?? true
                return available ? id : nil
            })
        }
    }

    public func fetchRouteReadCandidateIDs(for workoutIDs: Set<UUID>) async throws -> Set<UUID> {
        guard !workoutIDs.isEmpty else { return [] }
        if let loadError { throw loadError }
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = NSFetchRequest<NSDictionary>(entityName: "PersistedWalk")
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["id", "routeLookupComplete", "routeAvailable"]
            request.predicate = NSPredicate(
                format: "id IN %@ AND (routeLookupComplete == NO OR (routeLookupComplete == nil AND (routeAvailable == nil OR (routeAvailable == YES AND locationsData == nil))))",
                Array(workoutIDs)
            )
            return Set(try context.fetch(request).compactMap { row in
                guard let id = row["id"] as? UUID else { return nil }
                let lookupComplete = (row["routeLookupComplete"] as? NSNumber)?.boolValue
                if lookupComplete == true { return nil }
                return id
            })
        }
    }

    public func fetchAllRouteIDs(requiringGPSRoute: Bool = true) async throws -> Set<UUID> {
        if let loadError { throw loadError }
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = NSFetchRequest<NSDictionary>(entityName: "PersistedWalk")
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = ["id", "routeAvailable"]
            request.predicate = requiringGPSRoute
                ? NSPredicate(format: "routeAvailable == YES OR routeAvailable == nil")
                : NSPredicate(format: "routeAvailable == NO")
            return Set(try context.fetch(request).compactMap { row in
                guard let id = row["id"] as? UUID else { return nil }
                let available = (row["routeAvailable"] as? NSNumber)?.boolValue ?? true
                return available == requiringGPSRoute ? id : nil
            })
        }
    }

    public func fetchRoutes(ids: [UUID]) async throws -> [WalkRoute] {
        guard !ids.isEmpty else { return [] }
        if let loadError { throw loadError }
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = PersistedWalk.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", ids)
            return try context.fetch(request).compactMap(\.route)
        }
    }

    public func fetchWalkCount(requiringGPSRoute: Bool? = nil) async throws -> Int {
        if let loadError { throw loadError }
        let context = container.newBackgroundContext()
        return try await context.perform {
            let request = PersistedWalk.fetchRequest()
            if let requiringGPSRoute {
                request.predicate = requiringGPSRoute
                    ? NSPredicate(format: "routeAvailable == YES OR routeAvailable == nil")
                    : NSPredicate(format: "routeAvailable == NO")
            }
            return try context.count(for: request)
        }
    }
}