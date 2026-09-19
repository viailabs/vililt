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
                MainTabView()
                
                if !hasCompletedSplash {
                    AppStartupSplashView(isCompleted: $hasCompletedSplash)
                        .transition(.opacity)
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
