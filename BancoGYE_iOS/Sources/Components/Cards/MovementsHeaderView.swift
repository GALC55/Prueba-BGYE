import SwiftUI

struct MovementsHeaderView: View {
    @Binding var searchText: String
    @Binding var filter: MovementFilter
    let onRefresh: () -> Void
    let onSearchSubmit: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gestión")
                        .font(.title2.bold())
                    Text(Date().formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "es_EC"))))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                }
            }

            SearchBarView(text: $searchText, onSubmit: onSearchSubmit)

            FilterTabsView(selected: $filter)
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }
}
