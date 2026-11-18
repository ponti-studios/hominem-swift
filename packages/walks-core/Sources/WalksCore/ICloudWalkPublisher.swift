import Foundation

public struct ICloudWalkPublicationReport: Equatable, Sendable {
    public let routeCount: Int
    public let allFilesUploaded: Bool
    public let folderURL: URL

    public init(routeCount: Int, allFilesUploaded: Bool = false, folderURL: URL) {
        self.routeCount = routeCount
        self.allFilesUploaded = allFilesUploaded
        self.folderURL = folderURL
    }
}

public enum ICloudWalkPublisherError: LocalizedError, Equatable {
    case containerUnavailable
    case reconciliationFileMissing

    public var errorDescription: String? {
        switch self {
        case .containerUnavailable:
            "The iCloud container is unavailable."
        case .reconciliationFileMissing:
            "A route file is missing during iCloud reconciliation."
        }
    }
}

public final class ICloudWalkPublisher: @unchecked Sendable {
    public let configuration: WalkArchiveConfiguration
    private let queue = DispatchQueue(label: "io.ponti.walksc core.icloud-export", qos: .utility)

    public init(configuration: WalkArchiveConfiguration) {
        self.configuration = configuration
    }

    public convenience init(containerIdentifier: String, userVisibleFolderName: String = "Walks") {
        self.init(configuration: WalkArchiveConfiguration(
            containerIdentifier: containerIdentifier,
            userVisibleFolderName: userVisibleFolderName
        ))
    }

    public func reconcile(routes: [WalkRoute]) async throws -> ICloudWalkPublicationReport {
        try await enqueue {
            let folderURL = try self.folderURL()
            let desiredManifest = WalkExportManifest(routes: routes)

            for entry in desiredManifest.walks {
                guard let route = routes.first(where: { $0.id == entry.id }) else { continue }
                let fileURL = folderURL.appendingPathComponent(entry.filename)
                try Self.writeAtomically(GPXExporter.data(for: route), to: fileURL)
            }

            let desiredFilenames = Set(desiredManifest.walks.map(\.filename))
            let files = try FileManager.default.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            for fileURL in files where fileURL.pathExtension.lowercased() == "gpx"
                && !desiredFilenames.contains(fileURL.lastPathComponent) {
                try FileManager.default.removeItem(at: fileURL)
            }

            let manifestURL = folderURL.appendingPathComponent(self.configuration.manifestFilename)
            try Self.writeAtomically(try WalkExportManifest.encode(desiredManifest), to: manifestURL)

            for entry in desiredManifest.walks {
                let fileURL = folderURL.appendingPathComponent(entry.filename)
                guard FileManager.default.fileExists(atPath: fileURL.path) else {
                    throw ICloudWalkPublisherError.reconciliationFileMissing
                }
            }

            return ICloudWalkPublicationReport(
                routeCount: desiredManifest.walks.count,
                allFilesUploaded: false,
                folderURL: folderURL
            )
        }
    }

    public func exportFolderURL() throws -> URL {
        try folderURL()
    }

    private func folderURL() throws -> URL {
        guard let containerURL = FileManager.default.url(
            forUbiquityContainerIdentifier: configuration.containerIdentifier
        ) else {
            throw ICloudWalkPublisherError.containerUnavailable
        }
        let folderURL = containerURL.appendingPathComponent("Documents", isDirectory: true)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        return folderURL
    }

    private func enqueue<T: Sendable>(_ operation: @escaping @Sendable () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    continuation.resume(returning: try operation())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func writeAtomically(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }
}
