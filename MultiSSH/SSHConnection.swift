import Foundation
import SwiftData

@Model
final class SSHConnection {
    var name: String = "New Connection"
    var host: String = ""
    var port: Int = 22
    var username: String = ""
    var useKeyAuth: Bool = true
    var identityFile: String = ""
    
    // Relationship to folder
    var folder: ConnectionFolder?
    
    // Store a unique identifier for the password in Keychain
    // Password is NOT stored in the database anymore
    @Transient private var _password: String = ""

    init(name: String = "New Connection", host: String = "", port: Int = 22,
         username: String = "", useKeyAuth: Bool = true,
         identityFile: String = "", password: String = "", folder: ConnectionFolder? = nil) {
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.useKeyAuth = useKeyAuth
        self.identityFile = identityFile
        self._password = password
        self.folder = folder
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
    
    /// Unique identifier for this connection's password in the Keychain
    private var keychainAccount: String {
        return "\(username)@\(host):\(port)"
    }
    
    /// Delete password from Keychain when connection is deleted
    func deletePassword() {
        KeychainHelper.shared.deletePassword(account: keychainAccount)
    }
}

