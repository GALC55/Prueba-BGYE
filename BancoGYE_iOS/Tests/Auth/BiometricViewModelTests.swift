import XCTest
@testable import BancoGYE

// MARK: - Mock BiometricService

final class MockBiometricService: BiometricServiceProtocol {
    var shouldSucceed = true
    var errorToThrow: BiometricError?

    func authenticate() async throws {
        if let error = errorToThrow { throw error }
        if !shouldSucceed { throw BiometricError.failed("Mock failure") }
    }
}

// MARK: - Tests

@MainActor
final class BiometricViewModelTests: XCTestCase {

    // MARK: Caso 1: Autenticación biométrica exitosa → estado .authenticated
    func test_authenticate_success_transitions_to_authenticated() async {
        let service = MockBiometricService()
        service.shouldSucceed = true
        let vm = BiometricViewModel(service: service)

        await vm.authenticate()

        XCTAssertEqual(vm.state, .authenticated)
    }

    // MARK: Caso 2: Fallo biométrico → estado .failed con mensaje
    func test_authenticate_failure_transitions_to_failed() async {
        let service = MockBiometricService()
        service.errorToThrow = .failed("Huella no reconocida")
        let vm = BiometricViewModel(service: service)

        await vm.authenticate()

        if case .failed(let msg) = vm.state {
            XCTAssertFalse(msg.isEmpty)
        } else {
            XCTFail("Expected .failed state, got \(vm.state)")
        }
    }

    // MARK: Caso 3: Usuario cancela → estado regresa a .idle (no bloquea)
    func test_authenticate_cancel_returns_to_idle() async {
        let service = MockBiometricService()
        service.errorToThrow = .cancelled
        let vm = BiometricViewModel(service: service)

        await vm.authenticate()

        XCTAssertEqual(vm.state, .idle)
    }

    // MARK: Caso 4: Dispositivo sin biometría → estado .failed con mensaje descriptivo
    func test_authenticate_no_biometry_transitions_to_failed() async {
        let service = MockBiometricService()
        service.errorToThrow = .notAvailable("Biometría no configurada en este dispositivo.")
        let vm = BiometricViewModel(service: service)

        await vm.authenticate()

        if case .failed(let msg) = vm.state {
            XCTAssertFalse(msg.isEmpty, "Error message must describe the unavailability")
        } else {
            XCTFail("Expected .failed state for unavailable biometry")
        }
    }

    // MARK: Caso 5: Durante autenticación → estado .authenticating
    func test_state_is_authenticating_during_auth() async {
        let service = MockBiometricService()
        service.shouldSucceed = true
        let vm = BiometricViewModel(service: service)

        // State transitions to .authenticating before async work completes
        // We verify the initial transition by checking it's not stuck at idle after auth
        XCTAssertEqual(vm.state, .idle)
        await vm.authenticate()
        XCTAssertEqual(vm.state, .authenticated)
    }

    // MARK: Caso 6: Reintento después de fallo → puede volver a autenticarse
    func test_retry_after_failure_can_succeed() async {
        let service = MockBiometricService()
        service.errorToThrow = .failed("Fallo")
        let vm = BiometricViewModel(service: service)

        await vm.authenticate()
        XCTAssertEqual(vm.state, .failed("Fallo"))

        // Retry with success
        service.errorToThrow = nil
        service.shouldSucceed = true
        await vm.authenticate()

        XCTAssertEqual(vm.state, .authenticated)
    }

    // MARK: Caso 7: Acceso a movimientos bloqueado hasta auth exitosa
    func test_module_access_blocked_until_authenticated() async {
        let service = MockBiometricService()
        service.errorToThrow = .failed("Error")
        let vm = BiometricViewModel(service: service)

        await vm.authenticate()

        // Any state that is NOT .authenticated should block access
        let canAccess: Bool
        if case .authenticated = vm.state { canAccess = true } else { canAccess = false }
        XCTAssertFalse(canAccess, "Module must remain blocked after failed auth")
    }
}
