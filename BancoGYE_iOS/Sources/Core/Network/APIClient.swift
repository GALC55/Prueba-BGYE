import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case network(Error)
    case decoding(Error)
    case server(Int)
    case notFound

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida"
        case .network(let e):
            if let urlError = e as? URLError {
                switch urlError.code {
                case .notConnectedToInternet: return "Sin conexión a internet."
                case .cannotConnectToHost, .cannotFindHost: return "No se pudo conectar al servidor."
                case .timedOut: return "La conexión tardó demasiado. Intenta de nuevo."
                case .networkConnectionLost: return "Se perdió la conexión. Intenta de nuevo."
                default: return "Error de red. Intenta de nuevo."
                }
            }
            return "Error de red. Intenta de nuevo."
        case .decoding(let e): return "Error de datos: \(e.localizedDescription)"
        case .server(let code): return "Error del servidor (\(code))"
        case .notFound: return "No encontrado"
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let decoder: JSONDecoder
    private let session: URLSession

    private init() {
        baseURL = URL(string: "http://192.168.1.7:8080/api")!
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { dec in
            let str = try dec.singleValueContainer().decode(String.self)
            if let date = isoFormatter.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(
                in: try dec.singleValueContainer(),
                debugDescription: "Invalid date: \(str)"
            )
        }
        session = URLSession.shared
    }

    func get<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { throw APIError.invalidURL }

        let (data, response) = try await session.data(from: url)

        if let http = response as? HTTPURLResponse {
            guard (200...299).contains(http.statusCode) else {
                if http.statusCode == 404 { throw APIError.notFound }
                throw APIError.server(http.statusCode)
            }
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}
