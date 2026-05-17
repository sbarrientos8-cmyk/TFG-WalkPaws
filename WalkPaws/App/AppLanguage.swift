//
//  AppLanguage.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 28/3/26.
//

import Foundation

enum AppLanguage: String {
    case es
    case en

    static let userDefaultsKey = "app_language"

    static var current: AppLanguage {
        // 1) Si el usuario ya eligió idioma en la app, usar ese
        if let raw = UserDefaults.standard.string(forKey: userDefaultsKey),
           let lang = AppLanguage(rawValue: raw) {
            return lang
        }

        // 2) Si no hay preferencia guardada, mirar idioma del móvil
        let preferredLanguages = Locale.preferredLanguages
        let firstLanguageCode = preferredLanguages.first?
            .prefix(2)
            .lowercased()

        switch firstLanguageCode {
        case "en":
            return .en
        case "es":
            return .es
        default:
            return .es
        }
    }

    static func set(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: userDefaultsKey)
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }

    var localeIdentifier: String {
        switch self {
        case .es: return "es"
        case .en: return "en"
        }
    }
}

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

enum L10n {
    static func tr(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: AppLanguage.current.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }

        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    static func tr(_ key: String, _ args: CVarArg...) -> String {
        let format = tr(key)
        return String(
            format: format,
            locale: Locale(identifier: AppLanguage.current.localeIdentifier),
            arguments: args
        )
    }
}
