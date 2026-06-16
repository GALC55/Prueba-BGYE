import XCTest
@testable import BancoGYE

final class ArchivedMovementStoreTests: XCTestCase {

    private let store = ArchivedMovementStore.shared

    private func makeMovement(id: UUID = UUID()) -> Movement {
        Movement(
            id: id,
            reference: "REF-TEST",
            description: "Prueba persistencia",
            contactName: "Test Contact",
            amount: 250.00,
            type: .transfer,
            status: .completed,
            date: Date(),
            notes: nil
        )
    }

    override func tearDown() {
        // Limpia todos los movimientos creados en tests
        store.fetchAllArchived().forEach { store.unarchive(id: $0.id) }
        super.tearDown()
    }

    // MARK: Caso 1: Archivar → movimiento persiste en Core Data
    func test_archive_persists_movement_locally() {
        let movement = makeMovement()
        store.archive(movement)

        XCTAssertTrue(store.isArchived(id: movement.id))
    }

    // MARK: Caso 2: Desarchivar → elimina de Core Data
    func test_unarchive_removes_movement_from_store() {
        let movement = makeMovement()
        store.archive(movement)
        store.unarchive(id: movement.id)

        XCTAssertFalse(store.isArchived(id: movement.id))
    }

    // MARK: Caso 3: fetchAllArchived → retorna todos los archivados
    func test_fetch_all_archived_returns_all_stored_movements() {
        let m1 = makeMovement()
        let m2 = makeMovement()
        store.archive(m1)
        store.archive(m2)

        let archived = store.fetchAllArchived()
        let ids = Set(archived.map(\.id))
        XCTAssertTrue(ids.contains(m1.id))
        XCTAssertTrue(ids.contains(m2.id))
    }

    // MARK: Caso 4: Archivar mismo movimiento dos veces → no duplica
    func test_archive_same_movement_twice_does_not_duplicate() {
        let movement = makeMovement()
        store.archive(movement)
        store.archive(movement)

        let count = store.fetchAllArchived().filter { $0.id == movement.id }.count
        XCTAssertEqual(count, 1, "Duplicate archive must be idempotent")
    }

    // MARK: Caso 5: isArchived → false para movimiento no archivado
    func test_is_archived_false_for_non_archived_movement() {
        let movement = makeMovement()
        XCTAssertFalse(store.isArchived(id: movement.id))
    }

    // MARK: Caso 6: Datos del movimiento archivado se recuperan correctamente
    func test_archived_movement_data_is_preserved() {
        let id = UUID()
        let movement = Movement(
            id: id,
            reference: "REF-PERSIST",
            description: "Cobro mensual",
            contactName: "Ana García",
            amount: 999.99,
            type: .credit,
            status: .completed,
            date: Date(),
            notes: "Nota de prueba"
        )
        store.archive(movement)

        let fetched = store.fetchAllArchived().first { $0.id == id }
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.contactName, "Ana García")
        XCTAssertEqual(fetched?.amount, 999.99)
        XCTAssertEqual(fetched?.type, .credit)
        XCTAssertEqual(fetched?.notes, "Nota de prueba")
    }

    // MARK: Caso 7: Desarchivar ID inexistente → no lanza error
    func test_unarchive_nonexistent_id_is_safe() {
        XCTAssertNoThrow(store.unarchive(id: UUID()))
    }
}
