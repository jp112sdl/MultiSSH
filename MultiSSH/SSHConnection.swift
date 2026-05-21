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
    
    // Relationship to credential (optional - if nil, uses inline credentials)
    var credential: Credential?
    
    // Store a unique identifier for the password in Keychain
    // Password is NOT stored in the database anymore
    @Transient private var _password: String = ""

    init(name: String = "New Connection", host: String = "", port: Int = 22,
         username: String = "", useKeyAuth: Bool = true,
         identityFile: String = "", password: String = "", 
         folder: ConnectionFolder? = nil, credential: Credential? = nil) {
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.useKeyAuth = useKeyAuth
        self.identityFile = identityFile
        self._password = password
        self.folder = folder
        self.credential = credential
    }
    
    /// Computed property for secure password access
    var password: String {
        get {
            // If using a saved credential, return its password
            if let credential = credential {
                return credential.password
            }
            // Otherwise, try to load from Keychain
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
    
    /// Get the effective username (from credential or inline)
    var effectiveUsername: String {
        return credential?.username ?? username
    }
    
    /// Get the effective auth method (from credential or inline)
    var effectiveUseKeyAuth: Bool {
        return credential?.useKeyAuth ?? useKeyAuth
    }
    
    /// Get the effective identity file (from credential or inline)
    var effectiveIdentityFile: String {
        return credential?.identityFile ?? identityFile
    }
    
    /// Get the effective password (from credential or inline)
    var effectivePassword: String {
        return credential?.password ?? password
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

