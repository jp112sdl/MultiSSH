# Drag and Drop Implementation

## Summary

Implemented drag and drop functionality to move SSH connections between folders in the MultiSSH app. Users can now drag connections from one location and drop them into folders or back to the unfoldered section.

## Changes Made

### 1. ContentView.swift

#### Added State Variables
- `@State private var dropTargetFolder: ConnectionFolder?` - Tracks which folder is currently being targeted for drop
- `@State private var isDropTargetingUnfoldered: Bool` - Tracks if the unfoldered section is being targeted

#### Added Helper Function: `handleDrop(providers:targetFolder:)`
```swift
private func handleDrop(providers: [NSItemProvider], targetFolder: ConnectionFolder?) -> Bool
```

This function:
- Extracts the connection's persistent identifier from the dragged item
- Finds the matching connection in the database
- Updates the connection's `folder` property
- Saves changes to the model context
- Returns `true` to indicate successful drop

#### Modified ConnectionRowView
Added `.onDrag` modifier to make connections draggable:
```swift
.onDrag {
    let itemProvider = NSItemProvider()
    itemProvider.registerDataRepresentation(forTypeIdentifier: "com.multissh.connection", visibility: .all) { completion in
        let data = connection.id.uriRepresentation().absoluteString.data(using: .utf8) ?? Data()
        completion(data, nil)
        return nil
    }
    return itemProvider
}
```

#### Modified Unfoldered Section
- Added `.onDrop` modifier to accept dropped connections
- Added `.listRowBackground` modifier to highlight when targeted
- Added drop zone text when no unfoldered connections exist
- Uses custom UTI: `"com.multissh.connection"`

#### Modified Folder Sections
- Added `.onDrop` modifier to each folder section
- Added visual feedback with background highlighting on folder headers
- Binds drop targeting state to highlight the appropriate folder

## Features

### For Users

✅ **Drag connections** - Click and hold any connection to drag it
✅ **Drop into folders** - Drop connections onto folder headers to organize them
✅ **Remove from folders** - Drop connections on the unfoldered section to remove them from folders
✅ **Visual feedback** - Folders highlight when you drag over them
✅ **Automatic save** - Changes persist immediately to SwiftData

### Visual Indicators

- **Blue highlight** on folder headers when dragging over them
- **Blue highlight** on unfoldered section when dragging over it
- **Drop zone text** appears when no unfoldered connections exist

## Technical Details

### Custom UTI
Using custom Uniform Type Identifier: `"com.multissh.connection"`
- Ensures only connection items can be dropped
- Prevents dropping unrelated content

### Data Transfer
Connections are transferred using their SwiftData `PersistentIdentifier`:
- Converted to URI representation string
- Encoded as UTF-8 data
- Transferred via `NSItemProvider`
- Decoded and matched on drop

### Async Handling
Drop handling uses `Task { @MainActor in }` to ensure UI updates happen on the main thread:
```swift
Task { @MainActor in
    connection.folder = targetFolder
    try? modelContext.save()
}
```

## User Experience

### Common Use Cases

1. **Organizing new connections**: Drag newly added connections into appropriate folders
2. **Reorganizing structure**: Move connections between folders as your infrastructure changes
3. **Removing from folders**: Drag connections back to unfoldered section
4. **Quick triage**: Quickly sort connections without opening edit dialogs

### Workflow Benefits

- **Faster than editing**: No need to open connection edit dialog
- **Visual organization**: See where connections will land before dropping
- **Intuitive**: Follows standard drag-and-drop conventions from macOS
- **Forgiving**: If you drop in the wrong place, just drag again

## Testing Checklist

When testing this feature:

- [ ] Drag connection from unfoldered section to a folder
- [ ] Drag connection between two different folders
- [ ] Drag connection from folder back to unfoldered section
- [ ] Verify visual highlighting appears when dragging over targets
- [ ] Confirm connection persists in new location after app restart
- [ ] Test with collapsed folders
- [ ] Test with many connections (performance)
- [ ] Verify drop zone appears when no unfoldered connections exist

## Future Enhancements

Potential improvements:
- **Multi-select drag**: Drag multiple connections at once
- **Drag to reorder**: Change connection order within a folder
- **Drag folders**: Reorder folders by dragging their headers
- **Drop preview**: Show ghost image of connection being dragged
- **Undo support**: Add undo/redo for drag operations
- **Keyboard modifiers**: Hold Option to copy instead of move

## Documentation Updates

Updated `FOLDER_ORGANIZATION_GUIDE.md`:
- Marked "Drag & Drop" feature as implemented (✅)
- Added new section "Using Drag and Drop" with detailed instructions
- Updated "Adding Connections to Folders" section with drag-and-drop method
- Marked feature as complete in "Future Enhancements" section

## Code Quality

- **SwiftUI native**: Uses SwiftUI's built-in drag and drop APIs
- **Type-safe**: Uses SwiftData's `PersistentIdentifier` for safe references
- **Error handling**: Gracefully handles missing connections or invalid data
- **Memory efficient**: Transfers only identifiers, not entire objects
- **Thread-safe**: Uses @MainActor for UI updates

## Compatibility

- **macOS**: Primary target, uses AppKit's `NSItemProvider`
- **SwiftUI**: Uses standard SwiftUI modifiers (`.onDrag`, `.onDrop`)
- **SwiftData**: Leverages persistent identifiers for safe references

## Notes

- The implementation does NOT prevent dragging a connection onto itself (harmless)
- Dropping outside valid targets does nothing (connection stays in place)
- No animation for the actual move (instant update)
- Drop zones use accent color for consistency with app theme
