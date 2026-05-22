# Connect All/Disconnect All Buttons - Now Visible!

## ✅ Issue Fixed

The Connect All/Disconnect All buttons were missing from the folder headers. They've now been added!

## 📍 What Was Added

### Folder Header Buttons

Between the folder name and the edit (pencil) button, you'll now see:

**When folder has connections:**
- **🟢 ▶️ (Play Icon)** - Connect All button
  - Shows when: At least one server is disconnected
  - Color: Green
  - Tooltip: "Connect all servers in this folder"
  
- **🔴 ⏹ (Stop Icon)** - Disconnect All button
  - Shows when: At least one session is active  
  - Color: Red
  - Tooltip: "Disconnect all sessions in this folder"

**Smart Display:**
- If all servers are connected → Only Disconnect button shows
- If all servers are disconnected → Only Connect button shows
- If mixed (some connected) → Both buttons show
- If folder is empty → No buttons show

### Context Menu Options

Right-click on folder header to see:
- "Connect All" (with play icon) - Disabled if all already connected
- "Disconnect All" (with stop icon) - Disabled if none connected
- Divider
- "Edit Folder"
- Divider  
- "Delete Folder"

## 🎨 Visual Layout

```
[▽] 🔵 Production Servers  [⏹] [▶️] [✏️]
 ^   ^         ^             ^    ^    ^
 |   |         |             |    |    └─ Edit button
 |   |         |             |    └────── Connect All (green)
 |   |         |             └─────────── Disconnect All (red)
 |   |         └───────────────────────── Folder name
 |   └─────────────────────────────────── Folder color
 └─────────────────────────────────────── Collapse/Expand
```

## 💡 How to Use

### Connect All Servers
1. Find a folder with disconnected servers
2. Look for the green ▶️ button in the folder header
3. Click it
4. All servers in that folder will start connecting

### Disconnect All Sessions
1. Find a folder with active sessions (connected servers)
2. Look for the red ⏹ button in the folder header
3. Click it
4. All active sessions in that folder will disconnect

### Alternative: Context Menu
1. Right-click anywhere on the folder header
2. Select "Connect All" or "Disconnect All"
3. Same result as clicking the buttons

## 🧪 Test It Out

1. **Create a folder** with multiple connections
2. **Connect one server** manually
3. **Look at the folder header** - you should see both ▶️ and ⏹ buttons
4. **Click ▶️** - remaining servers connect
5. **Click ⏹** - all sessions disconnect

## ✅ Build and Run

The app should build successfully and the buttons should now be visible in each folder header!

---

**The buttons are now there!** 🎉
