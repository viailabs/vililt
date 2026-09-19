//
//  PersonaPickerView.swift
//  viLilt
//
//  Visual card selector for companion personalities and conversational tones
//

import SwiftUI

public struct PersonaPickerView: View {
    @State private var voiceEngine = VoiceConversationEngine.shared
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Persona.presets) { persona in
                        personaCard(persona)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .navigationTitle(String(localized: "Personas & Tones"))
        }
    }
    
    @ViewBuilder
    private func personaCard(_ persona: Persona) -> some View {
        let isSelected = voiceEngine.activePersona.id == persona.id
        
        Button {
            voiceEngine.activePersona = persona
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: persona.icon)
                    .font(.title2.weight(.bold))
                    .foregroundColor(isSelected ? LiltTheme.pureWhite : LiltTheme.liltViolet)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? LiltTheme.liltGradient : LinearGradient(colors: [Color(.tertiarySystemFill)], startPoint: .top, endPoint: .bottom))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(LocalizedStringKey(persona.name))
                            .font(.headline.weight(.bold))
                            .foregroundColor(LiltTheme.primaryText)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(LiltTheme.liltCyan)
                                .font(.title3)
                        }
                    }
                    
                    Text(LocalizedStringKey(persona.title))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(LiltTheme.liltViolet)
                    
                    Text(LocalizedStringKey(persona.promptDescription))
                        .font(.caption)
                        .foregroundColor(LiltTheme.secondaryText)
                        .padding(.top, 2)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? LiltTheme.liltViolet : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
