import Foundation

public struct GPXDocument: Sendable {
    public let name: String?
    public let activity: String?
    public let locations: [RouteLocation]

    public init(name: String?, activity: String?, locations: [RouteLocation]) {
        self.name = name
        self.activity = activity
        self.locations = locations
    }
}

public enum GPXParser {
    public static func parse(data: Data) -> GPXDocument? {
        let delegate = Delegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse(), !delegate.locations.isEmpty else { return nil }
        return GPXDocument(name: delegate.trackName, activity: delegate.activity, locations: delegate.locations)
    }

    public static func parse(contentsOf url: URL) -> GPXDocument? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return parse(data: data)
    }

    private final class Delegate: NSObject, XMLParserDelegate {
        var locations: [RouteLocation] = []
        var trackName: String?
        var activity: String?
        private var current: (latitude: Double, longitude: Double)?
        private var elevation: Double?
        private var timestamp: Date?
        private var text = ""
        private var collectingName = false
        private var collectingActivity = false

        private let iso = ISO8601DateFormatter()
        private let fractionalISO: ISO8601DateFormatter = {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter
        }()

        override init() {
            iso.formatOptions = [.withInternetDateTime]
            super.init()
        }

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes: [String: String] = [:]) {
            switch elementName {
            case "trkpt":
                if let latitude = Double(attributes["lat"] ?? ""), let longitude = Double(attributes["lon"] ?? "") {
                    current = (latitude, longitude)
                    elevation = nil
                    timestamp = nil
                }
            case "name":
                collectingName = trackName == nil
                text = ""
            case "type":
                collectingActivity = activity == nil
                text = ""
            case "ele", "time":
                text = ""
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            text += string
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            switch elementName {
            case "trkpt":
                if let current {
                    let location = RouteLocation(
                        latitude: current.latitude,
                        longitude: current.longitude,
                        elevation: elevation,
                        timestamp: timestamp ?? .distantPast
                    )
                    if location.isValidGPXPoint { locations.append(location) }
                }
                current = nil
                text = ""
            case "name":
                if collectingName {
                    trackName = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    collectingName = false
                }
            case "type":
                if collectingActivity {
                    activity = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    collectingActivity = false
                }
            case "ele":
                elevation = Double(text.trimmingCharacters(in: .whitespacesAndNewlines))
            case "time":
                let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
                timestamp = fractionalISO.date(from: value) ?? iso.date(from: value)
            default:
                break
            }
            if elementName != "trkpt" { text = "" }
        }
    }
}
