import Foundation

/// Role: Tape. Typed wire faults. This product has no remote catalog.
enum TapeWire: Error, Equatable, Sendable {
    case vacant
    case bent
    case snapped
    case waved
    case stray
}

/// Role: Tape. One HTTP exchange. Tests inject a script.
protocol TapeCarrying: Sendable {
    func carry(_ request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Tape. 15 s timeout and the app User-Agent on every request.
struct TapeSession: TapeCarrying, Sendable {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = TapeHeaders.timeout
        configuration.timeoutIntervalForResource = TapeHeaders.timeout
        configuration.httpAdditionalHeaders = ["User-Agent": TapeHeaders.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func carry(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

enum TapeHeaders {
    static let userAgent = "Pitchtape/1.0 (iOS; +https://zalupik-pupiuk.pro)"
    static let timeout: TimeInterval = 15
    static let holdNanoseconds: UInt64 = 300_000_000
}

/// Role: Tape. JSON number or numeric string. Missing stays nil.
struct TapeLooseFigure: Sendable, Equatable {
    var value: Double?
}

extension TapeLooseFigure: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
            return
        }
        if let number = try? container.decode(Double.self) {
            value = number
            return
        }
        if let number = try? container.decode(Int.self) {
            value = Double(number)
            return
        }
        if let text = try? container.decode(String.self) {
            value = Double(text)
            return
        }
        value = nil
    }
}

/// Role: Tape. status 0 means vacant. No Open Food Facts catalog is wired.
enum TapeCatalog {
    static func accept(status: Int) throws {
        if status == 0 { throw TapeWire.vacant }
    }
}

/// Role: Tape. Owns the session. Decode DTO then map — never into domain types.
actor TapeClient {
    static let userAgent = TapeHeaders.userAgent

    private let carrier: any TapeCarrying
    private let holdNanoseconds: UInt64
    private var lookupToken: UUID?

    init(carrier: any TapeCarrying, holdNanoseconds: UInt64 = TapeHeaders.holdNanoseconds) {
        self.carrier = carrier
        self.holdNanoseconds = holdNanoseconds
    }

    init() {
        self.carrier = TapeSession()
        self.holdNanoseconds = TapeHeaders.holdNanoseconds
    }

    func pull<DTO: Decodable & Sendable>(_ type: DTO.Type, at url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let body = try await cargo(request(at: url), attempt: 0)
        do {
            return try JSONDecoder().decode(DTO.self, from: body)
        } catch is CancellationError {
            throw TapeWire.waved
        } catch {
            throw TapeWire.bent
        }
    }

    func lookup<DTO: Decodable & Sendable>(_ type: DTO.Type, query: String, at url: URL) async throws -> DTO {
        let token = UUID()
        lookupToken = token
        if holdNanoseconds > 0 {
            try await Task.sleep(nanoseconds: holdNanoseconds)
        }
        try Task.checkCancellation()
        guard lookupToken == token else { throw TapeWire.waved }
        _ = query
        return try await pull(type, at: url)
    }

    private func request(at url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: TapeHeaders.timeout)
        request.setValue(TapeHeaders.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func cargo(_ request: URLRequest, attempt: Int) async throws -> Data {
        do {
            return try await fire(request)
        } catch let wire as TapeWire {
            throw wire
        } catch is CancellationError {
            throw TapeWire.waved
        } catch {
            if tapeWaved(error) { throw TapeWire.waved }
            guard attempt == 0, tapeTransient(error) else { throw TapeWire.snapped }
            return try await cargo(request, attempt: 1)
        }
    }

    private func fire(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await carrier.carry(request)
        guard let http = response as? HTTPURLResponse else {
            throw TapeWire.stray
        }
        if http.statusCode == 404 {
            throw TapeWire.vacant
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw TapeWire.snapped
        }
        return data
    }
}

func tapeTransient(_ error: Error) -> Bool {
    guard let urlError = error as? URLError else { return false }
    switch urlError.code {
    case .timedOut, .networkConnectionLost, .notConnectedToInternet,
         .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
        return true
    default:
        return false
    }
}

func tapeWaved(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    return (error as? URLError)?.code == .cancelled
}
