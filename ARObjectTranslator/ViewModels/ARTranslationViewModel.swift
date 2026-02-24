import SwiftUI

@MainActor
final class ARTranslationViewModel: ObservableObject {
    @Published var selectionRect: CGRect = CGRect(x: 60, y: 180, width: 250, height: 140)
    @Published var selectedTargetLanguage: SupportedLanguage = .english
    @Published var isBusy = false
    @Published var statusMessage = "Processing..."
    @Published var alertMessage = ""
    @Published var showingAlert = false
    @Published var detectedLanguageDescription = ""

    weak var snapshotProvider: ARSnapshotProviding?

    private let ocrService: TextRecognizing
    private let translationService: Translating

    init(
        ocrService: TextRecognizing = TextRecognitionService(),
        translationService: Translating = TranslationService()
    ) {
        self.ocrService = ocrService
        self.translationService = translationService
    }

    func translateSelection() async {
        guard !isBusy else { return }
        guard let snapshotProvider else {
            presentError("Camera session is not ready.")
            return
        }

        isBusy = true
        statusMessage = "Capturing frame..."
        defer { isBusy = false }

        guard let image = await snapshotProvider.captureImage(), let cgImage = image.cgImage else {
            presentError("Failed to capture camera frame.")
            return
        }

        let normalized = normalizedRect(in: image.size)
        guard let cropped = cgImage.cropping(to: normalized.pixelRect(in: cgImage)) else {
            presentError("Could not crop selected area.")
            return
        }

        do {
            statusMessage = "Recognizing text..."
            let recognized = try await ocrService.recognizeText(in: cropped)

            if recognized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw TranslationError.emptyInput
            }

            let sourceCode = translationService.detectLanguage(for: recognized)

            if let sourceCode {
                detectedLanguageDescription = "Detected: \(Locale.current.localizedString(forLanguageCode: sourceCode)?.capitalized ?? sourceCode.uppercased())"
            } else {
                detectedLanguageDescription = "Detected: Unknown"
            }

            statusMessage = "Translating..."
            let translated = try await translationService.translate(recognized, from: sourceCode, to: selectedTargetLanguage.rawValue)
            snapshotProvider.addTranslatedTextAnchor(text: translated, at: selectionRect)
        } catch {
            presentError(error.localizedDescription)
        }
    }

    private func normalizedRect(in imageSize: CGSize) -> CGRect {
        let width = max(imageSize.width, 1)
        let height = max(imageSize.height, 1)

        let x = min(max(selectionRect.origin.x / width, 0), 1)
        let y = min(max(selectionRect.origin.y / height, 0), 1)
        let w = min(max(selectionRect.width / width, 0.05), 1 - x)
        let h = min(max(selectionRect.height / height, 0.05), 1 - y)

        return CGRect(x: x, y: y, width: w, height: h)
    }

    private func presentError(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

private extension CGRect {
    func pixelRect(in cgImage: CGImage) -> CGRect {
        let pixelWidth = CGFloat(cgImage.width)
        let pixelHeight = CGFloat(cgImage.height)

        return CGRect(
            x: origin.x * pixelWidth,
            y: origin.y * pixelHeight,
            width: width * pixelWidth,
            height: height * pixelHeight
        ).integral
    }
}
