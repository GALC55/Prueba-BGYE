import SwiftUI

enum AuthState: Equatable {
    case idle
    case authenticating
    case authenticated
    case failed(String)
}

@MainActor
final class BiometricViewModel: ObservableObject {
    @Published var state: AuthState = .idle

    private let service: BiometricServiceProtocol

    init(service: BiometricServiceProtocol = BiometricService()) {
        self.service = service
    }

    func authenticate() async {
        state = .authenticating
        do {
            try await service.authenticate()
            state = .authenticated
        } catch let error as BiometricError {
            switch error {
            case .cancelled:
                state = .idle
            default:
                state = .failed(error.localizedDescription ?? "Error desconocido")
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
