# Credential Manager Implementation

## Overview

A comprehensive credential management system has been implemented to allow users to save and reuse authentication credentials across multiple SSH connections. This eliminates the need to re-enter the same username, password, or SSH key information for multiple servers.

## Key Features

### 1. Credential Model (`Credential.swift`)
- **Name**: Descriptive name for the credential set
- **Username**: SSH username
- **Authentication Method**: SSH Key/Agent or Password
- **Identity File**: Path to private key (optional)
- **Password**: Stored securely in macOS Keychain
- **Display Text**: Shows credential info in a user-friendly format

### 2. Credential Manager UI (`CredentialManagerView.swift`)
- **Credential List**: View all saved credentials
- **Add Credential**: Create new reusable credentials
- **Edit Credential**: Modify existing credentials
- **Delete Credential**: Remove credentials (with keychain cleanup)
- **Visual Indicators**: Key icon and formatted display text

### 3. Integration with Connections

#### Updated SSHConnection Model
- Added `credential: Credential?` relationship
- Added computed properties for effective credentials:
  - `effectiveUsername`
  - `effectiveUseKeyAuth`
  - `effectiveIdentityFile`
  - `effectivePassword`

#### Connection Forms
Both Add and Edit connection views now include:
- **Toggle**: "Use Saved Credential"
- **Picker**: Select from available credentials
- **Fallback**: Create credentials in Credential Manager if none exist
- **Inline Mode**: Use connection-specific credentials when toggle is off

### 4. Visual Enhancements

#### Connection Row Display
- Shows credential name with key icon when using saved credential
- Shows traditional `username@host:port` when using inline credentials
- Visual distinction helps identify credential usage at a glance

#### Toolbar Access
- Key icon button in sidebar toolbar
- Menu item under the plus (+) menu
- Easy access to credential management

## Usage Workflow

### Creating a Credential
1. Click the key icon in the toolbar (or Plus > Manage Credentials)
2. Click "Add Credential" in the Credential Manager
3. Enter:
   - Name (e.g., "Production Servers")
   - Username
   - Choose authentication method (SSH Key or Password)
   - Enter password or select identity file
4. Click "Add"

### Using a Credential in a Connection
1. Create or edit a connection
2. Toggle "Use Saved Credential" on
3. Select a credential from the dropdown
4. Only need to specify:
   - Connection name
   - Hostname
   - Port
   - Folder (optional)

### Editing Credentials
1. Open Credential Manager
2. Click "Edit" on any credential
3. Modify details (username, auth method, etc.)
4. Changes apply to all connections using this credential

## Security

### Keychain Integration
- Passwords are never stored in SwiftData database
- All sensitive data stored in macOS Keychain
- Secure account identifier: `credential-{name}-{username}`
- Automatic cleanup when credentials are deleted

### Effective Credentials
The system uses a fallback mechanism:
1. If connection has a credential, use credential's values
2. Otherwise, use connection's inline values
3. SSH session always uses effective credentials

## Benefits

### For Users
- **Time Saving**: Enter credentials once, use everywhere
- **Consistency**: Same credentials across multiple servers
- **Organization**: Group similar servers with shared credentials
- **Flexibility**: Mix saved and inline credentials as needed

### For Development Teams
- **Easy Updates**: Change credentials in one place
- **Bulk Management**: Update authentication for multiple servers
- **Credential Sharing**: Export/import credential sets (future enhancement)

## Database Schema

### Updated Models
```swift
// Credential model
@Model
final class Credential {
    var name: String
    var username: String
    var useKeyAuth: Bool
    var identityFile: String
    var sortOrder: Int
    // password stored in Keychain
}

// SSHConnection model (updated)
@Model
final class SSHConnection {
    // ... existing fields ...
    var credential: Credential? // NEW
}
```

### Model Container
Updated to include `Credential.self` in schema:
```swift
let schema = Schema([
    SSHConnection.self,
    ConnectionFolder.self,
    Credential.self  // NEW
])
```

## UI Components

### New Views
1. **CredentialManagerView**: Main management interface
2. **CredentialRowView**: Individual credential display
3. **AddCredentialView**: Create new credentials
4. **EditCredentialView**: Modify existing credentials

### Updated Views
1. **AddConnectionView**: Added credential selection
2. **EditConnectionView**: Added credential selection
3. **ConnectionRowView**: Shows credential indicator
4. **ContentView**: Added credential manager access

## Future Enhancements

Possible improvements for future versions:
- Credential groups/categories
- Import/export credentials
- Credential templates
- SSH config file import
- Credential usage statistics
- Unused credential detection
- Credential validation/testing
- Multiple identity file support
- Custom SSH options per credential
