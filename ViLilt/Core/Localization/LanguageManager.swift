//
//  LanguageManager.swift
//  viLilt
//
//  Centralized coordinator for app language and multi-lingual voice mapping
//

import Foundation
import SwiftUI
import Combine

public final class LanguageManager: ObservableObject, @unchecked Sendable {
    public static let shared = LanguageManager()
    
    public struct LanguageOption: Identifiable, Hashable, Sendable {
        public let id: String
        public let displayName: String
        public let fallbackLocalizedName: String
        
        public init(id: String, displayName: String, fallbackLocalizedName: String) {
            self.id = id
            self.displayName = displayName
            self.fallbackLocalizedName = fallbackLocalizedName
        }
        
        public func localizedName(in locale: Locale) -> String {
            if id == "system" {
                return String(localized: "Follow System", locale: locale)
            }
            if let native = locale.localizedString(forIdentifier: id) {
                return native.capitalized(with: locale)
            }
            return fallbackLocalizedName
        }
    }
    
    public static let availableLanguages: [LanguageOption] = [
        LanguageOption(id: "system", displayName: "🌐 Follow System", fallbackLocalizedName: "System Default"),
        LanguageOption(id: "en", displayName: "🇺🇸 English", fallbackLocalizedName: "English"),
        LanguageOption(id: "zh-Hans", displayName: "🇨🇳 简体中文", fallbackLocalizedName: "简体中文"),
        LanguageOption(id: "zh-Hant", displayName: "🇭🇰/🇹🇼 繁體中文", fallbackLocalizedName: "繁體中文"),
        LanguageOption(id: "es", displayName: "🇪🇸 Español", fallbackLocalizedName: "Español"),
        LanguageOption(id: "fr", displayName: "🇫🇷 Français", fallbackLocalizedName: "Français"),
        LanguageOption(id: "de", displayName: "🇩🇪 Deutsch", fallbackLocalizedName: "Deutsch"),
        LanguageOption(id: "ja", displayName: "🇯🇵 日本語", fallbackLocalizedName: "日本語"),
        LanguageOption(id: "ko", displayName: "🇰🇷 한국어", fallbackLocalizedName: "한국어"),
        LanguageOption(id: "vi", displayName: "🇻🇳 Tiếng Việt", fallbackLocalizedName: "Tiếng Việt"),
        LanguageOption(id: "it", displayName: "🇮🇹 Italiano", fallbackLocalizedName: "Italiano"),
        LanguageOption(id: "pt", displayName: "🇧🇷/🇵🇹 Português", fallbackLocalizedName: "Português")
    ]
    
    private let userDefaultsKey = "viLilt_selected_language"
    
    @Published public var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: userDefaultsKey)
            if currentLanguage == "system" {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            }
            UserDefaults.standard.synchronize()
            SpeechRecognitionEngine.shared.updateSpeechRecognizer()
            NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: currentLanguage)
        }
    }
    
    private init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: userDefaultsKey) ?? "system"
    }
    
    public var effectiveLanguage: String {
        if currentLanguage == "system" {
            return Self.detectSystemLanguage()
        }
        return currentLanguage
    }
    
    public var locale: Locale {
        Locale(identifier: effectiveLanguage)
    }
    
    public static func detectSystemLanguage() -> String {
        let preferred = Locale.preferredLanguages
        for lang in preferred {
            let lower = lang.lowercased()
            if lower.contains("hans") || lower.contains("cn") {
                return "zh-Hans"
            }
            if lower.contains("hant") || lower.contains("tw") || lower.contains("hk") {
                return "zh-Hant"
            }
            if lower.hasPrefix("zh") {
                return "zh-Hans"
            }
            if lower.hasPrefix("es") {
                return "es"
            }
            if lower.hasPrefix("fr") {
                return "fr"
            }
            if lower.hasPrefix("de") {
                return "de"
            }
            if lower.hasPrefix("ja") {
                return "ja"
            }
            if lower.hasPrefix("ko") {
                return "ko"
            }
            if lower.hasPrefix("vi") {
                return "vi"
            }
            if lower.hasPrefix("it") {
                return "it"
            }
            if lower.hasPrefix("pt") {
                return "pt"
            }
            if lower.hasPrefix("en") {
                return "en"
            }
        }
        return "en"
    }
    
    public func setLanguage(_ langId: String) {
        objectWillChange.send()
        currentLanguage = langId
    }
    
    public func localize(_ key: String) -> String {
        let loc = locale
        return String(localized: String.LocalizationValue(key), locale: loc)
    }
}
