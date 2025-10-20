//
//  SecureStorageTests.swift
//  Indice.Identity
//
//  Created by Nikolas Konstantakopoulos on 14/10/25.
//

import XCTest
import IdentityClient

final class SecureStorageTests: XCTestCase {
    
    func testPurge() async {
        let storage = SecureStorage(service: "test_service")
        let data = "this is a value".data(using: .utf8)!
        
        
        let saveSuccessful = await storage.store(key: "test", data: data)
        
        XCTAssertTrue(saveSuccessful)
        
        let retrievedData: Data? = await  storage.read(key: "test")
        
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(retrievedData, data)
        
        
        let purgeSuccessful = await storage.purgeStorage()
        XCTAssertTrue(purgeSuccessful)
        
        let deletedData = await  storage.read(key: "test")
        XCTAssertNil(deletedData)
    }
    
}
