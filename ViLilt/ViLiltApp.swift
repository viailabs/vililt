//
//  ViLiltApp.swift
//  viLilt
//
//  Application entry point with SwiftData model container and splash coordinator
//

import SwiftUI
import SwiftData

@main
struct ViLiltApp: App {
    @StateObject private var languageManager = LanguageManager.shared
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding: Bool = false
    @State private var hasCompletedSplash: Bool = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ConversationThread.self,
            ChatMessage.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !hasCompletedOnboarding {
                    OnboardingView(isPresented: Binding(
                        get: { !hasCompletedOnboarding },
                        set: { if !$0 { hasCompletedOnboarding = true } }
                    ))
                    .transition(.opacity)
                } else if !hasCompletedSplash {
                    AppStartupSplashView(isCompleted: $hasCompletedSplash)
                        .transition(.opacity)
                } else {
                    MainTabView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.35), value: hasCompletedSplash)
            .environment(\.locale, languageManager.locale)
            .environmentObject(languageManager)
            .id(languageManager.effectiveLanguage)
        }
        .modelContainer(sharedModelContainer)
    }
}
