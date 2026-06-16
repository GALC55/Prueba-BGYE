import SwiftUI

struct MovementsView: View {
    @StateObject private var viewModel = MovementsViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                contentSection
            }
            .navigationBarHidden(true)
        }
        .task { await viewModel.onAppear() }
    }

    private var headerSection: some View {
        MovementsHeaderView(
            searchText: $viewModel.searchText,
            filter: $viewModel.filter,
            onRefresh: { Task { await viewModel.loadInitial() } },
            onSearchSubmit: { Task { await viewModel.loadInitial() } }
        )
        .onChange(of: viewModel.searchText) { _, new in
            viewModel.onSearchChange(new)
        }
        .onChange(of: viewModel.filter) { _, _ in
            Task { await viewModel.loadInitial() }
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        switch viewModel.loadState {
        case .loading:
            LoadingView()
        case .empty:
            EmptyStateView(
                subtitle: "No hay movimientos para el filtro seleccionado."
            )
        case .error(let msg):
            ErrorStateView(message: msg) {
                Task { await viewModel.loadInitial() }
            }
        default:
            movementsList
        }
    }

    private var movementsList: some View {
        List {
            ForEach(viewModel.groupedMovements, id: \.key) { group in
                Section(header: Text(group.key.rawValue)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(nil)
                ) {
                    ForEach(group.movements) { movement in
                        NavigationLink {
                            MovementDetailView(movement: movement)
                        } label: {
                            MovementCardView(
                                movement: movement,
                                isArchived: viewModel.isArchived(movement),
                                onToggleArchive: { viewModel.toggleArchive(movement: movement) }
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.hidden)
                        .onAppear {
                            if movement.id == group.movements.last?.id {
                                Task { await viewModel.loadMore() }
                            }
                        }
                    }
                }
            }

            if case .loadingMore = viewModel.loadState {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable { await viewModel.refresh() }
    }
}
