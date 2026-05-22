# Secure Password Storage Migration

## What Changed

Passwords are now stored securely in the **macOS Keychain** instead of in plain text in the SwiftData database.

## Security Benefits

✅ **Encrypted Storage**: Passwords are encrypted by macOS Keychain
✅ **System Integration**: Uses the same secure storage as Safari, Mail, etc.
✅ **Access Control**: Only your app can access these passwords
✅ **Separate from Backups**: Keychain has separate backup/restore policies
✅ **Per-User**: Passwords are tied to your macOS user account

## How It Works

### Before (Insecure):
```
Database File: ~/Library/Application Support/.../default.store
├── Connection Info (name, host, port, username)
└── Password ❌ (stored in plain text!)
```

### After (Secure):
```
Database File: ~/Library/Application Support/.../default.store
└── Connection Info ONLY (name, host, port, username)

Keychain: ~/Library/Keychains/login.keychain-db
└── Passwords 🔒 (encrypted, per connection)
```

## Keychain Storage Format

Each password is stored with:
- **Service**: `MultiSSH` (app identifier)
- **Account**: `username@host:port` (unique per connection)
- **Password**: Your SSH password (encrypted)
- **Accessibility**: `kSecAttrAccessibleWhenUnlocked` (only when Mac is unlocked)

## Viewing Stored Passwords

You can view your stored passwords in **Keychain Access.app**:

1. Open **Keychain Access** (`/Applications/Utilities/Keychain Access.app`)
2. Select **login** keychain
3. Search for **"MultiSSH"**
4. Double-click any entry to view details
5. Check "Show password" (requires your Mac password)

## Migration

### For New Installations:
- Nothing to do! Passwords are automatically stored securely.

### For Existing Users:
If you had passwords saved before this update, they will be migrated automatically:
1. Old passwords in database will still be read (for compatibility)
2. Next time you edit a connection, the password will be moved to Keychain
3. You can force migration by:
   - Opening each connection in "Edit"
   - Re-entering (or confirming) the password
   - Saving

### Manual Migration Script:
```swift
// Run this once to migrate all existing passwords to Keychain
func migratePasswordsToKeychain() {
    // This would need to be added to your app if you have existing users
    // For now, passwords will migrate automatically when connections are edited
}
```

## Important Notes

⚠️ **Password Recovery**: If you lose access to your Mac keychain, saved passwords cannot be recovered. Always keep a secure backup of important credentials.

⚠️ **Multiple Macs**: Keychain passwords don't sync unless you enable iCloud Keychain. If you use the app on multiple Macs, you'll need to re-enter passwords on each one.

✅ **SSH Keys**: If you use SSH key authentication (recommended!), this doesn't affect you at all.

## Best Practices

1. **Use SSH Keys**: For better security, use SSH key authentication instead of passwords
2. **Strong Passwords**: If using password auth, use strong, unique passwords
3. **Enable iCloud Keychain**: (Optional) To sync passwords across your Macs
4. **Regular Backups**: Keep secure backups of your SSH keys and Keychain

## Troubleshooting

### "Password not found" after update:
- The password might still be in the old database format
- Edit the connection and re-enter the password
- It will be saved to Keychain automatically

### "Access denied" errors:
- macOS might prompt you to allow MultiSSH to access Keychain
- Click "Allow" or "Always Allow"
- If you accidentally clicked "Deny", go to Keychain Access → MultiSSH entry → Access Control

### Clearing all passwords:
```bash
# Remove all MultiSSH passwords from Keychain
security delete-generic-password -s "MultiSSH"
```

## Technical Details

The implementation uses macOS Security framework's Keychain Services API:
- `SecItemAdd`: Store new passwords
- `SecItemCopyMatching`: Retrieve passwords
- `SecItemUpdate`: Update existing passwords
- `SecItemDelete`: Remove passwords

Each operation is wrapped in the `KeychainHelper` class for easy access.
