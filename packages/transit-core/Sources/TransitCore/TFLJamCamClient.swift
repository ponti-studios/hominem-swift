import Foundation
import GeoCore

public struct TFLJamCamClient: JamCamProviding {
  public static let endpoint = URL(string: "https://api.tfl.gov.uk/Place/Type/JamCam")!

  private let session: URLSession
  private let appKey: String?

  public init(session: URLSession? = nil, appKey: String? = nil) {
    self.session = session ?? .shared
    self.appKey = appKey ?? ProcessInfo.processInfo.environment["TFL_APP_KEY"]
  }

  public func fetchCameras() async throws -> [JamCam] {
    var components = URLComponents(url: Self.endpoint, resolvingAgainstBaseURL: false)!
    if let appKey, !appKey.isEmpty {
      components.queryItems = [URLQueryItem(name: "app_key", value: appKey)]
    }
    var request = URLRequest(url: components.url!)
    request.timeoutInterval = 20
    request.setValue("Hominem/1.0 (TfL JamCam viewer)", forHTTPHeaderField: "User-Agent")

    let (data, response) = try await session.data(for: request)
    if let http = response as? HTTPURLResponse,
      !(200..<300).contains(http.statusCode)
    {
      throw JamCamError.badStatus(http.statusCode)
    }
    return try await Task.detached(priority: .userInitiated) {
      try Self.parse(data)
    }.value
  }

  public static func parse(_ data: Data) throws -> [JamCam] {
    let places: [Place]
    do {
      places = try JSONDecoder().decode([Place].self, from: data)
    } catch {
      throw JamCamError.badPayload
    }

    return places.compactMap { place -> JamCam? in
      guard !place.commonName.isEmpty,
        place.lat.isFinite,
        place.lon.isFinite,
        (-90...90).contains(place.lat),
        (-180...180).contains(place.lon)
      else {
        return nil
      }

      let properties = Dictionary(
        place.additionalProperties.map { ($0.key, $0.value) },
        uniquingKeysWith: { first, _ in first }
      )
      let key = place.id.replacingOccurrences(of: "JamCams_", with: "")
      let fallbackImage = URL(
        string: "https://s3-eu-west-1.amazonaws.com/jamcams.tfl.gov.uk/\(key).jpg"
      )
      let available = properties["available"]?.lowercased() != "false"

      return JamCam(
        id: place.id,
        name: clean(place.commonName),
        coordinate: GeoCoordinate(latitude: place.lat, longitude: place.lon),
        view: clean(properties["view"] ?? ""),
        imageURL: properties["imageUrl"].flatMap(URL.init(string:)) ?? fallbackImage,
        videoURL: properties["videoUrl"].flatMap(URL.init(string:)),
        isAvailable: available
      )
    }
    .sorted {
      $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
    }
  }

  private static func clean(_ value: String) -> String {
    value.replacingOccurrences(of: "\\/", with: "/")
  }

  private struct Place: Decodable {
    let id: String
    let commonName: String
    let lat: Double
    let lon: Double
    let additionalProperties: [Property]

    struct Property: Decodable {
      let key: String
      let value: String

      init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        if let string = try? container.decode(String.self, forKey: .value) {
          value = string
        } else if let bool = try? container.decode(Bool.self, forKey: .value) {
          value = bool ? "true" : "false"
        } else {
          value = ""
        }
      }

      enum CodingKeys: String, CodingKey {
        case key
        case value
      }
    }

    enum CodingKeys: String, CodingKey {
      case id
      case commonName
      case lat
      case lon
      case additionalProperties
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      id = try container.decode(String.self, forKey: .id)
      commonName = try container.decodeIfPresent(String.self, forKey: .commonName) ?? ""
      lat = try container.decode(Double.self, forKey: .lat)
      lon = try container.decode(Double.self, forKey: .lon)
      additionalProperties =
        try container.decodeIfPresent([Property].self, forKey: .additionalProperties) ?? []
    }
  }
}
