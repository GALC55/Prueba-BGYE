import SwiftUI

struct BiometricView: View {
    @ObservedObject var viewModel: BiometricViewModel
    var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("Banco Guayaquil")
                    .font(.title.bold())
                Text("Verifica tu identidad para continuar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let error = errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                Task { await viewModel.authenticate() }
            } label: {
                HStack {
                    Image(systemName: biometricIcon)
                    Text(buttonLabel)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.state == .authenticating)
            .padding(.horizontal, 32)

            if case .authenticating = viewModel.state {
                ProgressView()
            }

            Spacer()
        }
        .padding()
    }

    private var biometricIcon: String {
        "faceid"
    }

    private var buttonLabel: String {
        errorMessage != nil ? "Reintentar" : "Autenticar"
    }
}
