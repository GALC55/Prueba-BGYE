import SwiftUI

struct MovementCardView: View {
    let movement: Movement
    let isArchived: Bool
    let onToggleArchive: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: typeIcon)
                .font(.title3)
                .foregroundStyle(typeColor)
                .frame(width: 36, height: 36)
                .background(typeColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(movement.contactName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(movement.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(movement.amount, format: .currency(code: "USD"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(amountColor)
                Text(movement.status.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                onToggleArchive()
            } label: {
                Label(
                    isArchived ? "Desarchivar" : "Archivar",
                    systemImage: isArchived ? "tray.and.arrow.up" : "archivebox"
                )
            }
            .tint(isArchived ? .orange : .blue)
        }
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

    private var amountColor: Color {
        movement.type == .credit ? .green : .primary
    }
}
