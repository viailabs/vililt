//
//  LanguageManager.swift
//  viLilt
//
//  Centralized coordinator for app language and multi-lingual voice mapping
//

import Foundation
import SwiftUI

@Observable
public final class LanguageManager: @unchecked Sendable {
    public static let shared = LanguageManager()
    
    public struct LanguageOption: Identifiable, Hashable, Sendable {
        public let id: String
        public let displayName: String
        public let localizedName: String
        
        public init(id: String, displayName: String, localizedName: String) {
            self.id = id
            self.displayName = displayName
            self.localizedName = localizedName
        }
    }
    
    public static let availableLanguages: [LanguageOption] = [
        LanguageOption(id: "system", displayName: "🌐 Follow System (跟随系统)", localizedName: "System Default"),
        LanguageOption(id: "en", displayName: "🇺🇸 English", localizedName: "English"),
        LanguageOption(id: "zh-Hans", displayName: "🇨🇳 简体中文", localizedName: "简体中文"),
        LanguageOption(id: "zh-Hant", displayName: "🇭🇰/🇹🇼 繁體中文", localizedName: "繁體中文"),
        LanguageOption(id: "es", displayName: "🇪🇸 Español", localizedName: "Español"),
        LanguageOption(id: "fr", displayName: "🇫🇷 Français", localizedName: "Français"),
        LanguageOption(id: "de", displayName: "🇩🇪 Deutsch", localizedName: "Deutsch"),
        LanguageOption(id: "ja", displayName: "🇯🇵 日本語", localizedName: "日本語"),
        LanguageOption(id: "ko", displayName: "🇰🇷 한국어", localizedName: "한국어"),
        LanguageOption(id: "vi", displayName: "🇻🇳 Tiếng Việt", localizedName: "Tiếng Việt"),
        LanguageOption(id: "it", displayName: "🇮🇹 Italiano", localizedName: "Italiano"),
        LanguageOption(id: "pt", displayName: "🇧🇷/🇵🇹 Português", localizedName: "Português")
    ]
    
    private let userDefaultsKey = "viLilt_selected_language"
    
    public var currentLanguage: String {
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
        currentLanguage = langId
    }
}
