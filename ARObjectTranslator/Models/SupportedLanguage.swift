import Foundation

enum SupportedLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case ukrainian = "uk"
    case japanese = "ja"
    case korean = "ko"
    case polska = "pl"

    var id: String { rawValue }

    var displayName: String {
        Locale.current.localizedString(forLanguageCode: rawValue)?.capitalized ?? rawValue.uppercased()
    }
}
