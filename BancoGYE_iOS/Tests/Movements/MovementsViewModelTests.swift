import XCTest
@testable import BancoGYE

// MARK: - Mock Repository

final class MockMovementsRepository: MovementsRepositoryProtocol {
    var stubbedResponse: PagedResponse<Movement>?
    var errorToThrow: Error?
    var lastRequestedPage: Int = 0
    var lastRequestedFrom: Date?
    var lastRequestedSearch: String?

    func fetchMovements(page: Int, pageSize: Int, from: Date?, to: Date?, search: String?) async throws -> PagedResponse<Movement> {
        lastRequestedPage = page
        lastRequestedFrom = from
        lastRequestedSearch = search
        if let error = errorToThrow { throw error }
        return stubbedResponse ?? PagedResponse(items: [], page: page, pageSize: pageSize, totalCount: 0, hasMore: false)
    }

    func fetchMovement(id: UUID) async throws -> Movement {
        throw APIError.notFound
    }
}

// MARK: - Helpers

func makeMovement(daysAgo: Int = 0) -> Movement {
    Movement(
        id: UUID(),
        reference: "REF-\(daysAgo)",
        description: "Test movement",
        contactName: "Test User",
        amount: 100,
        type: .credit,
        status: .completed,
        date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
        notes: nil
    )
}

// MARK: - Tests

@MainActor
final class MovementsViewModelTests: XCTestCase {

    // MARK: Caso 1: Carga inicial → llama API con últimos 30 días por defecto
    func test_initial_load_requests_last_30_days() async {
        let repo = MockMovementsRepository()
        repo.stubbedResponse = PagedResponse(items: [makeMovement()], page: 1, pageSize: 20, totalCount: 1, hasMore: false)
        let vm = MovementsViewModel(repository: repo)

        await vm.onAppear()

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        // API called from 3 months ago (max window), initial display filtered to 30 days
        XCTAssertNotNil(repo.lastRequestedFrom)
        XCTAssertEqual(repo.lastRequestedPage, 1)
    }

    // MARK: Caso 2: Carga exitosa → estado .loaded con items agrupados
    func test_successful_load_produces_loaded_state() async {
        let repo = MockMovementsRepository()
        let movements = [makeMovement(daysAgo: 0), makeMovement(daysAgo: 10), makeMovement(daysAgo: 25)]
        repo.stubbedResponse = PagedResponse(items: movements, page: 1, pageSize: 20, totalCount: 3, hasMore: false)
        let vm = MovementsViewModel(repository: repo)

        await vm.onAppear()

        if case .loaded = vm.loadState { } else {
            XCTFail("Expected .loaded, got \(vm.loadState)")
        }
        XCTAssertFalse(vm.groupedMovements.isEmpty)
    }

    // MARK: Caso 3: Sin resultados → estado .empty
    func test_empty_response_produces_empty_state() async {
        let repo = MockMovementsRepository()
        repo.stubbedResponse = PagedResponse(items: [], page: 1, pageSize: 20, totalCount: 0, hasMore: false)
        let vm = MovementsViewModel(repository: repo)

        await vm.onAppear()

        if case .empty = vm.loadState { } else {
            XCTFail("Expected .empty, got \(vm.loadState)")
        }
    }

    // MARK: Caso 4: Error de red → estado .error con mensaje
    func test_network_error_produces_error_state() async {
        let repo = MockMovementsRepository()
        repo.errorToThrow = APIError.network(URLError(.notConnectedToInternet))
        let vm = MovementsViewModel(repository: repo)

        await vm.onAppear()

        if case .error(let msg) = vm.loadState {
            XCTAssertFalse(msg.isEmpty)
        } else {
            XCTFail("Expected .error state")
        }
    }

    // MARK: Caso 5: Scroll infinito → loadMore incrementa página
    func test_load_more_increments_page() async {
        let repo = MockMovementsRepository()
        repo.stubbedResponse = PagedResponse(items: [makeMovement()], page: 1, pageSize: 20, totalCount: 100, hasMore: true)
        let vm = MovementsViewModel(repository: repo)

        await vm.onAppear()
        XCTAssertEqual(repo.lastRequestedPage, 1)

        await vm.loadMore()
        XCTAssertEqual(repo.lastRequestedPage, 2)
    }

    // MARK: Caso 6: loadMore no dispara si no hay más páginas
    func test_load_more_skips_when_no_more_pages() async {
        let repo = MockMovementsRepository()
        repo.stubbedResponse = PagedResponse(items: [makeMovement()], page: 1, pageSize: 20, totalCount: 1, hasMore: false)
        let vm = MovementsViewModel(repository: repo)

        await vm.onAppear()
        let pageAfterInitial = repo.lastRequestedPage

        await vm.loadMore()
        XCTAssertEqual(repo.lastRequestedPage, pageAfterInitial, "loadMore must not fire when hasMore is false")
    }

    // MARK: Caso 7: Pull to refresh → resetea a página 1
    func test_refresh_resets_to_page_1() async {
        let repo = MockMovementsRepository()
        repo.stubbedResponse = PagedResponse(items: [makeMovement()], page: 1, pageSize: 20, totalCount: 100, hasMore: true)
        let vm = MovementsViewModel(repository: repo)

        await vm.onAppear()
        await vm.loadMore()
        XCTAssertEqual(repo.lastRequestedPage, 2)

        await vm.refresh()
        XCTAssertEqual(repo.lastRequestedPage, 1, "Refresh must restart from page 1")
    }

    // MARK: Caso 8: Movimientos agrupados por fecha con encabezados correctos
    func test_movements_grouped_by_date_with_correct_headers() async {
        let repo = MockMovementsRepository()
        let movements = [
            makeMovement(daysAgo: 0),   // Hoy
            makeMovement(daysAgo: 10),  // Últimos 15 días
            makeMovement(daysAgo: 25),  // Últimos 30 días
            makeMovement(daysAgo: 60),  // Meses anteriores
        ]
        repo.stubbedResponse = PagedResponse(items: movements, page: 1, pageSize: 20, totalCount: 4, hasMore: false)
        let vm = MovementsViewModel(repository: repo)

        await vm.onAppear()

        let keys = vm.groupedMovements.map(\.key)
        XCTAssertTrue(keys.contains(.today))
        XCTAssertTrue(keys.contains(.last15Days))
        XCTAssertTrue(keys.contains(.last30Days))
        XCTAssertTrue(keys.contains(.older))
    }

    // MARK: Caso 9: Búsqueda pasa texto al repositorio
    func test_search_passes_text_to_repository() async {
        let repo = MockMovementsRepository()
        repo.stubbedResponse = PagedResponse(items: [], page: 1, pageSize: 20, totalCount: 0, hasMore: false)
        let vm = MovementsViewModel(repository: repo)
        vm.searchText = "Miguel"

        await vm.loadInitial()

        XCTAssertEqual(repo.lastRequestedSearch, "Miguel")
    }

    // MARK: Caso 10: Filtro Archivados muestra solo archivados locales
    func test_filter_archived_shows_only_archived_movements() async {
        let store = ArchivedMovementStore.shared
        let movement = makeMovement(daysAgo: 1)
        store.archive(movement)
        defer { store.unarchive(id: movement.id) }

        let repo = MockMovementsRepository()
        repo.stubbedResponse = PagedResponse(items: [movement], page: 1, pageSize: 20, totalCount: 1, hasMore: false)
        let vm = MovementsViewModel(repository: repo)

        await vm.onAppear()
        vm.filter = .archived
        await vm.loadInitial()

        let allIDs = vm.groupedMovements.flatMap(\.movements).map(\.id)
        XCTAssertTrue(allIDs.contains(movement.id))
    }

    // MARK: Caso 11: Filtro Archivados NO llama al API (funciona offline)
    func test_filter_archived_does_not_call_api() async {
        let store = ArchivedMovementStore.shared
        let movement = makeMovement(daysAgo: 1)
        store.archive(movement)
        defer { store.unarchive(id: movement.id) }

        let repo = MockMovementsRepository()
        repo.errorToThrow = APIError.network(URLError(.notConnectedToInternet))
        let vm = MovementsViewModel(repository: repo)
        vm.filter = .archived

        await vm.loadInitial()

        // Debe mostrar archivados locales aunque la red falle
        if case .error = vm.loadState {
            XCTFail("Archived filter must not depend on network — should show local data")
        }
        let allIDs = vm.groupedMovements.flatMap(\.movements).map(\.id)
        XCTAssertTrue(allIDs.contains(movement.id), "Archived movement must appear from local store without network")
    }

    // MARK: Caso 12: Filtro Desarchivados excluye archivados
    func test_filter_unarchived_excludes_archived_movements() async {
        let store = ArchivedMovementStore.shared
        let archivedMovement = makeMovement(daysAgo: 1)
        let normalMovement = makeMovement(daysAgo: 2)
        store.archive(archivedMovement)
        defer { store.unarchive(id: archivedMovement.id) }

        let repo = MockMovementsRepository()
        repo.stubbedResponse = PagedResponse(
            items: [archivedMovement, normalMovement],
            page: 1, pageSize: 20, totalCount: 2, hasMore: false
        )
        let vm = MovementsViewModel(repository: repo)

        await vm.onAppear()
        vm.filter = .unarchived
        await vm.loadInitial()

        let allIDs = vm.groupedMovements.flatMap(\.movements).map(\.id)
        XCTAssertFalse(allIDs.contains(archivedMovement.id), "Archived must not appear in unarchived filter")
        XCTAssertTrue(allIDs.contains(normalMovement.id))
    }
}
