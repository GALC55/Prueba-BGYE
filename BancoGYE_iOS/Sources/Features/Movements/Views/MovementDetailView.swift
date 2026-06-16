import SwiftUI

struct MovementDetailView: View {
    let movement: Movement
    @StateObject private var vm = MovementsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: typeIcon)
                        .font(.system(size: 48))
                        .foregroundStyle(typeColor)
                    Text(movement.amount, format: .currency(code: "USD"))
                        .font(.largeTitle.bold())
                    Text(movement.status.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }
                .padding(.top)

                VStack(spacing: 0) {
                    detailRow(label: "Contacto", value: movement.contactName)
                    Divider().padding(.leading)
                    detailRow(label: "Descripción", value: movement.description)
                    Divider().padding(.leading)
                    detailRow(label: "Referencia", value: movement.reference)
                    Divider().padding(.leading)
                    detailRow(label: "Fecha", value: movement.date.formatted(date: .long, time: .shortened))
                    Divider().padding(.leading)
                    detailRow(label: "Tipo", value: movement.type.displayName)
                    if let notes = movement.notes {
                        Divider().padding(.leading)
                        detailRow(label: "Notas", value: notes)
                    }
                }
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    vm.toggleArchive(movement: movement)
                } label: {
                    Label(
                        vm.isArchived(movement) ? "Desarchivar" : "Archivar",
                        systemImage: vm.isArchived(movement) ? "tray.and.arrow.up" : "archivebox"
                    )
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.isArchived(movement) ? Color.orange.opacity(0.12) : Color.blue.opacity(0.12))
                    .foregroundStyle(vm.isArchived(movement) ? .orange : .blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var typeIcon: String {
        switch movement.type {
        case .credit: return "arrow.down.circle.fill"
        case .debit: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }

    private var typeColor: Color {
        switch movement.type {
        case .credit: return .green
        case .debit: return .red
        case .transfer: return .blue
        }
    }
}
