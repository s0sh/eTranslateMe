import Foundation
import NaturalLanguage

protocol Translating {
    func detectLanguage(for text: String) -> String?
    func translate(_ text: String, from sourceLanguageCode: String?, to targetLanguageCode: String) async throws -> String
}

enum TranslationError: LocalizedError {
    case unavailable
    case emptyInput
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Translation service is unavailable right now."
        case .emptyInput:
            return "No text found in selected area."
        case .invalidResponse:
            return "Translation returned an invalid response."
        }
    }
}

private struct MyMemoryResponse: Decodable {
    let responseData: ResponseData

    struct ResponseData: Decodable {
        let translatedText: String
    }
}

final class TranslationService: Translating {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func detectLanguage(for text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }

    func translate(_ text: String, from sourceLanguageCode: String?, to targetLanguageCode: String) async throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TranslationError.emptyInput }

        guard var components = URLComponents(string: "https://api.mymemory.translated.net/get") else {
            throw TranslationError.unavailable
        }

        let source = sourceLanguageCode ?? "auto"
        components.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "langpair", value: "\(source)|\(targetLanguageCode)")
        ]

        guard let url = components.url else {
            throw TranslationError.unavailable
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw TranslationError.unavailable
        }

        let decoded = try JSONDecoder().decode(MyMemoryResponse.self, from: data)
        let result = decoded.responseData.translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { throw TranslationError.invalidResponse }

        return result
    }
}
