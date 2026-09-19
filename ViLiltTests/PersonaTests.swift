//
//  PersonaTests.swift
//  ViLiltTests
//
//  Unit tests verifying companion personas and system prompt specifications
//

import XCTest
@testable import ViLilt

final class PersonaTests: XCTestCase {
    
    func testPersonaPresetsNonEmpty() {
        XCTAssertFalse(Persona.presets.isEmpty, "Persona presets catalog should not be empty")
        XCTAssertGreaterThanOrEqual(Persona.presets.count, 5, "Should provide at least 5 companion personas")
    }
    
    func testDefaultPersonaValidity() {
        let defaultPersona = Persona.defaultPersona
        XCTAssertEqual(defaultPersona.id, "companion")
        XCTAssertEqual(defaultPersona.name, "Empathetic Friend")
        XCTAssertFalse(defaultPersona.systemPrompt.isEmpty)
        XCTAssertFalse(defaultPersona.icon.isEmpty)
    }
    
    func testUniquePersonaIDs() {
        let ids = Persona.presets.map { $0.id }
        let uniqueIDs = Set(ids)
        XCTAssertEqual(ids.count, uniqueIDs.count, "Each persona must have a unique identifier")
    }
    
    func testPersonaSystemPromptsContainViLiltTone() {
        for persona in Persona.presets {
            XCTAssertFalse(persona.name.isEmpty, "Persona name cannot be empty")
            XCTAssertFalse(persona.title.isEmpty, "Persona title cannot be empty")
            XCTAssertFalse(persona.promptDescription.isEmpty, "Persona description cannot be empty")
            XCTAssertTrue(persona.systemPrompt.contains("viLilt"), "System prompt for \(persona.name) must reference viLilt persona identity")
        }
    }
}
