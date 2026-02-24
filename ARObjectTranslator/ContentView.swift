import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ARTranslationViewModel()

    var body: some View {
        ZStack {
            ARViewContainer(viewModel: viewModel)
                .ignoresSafeArea()

            SelectionOverlay(selectionRect: $viewModel.selectionRect)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                topBar
                Spacer()
                bottomBar
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)

            if viewModel.isBusy {
                ProgressView(viewModel.statusMessage)
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .background(Color(.systemGroupedBackground))
        .alert("Translation", isPresented: $viewModel.showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AR Object Translator")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            HStack {
                Label("Translate to", systemImage: "globe")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Picker("Translate to", selection: $viewModel.selectedTargetLanguage) {
                    ForEach(SupportedLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if !viewModel.detectedLanguageDescription.isEmpty {
                Text(viewModel.detectedLanguageDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task {
                    await viewModel.translateSelection()
                }
            } label: {
                HStack {
                    Image(systemName: "camera.viewfinder")
                    Text("Translate Selection")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(PrimarySoftButtonStyle())
            .disabled(viewModel.isBusy)

            Text("Drag to select text area. Only selected region is scanned.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
    }
}

private struct PrimarySoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: configuration.isPressed
                                ? [Color(red: 0.18, green: 0.47, blue: 0.76), Color(red: 0.22, green: 0.56, blue: 0.85)]
                                : [Color(red: 0.24, green: 0.60, blue: 0.92), Color(red: 0.28, green: 0.72, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
