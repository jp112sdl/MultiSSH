import Foundation
import Security

/// Helper class for securely storing and retrieving passwords in the macOS Keychain
final class KeychainHelper {
    
    static let shared = KeychainHelper()
    
    private init() {}
    
    /// Save a password to the Keychain
    /// - Parameters:
    ///   - password: The password to save
    ///   - account: Unique identifier (e.g., "username@host:port")
    ///   - service: Service name (app identifier)
    /// - Returns: True if successful
    @discardableResult
    func savePassword(_ password: String, account: String, service: String = "MultiSSH") -> Bool {
        guard let passwordData = password.data(using: .utf8) else { return false }
        
        // First, try to delete existing password to avoid duplicates
        deletePassword(account: account, service: service)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            return true
        } else {
            print("❌ Keychain save failed with status: \(status)")
            return false
        }
    }
    
    /// Retrieve a password from the Keychain
    /// - Parameters:
    ///   - account: Unique identifier (e.g., "username@host:port")
    ///   - service: Service name (app identifier)
    /// - Returns: The password if found, nil otherwise
    func getPassword(account: String, service: String = "MultiSSH") -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let passwordData = result as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            if status != errSecItemNotFound {
                print("⚠️ Keychain retrieve failed with status: \(status)")
            }
            return nil
        }
        
        return password
    }
    
    /// Delete a password from the Keychain
    /// - Parameters:
    ///   - account: Unique identifier (e.g., "username@host:port")
    ///   - service: Service name (app identifier)
    /// - Returns: True if successful or item didn't exist
    @discardableResult
    func deletePassword(account: String, service: String = "MultiSSH") -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Update an existing password in the Keychain
    /// - Parameters:
    ///   - password: The new password
    ///   - account: Unique identifier
    ///   - service: Service name
    /// - Returns: True if successful
    @discardableResult
    func updatePassword(_ password: String, account: String, service: String = "MultiSSH") -> Bool {
        guard let passwordData = password.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: passwordData
        ]
        
        let status = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        
        if status == errSecItemNotFound {
            // Password doesn't exist, create it
            return savePassword(password, account: account, service: service)
        }
        
        return status == errSecSuccess
    }
}
