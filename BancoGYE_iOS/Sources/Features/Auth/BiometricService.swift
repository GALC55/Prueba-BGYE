import LocalAuthentication
import Foundation

enum BiometricError: Error, LocalizedError {
    case notAvailable(String)
    case failed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notAvailable(let msg): return msg
        case .failed(let msg): return msg
        case .cancelled: return "Autenticación cancelada"
        }
    }
}

protocol BiometricServiceProtocol {
    func authenticate() async throws
}

final class BiometricService: BiometricServiceProtocol {
    func authenticate() async throws {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Face ID locked out — fall back to passcode only
            if (error as? LAError)?.code == .biometryLockout {
                try await evaluatePasscode()
                return
            }
            let msg = error?.localizedDescription ?? "Biometría no disponible en este dispositivo."
            throw BiometricError.notAvailable(msg)
        }

        let reason = "Verifica tu identidad para acceder a tus movimientos."

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if !success {
                throw BiometricError.failed("Autenticación fallida.")
            }
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .appCancel, .systemCancel:
                throw BiometricError.cancelled
            case .userFallback:
                // User tapped "Ingresar contraseña" — show passcode screen
                try await evaluatePasscode()
            case .biometryLockout:
                try await evaluatePasscode()
            default:
                throw BiometricError.failed(laError.localizedDescription)
            }
        }
    }

    private func evaluatePasscode() async throws {
        let context = LAContext()
        let reason = "Verifica tu identidad para acceder a tus movimientos."
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            if !success {
                throw BiometricError.failed("Autenticación fallida.")
            }
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .appCancel, .systemCancel:
                throw BiometricError.cancelled
            default:
                throw BiometricError.failed(laError.localizedDescription)
            }
        }
    }
}
