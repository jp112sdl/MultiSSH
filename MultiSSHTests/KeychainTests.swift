import XCTest
@testable import MultiSSH

final class KeychainTests: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        // Cleanup any test passwords
        KeychainHelper.shared.deletePassword(account: "testuser@testhost:22")
        KeychainHelper.shared.deletePassword(account: "testuser@example.com:22")
    }
    
    func testSaveAndRetrievePassword() throws {
        let account = "testuser@testhost:22"
        let password = "testPassword123"
        
        // Save password
        let saveSuccess = KeychainHelper.shared.savePassword(password, account: account)
        XCTAssertTrue(saveSuccess, "Password should be saved successfully")
        
        // Retrieve password
        let retrieved = KeychainHelper.shared.getPassword(account: account)
        XCTAssertEqual(retrieved, password, "Retrieved password should match saved password")
        
        // Cleanup
        KeychainHelper.shared.deletePassword(account: account)
    }
    
    func testUpdatePassword() throws {
        let account = "testuser@testhost:22"
        let password1 = "oldPassword"
        let password2 = "newPassword"
        
        // Save initial password
        KeychainHelper.shared.savePassword(password1, account: account)
        
        // Update password
        let updateSuccess = KeychainHelper.shared.updatePassword(password2, account: account)
        XCTAssertTrue(updateSuccess, "Password should be updated successfully")
        
        // Verify new password
        let retrieved = KeychainHelper.shared.getPassword(account: account)
        XCTAssertEqual(retrieved, password2, "Retrieved password should be the updated one")
        
        // Cleanup
        KeychainHelper.shared.deletePassword(account: account)
    }
    
    func testDeletePassword() throws {
        let account = "testuser@testhost:22"
        let password = "testPassword"
        
        // Save password
        KeychainHelper.shared.savePassword(password, account: account)
        
        // Delete password
        let deleteSuccess = KeychainHelper.shared.deletePassword(account: account)
        XCTAssertTrue(deleteSuccess, "Password should be deleted successfully")
        
        // Verify it's gone
        let retrieved = KeychainHelper.shared.getPassword(account: account)
        XCTAssertNil(retrieved, "Password should not exist after deletion")
    }
    
    func testSSHConnectionPasswordStorage() throws {
        let connection = SSHConnection(
            name: "Test Server",
            host: "example.com",
            port: 22,
            username: "testuser",
            useKeyAuth: false,
            password: "securePassword123"
        )
        
        // Password should be saved to Keychain
        let keychainPassword = KeychainHelper.shared.getPassword(account: "testuser@example.com:22")
        XCTAssertEqual(keychainPassword, "securePassword123", "Password should be stored in Keychain")
        
        // Verify we can retrieve it through the property
        XCTAssertEqual(connection.password, "securePassword123", "Password property should retrieve from Keychain")
        
        // Cleanup
        connection.deletePassword()
    }
    
    func testEmptyPassword() throws {
        let account = "testuser@testhost:22"
        
        // Try to save empty password
        let saveSuccess = KeychainHelper.shared.savePassword("", account: account)
        
        // Retrieve - should return empty string or nil
        let retrieved = KeychainHelper.shared.getPassword(account: account)
        XCTAssertTrue(retrieved == "" || retrieved == nil, "Empty password should be handled")
        
        // Cleanup
        KeychainHelper.shared.deletePassword(account: account)
    }
    
    func testMultiplePasswords() throws {
        let account1 = "user1@host1:22"
        let account2 = "user2@host2:2222"
        let password1 = "password1"
        let password2 = "password2"
        
        // Save multiple passwords
        KeychainHelper.shared.savePassword(password1, account: account1)
        KeychainHelper.shared.savePassword(password2, account: account2)
        
        // Retrieve both
        let retrieved1 = KeychainHelper.shared.getPassword(account: account1)
        let retrieved2 = KeychainHelper.shared.getPassword(account: account2)
        
        XCTAssertEqual(retrieved1, password1, "First password should be correct")
        XCTAssertEqual(retrieved2, password2, "Second password should be correct")
        
        // Cleanup
        KeychainHelper.shared.deletePassword(account: account1)
        KeychainHelper.shared.deletePassword(account: account2)
    }
    
    func testPasswordPersistence() throws {
        let account = "testuser@testhost:22"
        let password = "persistentPassword"
        
        // Save password
        KeychainHelper.shared.savePassword(password, account: account)
        
        // Create a new instance of KeychainHelper (simulate app restart)
        let retrieved = KeychainHelper.shared.getPassword(account: account)
        
        XCTAssertEqual(retrieved, password, "Password should persist across instances")
        
        // Cleanup
        KeychainHelper.shared.deletePassword(account: account)
    }
}

