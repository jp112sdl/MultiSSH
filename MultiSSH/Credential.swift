import Foundation
import SwiftData

@Model
final class Credential {
    var name: String = "New Credential"
    var username: String = ""
    var useKeyAuth: Bool = true
    var identityFile: String = ""
    var sortOrder: Int = 0
    
    // Store a unique identifier for the password in Keychain
    @Transient private var _password: String = ""
    
    init(name: String = "New Credential", username: String = "",
         useKeyAuth: Bool = true, identityFile: String = "", password: String = "") {
        self.name = name
        self.username = username
        self.useKeyAuth = useKeyAuth
        self.identityFile = identityFile
        self._password = password
        self.sortOrder = Int(Date().timeIntervalSince1970)
    }
    
    /// Computed property for secure password access
    var password: String {
        get {
            // Try to load from Keychain
            if let storedPassword = KeychainHelper.shared.getPassword(account: keychainAccount) {
                return storedPassword
            }
            return _password
        }
        set {
            _password = newValue
            // Save to Keychain
            if !newValue.isEmpty {
                KeychainHelper.shared.savePassword(newValue, account: keychainAccount)
            } else {
                KeychainHelper.shared.deletePassword(account: keychainAccount)
            }
        }
    }
    
    /// Unique identifier for this credential's password in the Keychain
    private var keychainAccount: String {
        return "credential-\(name)-\(username)"
    }
    
    /// Delete password from Keychain when credential is deleted
    func deletePassword() {
        KeychainHelper.shared.deletePassword(account: keychainAccount)
    }
    
    /// Display text for credential
    var displayText: String {
        if useKeyAuth {
            if identityFile.isEmpty {
                return "\(username) (SSH Key/Agent)"
            } else {
                let fileName = (identityFile as NSString).lastPathComponent
                return "\(username) (Key: \(fileName))"
            }
        } else {
            return "\(username) (Password)"
        }
    }
}
