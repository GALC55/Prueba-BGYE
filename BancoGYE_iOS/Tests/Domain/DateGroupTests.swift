import XCTest
@testable import BancoGYE

final class DateGroupTests: XCTestCase {

    private let calendar = Calendar.current
    private let now = Date()

    // MARK: Caso 1: Movimiento de hoy → grupo "Hoy"
    func test_today_movement_groups_as_today() {
        let date = Date()
        XCTAssertEqual(DateGroup.group(for: date), .today)
    }

    // MARK: Caso 2: Movimiento de ayer (misma semana) → "Esta semana"
    func test_yesterday_same_week_groups_as_thisWeek() {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
              !calendar.isDateInToday(yesterday) else { return }

        let group = DateGroup.group(for: yesterday)
        // Could be thisWeek or last7Days depending on position in week
        XCTAssertTrue([DateGroup.thisWeek, .last7Days].contains(group))
    }

    // MARK: Caso 3: Hace 3 días → "Últimos 7 días" o "Esta semana"
    func test_3_days_ago_groups_correctly() {
        let date = calendar.date(byAdding: .day, value: -3, to: now)!
        let group = DateGroup.group(for: date)
        XCTAssertTrue([DateGroup.thisWeek, .last7Days].contains(group))
    }

    // MARK: Caso 4: Hace 10 días → "Últimos 15 días"
    func test_10_days_ago_groups_as_last15Days() {
        let date = calendar.date(byAdding: .day, value: -10, to: now)!
        XCTAssertEqual(DateGroup.group(for: date), .last15Days)
    }

    // MARK: Caso 5: Hace 20 días → "Últimos 30 días"
    func test_20_days_ago_groups_as_last30Days() {
        let date = calendar.date(byAdding: .day, value: -20, to: now)!
        XCTAssertEqual(DateGroup.group(for: date), .last30Days)
    }

    // MARK: Caso 6: Hace 45 días → "Meses anteriores"
    func test_45_days_ago_groups_as_older() {
        let date = calendar.date(byAdding: .day, value: -45, to: now)!
        XCTAssertEqual(DateGroup.group(for: date), .older)
    }

    // MARK: Caso 7: Hace 89 días (dentro de 3 meses) → "Meses anteriores"
    func test_89_days_ago_still_within_3_months() {
        let date = calendar.date(byAdding: .day, value: -89, to: now)!
        XCTAssertEqual(DateGroup.group(for: date), .older)
    }

    // MARK: Caso 8: Grupos tienen rawValue correcto (encabezados visuales)
    func test_group_raw_values_match_spec() {
        XCTAssertEqual(DateGroup.today.rawValue, "Hoy")
        XCTAssertEqual(DateGroup.thisWeek.rawValue, "Esta semana")
        XCTAssertEqual(DateGroup.last7Days.rawValue, "Últimos 7 días")
        XCTAssertEqual(DateGroup.last15Days.rawValue, "Últimos 15 días")
        XCTAssertEqual(DateGroup.last30Days.rawValue, "Últimos 30 días")
        XCTAssertEqual(DateGroup.older.rawValue, "Meses anteriores")
    }
}
