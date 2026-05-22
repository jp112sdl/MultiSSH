# Connect All / Disconnect All Feature

## Overview

Quickly connect or disconnect all SSH connections within a folder with a single click. Perfect for managing groups of related servers.

## ✨ Features

### In Folder Header
- **Connect All Button** (▶️) - Connect all servers in the folder
- **Disconnect All Button** (⏹) - Disconnect all active sessions in the folder
- **Smart Display** - Buttons only show when relevant:
  - Connect button hidden when all servers are already connected
  - Disconnect button hidden when no servers are connected
  - No buttons shown for empty folders

### In Context Menu
- Right-click folder header for additional options
- "Connect All" - Connect all servers (disabled if all connected)
- "Disconnect All" - Disconnect all servers (disabled if none connected)

## 🎯 Use Cases

### 1. Environment Management
```
📁 Production Servers (5 connections)
  Click ▶️ → All 5 production servers connect at once
  Click ⏹ → All sessions disconnect
```

### 2. Maintenance Windows
```
📁 Database Servers (3 connections)
  Before: Connect each DB server individually
  Now: Single ▶️ click → all DBs connected
```

### 3. Group Operations
```
📁 Web Servers (10 connections)
  Deploy time: ▶️ Connect all
  Run commands via broadcast
  When done: ⏹ Disconnect all
```

### 4. Quick Cleanup
```
Multiple folders with active sessions:
  Production: ⏹ Disconnect all
  Staging: ⏹ Disconnect all
  Development: ⏹ Disconnect all
  → Clean workspace in 3 clicks
```

## 🎨 Visual Indicators

### Button States

**Connect All (▶️ Green)**
- Shows when: At least one server is disconnected
- Hidden when: All servers are already connected
- Tooltip: "Connect all servers in this folder"

**Disconnect All (⏹ Red)**
- Shows when: At least one session is active
- Hidden when: No active sessions
- Tooltip: "Disconnect all sessions in this folder"

**Both Buttons**
- Shows when: Some servers connected, some disconnected
- Action: Connect connects the remaining, Disconnect stops all

**No Buttons**
- Shows when: Folder is empty (no connections)

### Example Scenarios

| Scenario | Connect Button | Disconnect Button |
|----------|---------------|-------------------|
| All disconnected | ✅ Visible | ❌ Hidden |
| All connected | ❌ Hidden | ✅ Visible |
| Some connected | ✅ Visible | ✅ Visible |
| Folder empty | ❌ Hidden | ❌ Hidden |

## 📝 How to Use

### Quick Access (Folder Header)

**Connect All:**
1. Find folder in sidebar
2. Click green ▶️ button in folder header
3. All servers connect automatically

**Disconnect All:**
1. Find folder with active sessions
2. Click red ⏹ button in folder header
3. All sessions disconnect immediately

### Context Menu Access

**Connect All:**
1. Right-click folder header
2. Select "Connect All" (with play icon)
3. All servers connect

**Disconnect All:**
1. Right-click folder header
2. Select "Disconnect All" (with stop icon)
3. All sessions close

### Keyboard Workflow

```
1. Navigate with Tab/Arrow keys
2. Right-click folder
3. Arrow down to "Connect All"
4. Press Return
```

## ⚡ Performance

### Connection Timing
- Servers connect sequentially (not parallel)
- Each connection follows normal authentication flow
- Total time = sum of individual connection times
- Status updates appear in real-time

### Disconnect Timing
- Sessions close immediately
- Clean disconnection (sends exit signal)
- Instant UI update

### Best Practices
- **Small folders** (< 5 servers): Connect all is instant
- **Large folders** (> 10 servers): Consider connecting in batches
- **Mixed auth**: Key-based auth is faster than password auth
- **Network latency**: Slower connections take longer to establish

## 🔒 Security Considerations

### Authentication
- Each server uses its configured authentication method
- Password prompts appear sequentially if needed
- Failed connections don't block others
- SSH key passphrases cached per session

### Connection Safety
- No parallel connection storms (avoids overwhelming networks)
- Each connection independently validated
- Failed connections logged individually
- No automatic retry on failure

### Access Control
- Respects individual connection permissions
- No elevation of privileges
- Each server authenticated separately

## 🎬 Example Workflows

### Morning Routine
```
1. Open MultiSSH
2. Click ▶️ on "Daily Servers" folder
3. All monitoring and admin servers connect
4. Start work immediately
```

### Deployment Workflow
```
1. Click ▶️ on "Web Servers" folder (10 servers)
2. Wait for all to connect
3. Use broadcast to run deployment commands
4. Click ⏹ when done
```

### Troubleshooting Session
```
1. Click ▶️ on "Database Cluster" folder
2. Check status on all nodes simultaneously
3. Run diagnostic commands via broadcast
4. Click ⏹ to clean up
```

### End of Day
```
1. Click ⏹ on "Production" folder
2. Click ⏹ on "Staging" folder
3. Click ⏹ on "Development" folder
4. Clean workspace, no lingering connections
```

## 🛠️ Technical Details

### Implementation
- Iterates through `folder.connections` array
- Calls `manager.connect(connection)` for each
- Skips already-connected servers (for Connect All)
- Skips already-disconnected servers (for Disconnect All)
- UI updates automatically via `@Observable`

### State Management
```swift
// Check if any sessions are connected
hasConnectedSessions(in: folder) -> Bool

// Check if all connections are connected
allConnected(in: folder) -> Bool

// Connect all disconnected servers
connectAll(in: folder)

// Disconnect all connected sessions
disconnectAll(in: folder)
```

### Button Logic
```swift
// Show Disconnect if any sessions active
if hasConnectedSessions(in: folder) {
    // Show red stop button
}

// Show Connect if not all servers connected
if !allConnected(in: folder) {
    // Show green play button
}
```

## 💡 Tips & Tricks

### Organize by Use Case
Create folders based on when you connect to servers:
- "Morning Check" - Servers you check daily
- "Deployment Targets" - Servers for releases
- "Emergency Response" - Critical systems
- "Weekly Maintenance" - Once-a-week servers

### Combine with Broadcast
```
1. Connect All to "Web Servers"
2. Enable "Sync" on all sessions
3. Use broadcast input for commands
4. Disconnect All when done
```

### Staged Connections
For large groups:
```
1. Connect All "Web Tier 1" (10 servers)
2. Wait for connections
3. Connect All "Web Tier 2" (10 servers)
4. Avoids overwhelming network/system
```

### Quick Testing
```
1. Create "Test" folder with 3-5 servers
2. Connect All → verify authentication works
3. Disconnect All → clean slate
4. Repeat as needed
```

## 🐛 Troubleshooting

### Some Servers Don't Connect

**Possible causes:**
- Authentication failed for specific servers
- Network timeout for some hosts
- Incorrect credentials stored
- Firewall blocking certain IPs

**Solution:**
- Connect individually to identify problem servers
- Check connection details (Edit button)
- Verify credentials are current
- Test network connectivity

### Buttons Don't Appear

**Check:**
- Folder has connections (empty folders have no buttons)
- Connections are visible (folder not collapsed)
- UI is updated (try expanding/collapsing folder)

### Disconnect All Doesn't Work

**Check:**
- Sessions are actually connected (green dot)
- Not just "Connecting..." state
- Try individual disconnect first
- Check for hung sessions (reconnect → disconnect)

### Performance Issues

**If Connect All is slow:**
- Normal for many servers or slow networks
- Each connection takes 1-5 seconds typically
- Watch session panel for connection progress
- Consider reducing folder size

## 🔮 Future Enhancements

Potential improvements:
- [ ] Progress indicator during Connect All
- [ ] Parallel connection mode (connect multiple simultaneously)
- [ ] Connect All with timeout option
- [ ] Retry failed connections automatically
- [ ] "Connect All" keyboard shortcut per folder
- [ ] Connection templates (connect only active/production/etc)
- [ ] Scheduled connect/disconnect (time-based)

## 📊 Comparison

### Before This Feature
```
Production Servers (8 connections)
  ├─ prod-web-01     [Connect] ← Click 1
  ├─ prod-web-02     [Connect] ← Click 2  
  ├─ prod-web-03     [Connect] ← Click 3
  ├─ prod-api-01     [Connect] ← Click 4
  ├─ prod-api-02     [Connect] ← Click 5
  ├─ prod-db-01      [Connect] ← Click 6
  ├─ prod-db-02      [Connect] ← Click 7
  └─ prod-cache-01   [Connect] ← Click 8

Total: 8 clicks
```

### After This Feature
```
Production Servers (8 connections) [▶️ Connect All] ← Click 1
  ├─ prod-web-01     ⏳ Connecting...
  ├─ prod-web-02     ⏳ Connecting...
  ├─ prod-web-03     ⏳ Connecting...
  ├─ prod-api-01     ⏳ Connecting...
  ├─ prod-api-02     ⏳ Connecting...
  ├─ prod-db-01      ⏳ Connecting...
  ├─ prod-db-02      ⏳ Connecting...
  └─ prod-cache-01   ⏳ Connecting...

Total: 1 click (87.5% reduction!)
```

## Related Documentation

- `FOLDER_ORGANIZATION_GUIDE.md` - Creating and managing folders
- `QUICK_START_DRAG_DROP.md` - Organizing connections
- `ContentView.swift` - Implementation details

---

**Manage your server groups efficiently!** ⚡
