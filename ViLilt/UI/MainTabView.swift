//
//  MainTabView.swift
//  viLilt
//
//  Main Tab Navigation between Voice Call Orb, Chat, Personas, and Settings
//

import SwiftUI
import SwiftData

public struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            VoiceOrbView()
                .tabItem {
                    Label(LocalizedStringKey("Voice Call"), systemImage: "phone.circle.fill")
                }
                .tag(0)
            
            TextChatView()
                .tabItem {
                    Label(LocalizedStringKey("Chat"), systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(1)
            
            PersonaPickerView()
                .tabItem {
                    Label(LocalizedStringKey("Personas"), systemImage: "person.2.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label(LocalizedStringKey("Settings"), systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(LiltTheme.liltViolet)
    }
}
