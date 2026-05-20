# Folder Organization Feature

## Overview

Organize your SSH connections into folders for better management. Group servers by environment, client, project, or any category that makes sense for your workflow.

## Features

✅ **Unlimited Folders**: Create as many folders as you need
✅ **Color Coding**: Each folder has a customizable color for quick visual identification  
✅ **Drag & Drop**: (Future) Move connections between folders
✅ **Automatic Sorting**: Connections within folders are sorted alphabetically
✅ **Unfoldered Connections**: Connections without a folder appear at the top

## How to Use

### Creating a Folder

1. Click the **+** button in the sidebar
2. Select **"New Folder"**
3. Enter a folder name (e.g., "Production Servers")
4. Choose a color
5. Click **"Create"**

### Adding Connections to Folders

**When creating a new connection:**
1. Click **+** → **"New Connection"**
2. Fill in connection details
3. Select a folder from the **"Organization"** section
4. Click **"Add"**

**For existing connections:**
1. Click the connection to edit it
2. Change the **"Folder"** picker in the "Organization" section
3. Click **"Done"**

### Editing a Folder

**Method 1: Header Button**
- Click the pencil icon next to the folder name in the sidebar

**Method 2: Context Menu**
- Right-click on the folder header
- Select **"Edit Folder"**

You can change:
- Folder name
- Folder color
- View connection count

### Deleting a Folder

1. Right-click on the folder header
2. Select **"Delete Folder"**
3. Confirm deletion

**Note**: Deleting a folder does NOT delete the connections inside it. They will be moved to the "unfoldered" section at the top.

## Folder Colors

Choose from 8 predefined colors:

- 🔵 **Blue** (default) - General purpose
- 🟢 **Green** - Production, live servers
- 🔴 **Red** - Critical, high priority
- 🟡 **Yellow** - Development, staging
- 🟣 **Purple** - Testing, QA
- 🩷 **Pink** - Client-specific
- 🟠 **Orange** - Database servers
- 🔷 **Cyan** - Backup, secondary

Pick colors that make sense for your workflow!

## Organization Examples

### By Environment

```
📁 Production (Green)
  ├─ web-server-01
  ├─ web-server-02
  └─ database-prod

📁 Staging (Yellow)
  ├─ staging-web
  └─ staging-db

📁 Development (Blue)
  └─ dev-server
```

### By Client

```
📁 Acme Corp (Blue)
  ├─ acme-web
  └─ acme-db

📁 Tech Startup (Purple)
  ├─ startup-app
  └─ startup-api

📁 Enterprise Co (Red)
  ├─ ent-prod-1
  └─ ent-prod-2
```

### By Server Type

```
📁 Web Servers (Green)
  ├─ nginx-01
  └─ nginx-02

📁 Databases (Orange)
  ├─ postgres-master
  └─ postgres-replica

📁 Monitoring (Cyan)
  ├─ prometheus
  └─ grafana
```

### By Project

```
📁 Project Alpha (Purple)
  ├─ alpha-frontend
  ├─ alpha-backend
  └─ alpha-cache

📁 Project Beta (Pink)
  ├─ beta-app
  └─ beta-db
```

## Tips & Best Practices

### Naming Conventions

1. **Be Descriptive**: Use clear, meaningful names
2. **Keep it Short**: Folder names should fit in the sidebar
3. **Use Prefixes**: Consider numbering for order (01-Production, 02-Staging)
4. **Consistency**: Stick to a naming pattern across folders

### Color Strategy

1. **Consistency**: Use the same color for the same type across projects
2. **Priority**: Use red for critical/production, yellow for dev/test
3. **Visual Balance**: Don't use too many different colors
4. **Personal Preference**: Choose what works best for your workflow

### Organization Strategy

1. **Start Simple**: Begin with a few obvious folders (Production, Development)
2. **Evolve**: Add more folders as your server list grows
3. **Review Regularly**: Reorganize as your infrastructure changes
4. **Archive**: Consider an "Archived" or "Old" folder for unused connections

## Technical Details

### Data Model

- **ConnectionFolder**: Stored in SwiftData database
- **Relationship**: One-to-many (folder → connections)
- **Delete Behavior**: Nullify (connections remain when folder deleted)
- **Sorting**: Folders sorted by `sortOrder`, connections by name

### Storage Location

Folders are stored in the same SwiftData database as connections:
```
~/Library/Application Support/<BundleID>/default.store
```

### Migration

If you have existing connections (created before folders):
- They will appear in the "unfoldered" section
- Edit each connection to assign it to a folder
- Or leave them unfoldered if you prefer

## Keyboard Shortcuts

Currently, there are no keyboard shortcuts for folder operations, but you can:
- Use Tab to navigate form fields when creating/editing folders
- Use Return to confirm folder creation/editing
- Use Escape to cancel

## Future Enhancements

Potential improvements planned:
- [ ] Drag and drop to move connections between folders
- [ ] Collapsible folders (expand/collapse sections)
- [ ] Folder search/filter
- [ ] Bulk operations (connect all in folder)
- [ ] Folder templates/presets
- [ ] Import/export folder structure
- [ ] Custom color picker (beyond 8 presets)
- [ ] Nested folders (subfolders)
- [ ] Folder icons in addition to colors

## Troubleshooting

### Folder not showing up
- Make sure you clicked "Create" (not cancel)
- Check if it's at the bottom (folders sorted by creation order)

### Connection not appearing in folder
- Verify the folder is selected in the connection's "Organization" section
- Try editing the connection and re-selecting the folder

### Can't delete folder
- Make sure you're right-clicking on the folder header (not a connection)
- Try using the "Edit Folder" dialog and delete from there

### Folder color not changing
- Ensure you selected a different color in the picker
- Click "Done" to save changes

## Database Schema

For developers:

```swift
ConnectionFolder {
    name: String
    colorHex: String  // e.g., "#3B82F6"
    sortOrder: Int
    connections: [SSHConnection]  // one-to-many relationship
}

SSHConnection {
    // ... existing fields ...
    folder: ConnectionFolder?  // optional relationship
}
```

The relationship is bidirectional:
- `ConnectionFolder.connections` (one-to-many)
- `SSHConnection.folder` (many-to-one, optional)

Delete rule: `.nullify` - when a folder is deleted, connections remain but `folder` is set to `nil`.
