import XCTest
@testable import TransitCore
import GeoCore

/// URLProtocol stub so the TfL client is tested offline.
private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler, let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static func respond(status: Int, to url: URL, json: String = "[]") -> (HTTPURLResponse, Data) {
        (
            HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!,
            Data(json.utf8)
        )
    }
}

final class TransitCoreTests: XCTestCase {
    override func tearDown() {
        StubURLProtocol.handler = nil
        super.tearDown()
    }

    func testFetchCamerasReturnsParsedCamerasOffline() async throws {
        let json = """
        [{
          "id": "JamCams_ABC",
          "commonName": "Test Junction",
          "lat": 51.5,
          "lon": -0.1,
          "additionalProperties": [
            {"key": "view", "value": "North"},
            {"key": "available", "value": "false"},
            {"key": "imageUrl", "value": "https:\\/\\/example.com\\/camera.jpg"}
          ]
        }]
        """
        StubURLProtocol.handler = { request in
            StubURLProtocol.respond(
                status: 200,
                to: request.url!,
                json: json
            )
        }
        let client = TFLJamCamClient(session: StubURLProtocol.makeSession(), appKey: nil)

        let cameras = try await client.fetchCameras()

        XCTAssertEqual(cameras.count, 1)
        XCTAssertEqual(cameras.first?.isAvailable, false)
        XCTAssertEqual(cameras.first?.imageURL?.absoluteString, "https://example.com/camera.jpg")
    }

    func testFetchCamerasAttachesTheAppKeyQueryWhenPresent() async throws {
        let seen = LockedRequest()
        StubURLProtocol.handler = { request in
            seen.capture(request)
            return StubURLProtocol.respond(status: 200, to: request.url!)
        }
        let client = TFLJamCamClient(session: StubURLProtocol.makeSession(), appKey: "secret-test-key")

        _ = try await client.fetchCameras()

        XCTAssertEqual(seen.request?.url?.query, "app_key=secret-test-key")
    }

    func testFetchCamerasThrowsOnHTTPErrorStatus() async {
        StubURLProtocol.handler = { request in
            StubURLProtocol.respond(status: 503, to: request.url!)
        }
        let client = TFLJamCamClient(session: StubURLProtocol.makeSession(), appKey: nil)

        do {
            _ = try await client.fetchCameras()
            XCTFail("Expected badStatus")
        } catch {
            XCTAssertEqual(error as? JamCamError, .badStatus(503))
        }
    }

    func testFetchCamerasThrowsOnUnreadablePayload() async {
        StubURLProtocol.handler = { request in
            StubURLProtocol.respond(status: 200, to: request.url!, json: "not json")
        }
        let client = TFLJamCamClient(session: StubURLProtocol.makeSession(), appKey: nil)

        do {
            _ = try await client.fetchCameras()
            XCTFail("Expected badPayload")
        } catch {
            XCTAssertEqual(error as? JamCamError, .badPayload)
        }
    }

    func testTfLPayloadParsing() throws {
        let json = """
        [{
          "id": "JamCams_ABC",
          "commonName": "Test Junction",
          "lat": 51.5,
          "lon": -0.1,
          "additionalProperties": [
            {"key": "view", "value": "North"},
            {"key": "available", "value": "true"},
            {"key": "imageUrl", "value": "https://example.com/camera.jpg"}
          ]
        }]
        """.data(using: .utf8)!

        let cameras = try TFLJamCamClient.parse(json)
        XCTAssertEqual(cameras.count, 1)
        XCTAssertEqual(cameras.first?.name, "Test Junction")
        XCTAssertEqual(cameras.first?.coordinate.latitude, 51.5)
    }
}


/// Captures the outgoing request without races between the URLSession
/// queue and the test thread.
private final class LockedRequest: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: URLRequest?

    var request: URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func capture(_ request: URLRequest) {
        lock.lock()
        defer { lock.unlock() }
        stored = request
    }
}
