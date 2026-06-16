import Foundation

protocol MovementsRepositoryProtocol {
    func fetchMovements(page: Int, pageSize: Int, from: Date?, to: Date?, search: String?) async throws -> PagedResponse<Movement>
    func fetchMovement(id: UUID) async throws -> Movement
}

final class MovementsRepository: MovementsRepositoryProtocol {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchMovements(page: Int, pageSize: Int, from: Date?, to: Date?, search: String?) async throws -> PagedResponse<Movement> {
        var items: [URLQueryItem] = [
            .init(name: "page", value: "\(page)"),
            .init(name: "pageSize", value: "\(pageSize)")
        ]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let from { items.append(.init(name: "from", value: formatter.string(from: from))) }
        if let to { items.append(.init(name: "to", value: formatter.string(from: to))) }
        if let search, !search.isEmpty { items.append(.init(name: "search", value: search)) }

        return try await client.get(path: "movements", queryItems: items)
    }

    func fetchMovement(id: UUID) async throws -> Movement {
        return try await client.get(path: "movements/\(id.uuidString)")
    }
}
