import SwiftUI

struct RootView: View {
    @StateObject private var authVM = BiometricViewModel()

    var body: some View {
        switch authVM.state {
        case .idle, .authenticating:
            BiometricView(viewModel: authVM)
        case .authenticated:
            MovementsView()
        case .failed(let msg):
            BiometricView(viewModel: authVM, errorMessage: msg)
        }
    }
}
