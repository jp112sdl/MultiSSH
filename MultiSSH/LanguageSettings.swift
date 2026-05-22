import SwiftUI
import Observation

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case german = "de"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .german: return "Deutsch"
        }
    }

    var code: String {
        switch self {
        case .english: return "EN"
        case .german: return "DE"
        }
    }

    var next: AppLanguage {
        switch self {
        case .english: return .german
        case .german: return .english
        }
    }
}

@Observable
class LanguageSettings {
    var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "appLanguage")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        self.current = AppLanguage(rawValue: saved) ?? .english
    }

    func s(_ en: String, _ de: String) -> String {
        current == .english ? en : de
    }

    func toggle() {
        current = current.next
    }
}
