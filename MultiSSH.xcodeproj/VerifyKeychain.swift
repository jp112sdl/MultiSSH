import Foundation

/// Quick verification that Keychain integration is working
/// This is NOT a test file - just a helper function you can call to verify things work
struct KeychainVerification {
    
    /// Run a quick check to verify Keychain operations work correctly
    /// Call this from your app's launch or a debug menu
    static func verify() {
        print("\n🔐 Keychain Verification Starting...")
        
        let testAccount = "test@verification:22"
        let testPassword = "testPassword123"
        
        // Test 1: Save
        print("1️⃣ Testing save...")
        let saveSuccess = KeychainHelper.shared.savePassword(testPassword, account: testAccount)
        print(saveSuccess ? "   ✅ Save succeeded" : "   ❌ Save failed")
        
        // Test 2: Retrieve
        print("2️⃣ Testing retrieve...")
        if let retrieved = KeychainHelper.shared.getPassword(account: testAccount) {
            let matches = retrieved == testPassword
            print(matches ? "   ✅ Retrieved correct password" : "   ❌ Password mismatch")
        } else {
            print("   ❌ Could not retrieve password")
        }
        
        // Test 3: Update
        print("3️⃣ Testing update...")
        let newPassword = "updatedPassword456"
        let updateSuccess = KeychainHelper.shared.updatePassword(newPassword, account: testAccount)
        print(updateSuccess ? "   ✅ Update succeeded" : "   ❌ Update failed")
        
        if let updated = KeychainHelper.shared.getPassword(account: testAccount) {
            let matches = updated == newPassword
            print(matches ? "   ✅ Retrieved updated password" : "   ❌ Updated password mismatch")
        }
        
        // Test 4: Delete
        print("4️⃣ Testing delete...")
        let deleteSuccess = KeychainHelper.shared.deletePassword(account: testAccount)
        print(deleteSuccess ? "   ✅ Delete succeeded" : "   ❌ Delete failed")
        
        let shouldBeNil = KeychainHelper.shared.getPassword(account: testAccount)
        print(shouldBeNil == nil ? "   ✅ Password properly deleted" : "   ❌ Password still exists")
        
        print("\n🔐 Keychain Verification Complete!\n")
    }
    
    /// Test SSHConnection integration with Keychain
    static func verifySSHConnectionIntegration() {
        print("\n🔐 Testing SSHConnection Keychain Integration...")
        
        let connection = SSHConnection(
            name: "Test Server",
            host: "test.example.com",
            port: 2222,
            username: "testuser",
            useKeyAuth: false,
            password: "mySecretPassword"
        )
        
        print("1️⃣ Created connection with password")
        
        // Check if password was saved to Keychain
        let keychainAccount = "testuser@test.example.com:2222"
        if let savedPassword = KeychainHelper.shared.getPassword(account: keychainAccount) {
            print("   ✅ Password saved to Keychain: '\(savedPassword)'")
        } else {
            print("   ❌ Password NOT found in Keychain")
        }
        
        // Verify we can retrieve through the property
        print("2️⃣ Testing password property getter...")
        let retrievedPassword = connection.password
        print(retrievedPassword == "mySecretPassword" ? "   ✅ Password retrieved correctly" : "   ❌ Password mismatch")
        
        // Update password
        print("3️⃣ Testing password update...")
        connection.password = "newPassword123"
        
        if let updated = KeychainHelper.shared.getPassword(account: keychainAccount) {
            print(updated == "newPassword123" ? "   ✅ Password updated in Keychain" : "   ❌ Password not updated")
        }
        
        // Cleanup
        print("4️⃣ Cleanup...")
        connection.deletePassword()
        let cleaned = KeychainHelper.shared.getPassword(account: keychainAccount)
        print(cleaned == nil ? "   ✅ Cleanup successful" : "   ❌ Cleanup failed")
        
        print("\n🔐 SSHConnection Integration Test Complete!\n")
    }
}
