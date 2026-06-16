import Foundation

struct Movement: Identifiable, Codable, Equatable {
    let id: UUID
    let reference: String
    let description: String
    let contactName: String
    let amount: Decimal
    let type: MovementType
    let status: MovementStatus
    let date: Date
    let notes: String?
}

enum MovementType: String, Codable {
    case credit = "Credit"
    case debit = "Debit"
    case transfer = "Transfer"

    var displayName: String {
        switch self {
        case .credit: return "Crédito"
        case .debit: return "Débito"
        case .transfer: return "Transferencia"
        }
    }
}

enum MovementStatus: String, Codable {
    case pending = "Pending"
    case completed = "Completed"
    case failed = "Failed"

    var displayName: String {
        switch self {
        case .pending: return "Pendiente"
        case .completed: return "Cobrado"
        case .failed: return "Fallido"
        }
    }
}

struct PagedResponse<T: Codable>: Codable {
    let items: [T]
    let page: Int
    let pageSize: Int
    let totalCount: Int
    let hasMore: Bool
}

enum DateGroup: String, Hashable {
    case today = "Hoy"
    case thisWeek = "Esta semana"
    case last7Days = "Últimos 7 días"
    case last15Days = "Últimos 15 días"
    case last30Days = "Últimos 30 días"
    case older = "Meses anteriores"

    static func group(for date: Date) -> DateGroup {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) { return .today }
        if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) { return .thisWeek }

        let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        if days <= 7 { return .last7Days }
        if days <= 15 { return .last15Days }
        if days <= 30 { return .last30Days }
        return .older
    }
}
