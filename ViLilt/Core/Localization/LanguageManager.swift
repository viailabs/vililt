//
//  LanguageManager.swift
//  viLilt
//
//  Centralized coordinator for app language and multi-lingual voice mapping
//

import Foundation
import SwiftUI

@Observable
public final class LanguageManager {
    public static let shared = LanguageManager()
    
    public struct LanguageOption: Identifiable, Hashable {
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
        LanguageOption(id: "system", displayName: "System Default (跟随系统)", localizedName: "System Default"),
        LanguageOption(id: "en", displayName: "English", localizedName: "English"),
        LanguageOption(id: "zh-Hans", displayName: "简体中文 (Simplified Chinese)", localizedName: "简体中文"),
        LanguageOption(id: "zh-Hant", displayName: "繁體中文 (Traditional Chinese)", localizedName: "繁體中文"),
        LanguageOption(id: "ja", displayName: "日本語 (Japanese)", localizedName: "日本語"),
        LanguageOption(id: "ko", displayName: "한국어 (Korean)", localizedName: "한국어"),
        LanguageOption(id: "es", displayName: "Español (Spanish)", localizedName: "Español"),
        LanguageOption(id: "fr", displayName: "Français (French)", localizedName: "Français"),
        LanguageOption(id: "de", displayName: "Deutsch (German)", localizedName: "Deutsch"),
        LanguageOption(id: "it", displayName: "Italiano (Italian)", localizedName: "Italiano"),
        LanguageOption(id: "pt", displayName: "Português (Portuguese)", localizedName: "Português"),
        LanguageOption(id: "ru", displayName: "Русский (Russian)", localizedName: "Русский"),
        LanguageOption(id: "ar", displayName: "العربية (Arabic)", localizedName: "العربية"),
        LanguageOption(id: "hi", displayName: "हिन्दी (Hindi)", localizedName: "हिन्दी")
    ]
    
    private let userDefaultsKey = "viLilt_selected_language"
    
    public var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: userDefaultsKey)
            NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
        }
    }
    
    private init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: userDefaultsKey) ?? "system"
    }
    
    public var effectiveLanguage: String {
        if currentLanguage == "system" {
            return Locale.preferredLanguages.first ?? "en"
        }
        return currentLanguage
    }
    
    public func setLanguage(_ langId: String) {
        currentLanguage = langId
    }
}
