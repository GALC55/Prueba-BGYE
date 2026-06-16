import SwiftUI
import Combine

enum MovementFilter: String, CaseIterable {
    case all = "Todos"
    case archived = "Archivados"
    case unarchived = "Desarchivados"
}

enum LoadState {
    case idle, loading, loadingMore, loaded, empty, error(String)
}

@MainActor
final class MovementsViewModel: ObservableObject {
    @Published var filter: MovementFilter = .all
    @Published var searchText: String = ""
    @Published var loadState: LoadState = .idle
    @Published var groupedMovements: [(key: DateGroup, movements: [Movement])] = []

    private let repository: MovementsRepositoryProtocol
    private let store = ArchivedMovementStore.shared

    private var allMovements: [Movement] = []
    private var currentPage = 1
    private var hasMore = true
    private var isLoadingMore = false
    private var searchTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?

    init(repository: MovementsRepositoryProtocol = MovementsRepository()) {
        self.repository = repository
    }

    func onAppear() async {
        await loadInitial()
    }

    func loadInitial() async {
        loadTask?.cancel()
        if filter == .archived {
            loadArchivedOffline()
            return
        }
        loadTask = Task {
            loadState = .loading
            allMovements = []
            currentPage = 1
            hasMore = true
            await loadPage()
        }
        await loadTask?.value
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore, filter != .archived else { return }
        isLoadingMore = true
        loadState = .loadingMore
        await loadPage()
        isLoadingMore = false
    }

    func refresh() async {
        await loadInitial()
    }

    func toggleArchive(movement: Movement) {
        if store.isArchived(id: movement.id) {
            store.unarchive(id: movement.id)
        } else {
            store.archive(movement)
        }
        applyFilter()
    }

    func isArchived(_ movement: Movement) -> Bool {
        store.isArchived(id: movement.id)
    }

    private func loadArchivedOffline() {
        loadState = .loading
        applyFilter()
    }

    func onSearchChange(_ text: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await loadInitial()
        }
    }

    private func loadPage() async {
        let from = Calendar.current.date(byAdding: .month, value: -3, to: Date())
        do {
            let response = try await repository.fetchMovements(
                page: currentPage,
                pageSize: 20,
                from: from,
                to: nil,
                search: searchText.isEmpty ? nil : searchText
            )
            guard !Task.isCancelled, filter != .archived else { return }
            allMovements.append(contentsOf: response.items)
            hasMore = response.hasMore
            currentPage += 1
            applyFilter()
        } catch {
            guard !Task.isCancelled, filter != .archived else { return }
            loadState = .error(error.localizedDescription)
        }
    }

    private func applyFilter() {
        let archivedIDs = Set(store.fetchAllArchived().map(\.id))
        var source: [Movement]

        switch filter {
        case .all:
            source = allMovements
        case .archived:
            source = store.fetchAllArchived()
        case .unarchived:
            source = allMovements.filter { !archivedIDs.contains($0.id) }
        }

        let grouped = Dictionary(grouping: source) { DateGroup.group(for: $0.date) }
        let order: [DateGroup] = [.today, .thisWeek, .last7Days, .last15Days, .last30Days, .older]

        groupedMovements = order.compactMap { group in
            guard let items = grouped[group], !items.isEmpty else { return nil }
            return (key: group, movements: items.sorted { $0.date > $1.date })
        }

        loadState = groupedMovements.isEmpty ? .empty : .loaded
    }
}
