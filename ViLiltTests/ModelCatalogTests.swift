//
//  ModelCatalogTests.swift
//  ViLiltTests
//
//  Unit tests verifying on-device LLM model specifications and memory requirements
//

import XCTest
@testable import ViLilt

final class ModelCatalogTests: XCTestCase {
    
    func testAvailableModelsNotEmpty() {
        XCTAssertFalse(ModelCatalog.availableModels.isEmpty, "Model catalog must contain available models")
    }
    
    func testDefaultModelExists() {
        let defaultModel = ModelCatalog.defaultModel
        XCTAssertTrue(defaultModel.isDefault, "Default model must have isDefault = true")
        XCTAssertEqual(defaultModel.id, "qwen2.5-0.5b-instruct-q4_k_m")
        XCTAssertNotNil(defaultModel.downloadURL, "Default model must have valid download URL")
    }
    
    func testModelDownloadURLsAndConstraints() {
        for model in ModelCatalog.availableModels {
            XCTAssertFalse(model.id.isEmpty)
            XCTAssertFalse(model.displayName.isEmpty)
            XCTAssertGreaterThan(model.downloadSizeMB, 0, "Model download size must be positive")
            XCTAssertGreaterThan(model.memoryRequirementMB, 0, "Model RAM requirement must be positive")
            XCTAssertNotNil(model.downloadURL, "Model \(model.id) must have a valid download URL")
        }
    }
    
    func testUniqueModelIDs() {
        let ids = ModelCatalog.availableModels.map { $0.id }
        let uniqueIDs = Set(ids)
        XCTAssertEqual(ids.count, uniqueIDs.count, "Each model in catalog must have a unique identifier")
    }
}
