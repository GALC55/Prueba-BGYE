import SwiftUI

struct FilterTabsView: View {
    @Binding var selected: MovementFilter

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MovementFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.subheadline.weight(selected == filter ? .semibold : .regular))
                        .foregroundStyle(selected == filter ? .white : .primary)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(selected == filter ? Color.blue : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
