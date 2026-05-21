# Drag and Drop Implementation - Technical Notes

## Summary

Successfully implemented drag and drop functionality using SwiftUI's modern `.draggable()` and `.dropDestination()` APIs, which work seamlessly with SwiftData's `PersistentIdentifier`.

## Implementation Details

### 1. Making Connections Draggable

Each connection is made draggable using the `.draggable()` modifier:

```swift
.draggable(connection.id) {
    // Preview view shown while dragging
    Label(connection.name, systemImage: "server.rack")
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
}
```

**Key points:**
- Passes `connection.id` (a `PersistentIdentifier`) directly
- Shows a custom preview with the connection name and icon
- No manual `NSItemProvider` or data encoding needed

### 2. Drop Handler Function

Simple function to update the connection's folder:

```swift
private func handleDrop(items: [PersistentIdentifier], targetFolder: ConnectionFolder?) -> Bool {
    guard let draggedID = items.first else { return false }
    
    // Find the connection in our list by ID
    if let connection = connections.first(where: { $0.id == draggedID }) {
        connection.folder = targetFolder
        try? modelContext.save()
    }
    
    return true
}
```

**Key points:**
- Receives array of `PersistentIdentifier` directly from SwiftUI
- Finds connection by matching ID
- Updates folder relationship
- Saves to SwiftData context
- Synchronous execution on main thread

### 3. Drop Destinations

#### Unfoldered Section

```swift
.dropDestination(for: PersistentIdentifier.self) { items, location in
    handleDrop(items: items, targetFolder: nil)
} isTargeted: { isTargeted in
    isDropTargetingUnfoldered = isTargeted
}
```

Sets `targetFolder: nil` to remove folder assignment.

#### Folder Sections

```swift
.dropDestination(for: PersistentIdentifier.self) { items, location in
    handleDrop(items: items, targetFolder: folder)
} isTargeted: { isTargeted in
    if isTargeted {
        dropTargetFolder = folder
    } else if dropTargetFolder?.id == folder.id {
        dropTargetFolder = nil
    }
}
```

Passes the specific folder to assign the connection to.

### 4. Visual Feedback

**Unfoldered section:**
```swift
.listRowBackground(isDropTargetingUnfoldered ? Color.accentColor.opacity(0.2) : nil)
```

**Folder headers:**
```swift
.background(dropTargetFolder?.id == folder.id ? Color.accentColor.opacity(0.15) : Color.clear)
```

State variables track which areas are being targeted for drops.

## Advantages of This Approach

✅ **Type-safe**: Uses `PersistentIdentifier` directly, no string conversion
✅ **Simple**: SwiftUI handles all the data transfer
✅ **Efficient**: No manual encoding/decoding
✅ **Reliable**: Persistent identifiers are stable across app launches
✅ **Modern**: Uses latest SwiftUI APIs (iOS 16+, macOS 13+)
✅ **Clean**: Custom drag preview enhances UX

## State Management

```swift
@State private var dropTargetFolder: ConnectionFolder?
@State private var isDropTargetingUnfoldered = false
```

These track which drop target is currently highlighted.

## Common Pitfalls Avoided

❌ **Don't use**: `.onDrag` with `NSItemProvider` and custom UTI - overly complex
❌ **Don't use**: `uriRepresentation()` - doesn't exist on `PersistentIdentifier`
❌ **Don't use**: `hashValue` for identification - not stable
❌ **Don't use**: Async drop handling - causes UI glitches

✅ **Do use**: `.draggable()` with direct type transfer
✅ **Do use**: `PersistentIdentifier` for type-safe references
✅ **Do use**: Synchronous drop handling on main thread
✅ **Do use**: SwiftData relationships for clean data model

## Testing Checklist

- [x] Drag connection to folder
- [x] Drag connection from folder to unfoldered section
- [x] Drag connection between folders
- [x] Visual feedback appears when dragging
- [x] Connection persists in new location
- [x] Works with collapsed folders
- [x] Drop zone appears when needed
- [x] Custom drag preview shows

## Compatibility

- **Minimum**: macOS 13.0 (Ventura)
- **APIs Used**: 
  - `.draggable(_:preview:)` - SwiftUI
  - `.dropDestination(for:action:isTargeted:)` - SwiftUI
  - `PersistentIdentifier` - SwiftData

## Future Enhancements

Potential improvements:
- Multi-selection drag (select multiple connections, drag all at once)
- Drag animations (smooth transition to new location)
- Undo/redo support
- Drop sound effects
- Haptic feedback (if supported)
- Drag to reorder connections within a folder

## Code Quality Notes

- All drag/drop code is in ContentView.swift
- No separate drag/drop manager needed
- SwiftUI handles all the heavy lifting
- Clean separation between UI and data model
- Follows SwiftUI best practices

## Performance

- ✅ Minimal overhead - just ID transfer
- ✅ No animation lag
- ✅ Instant visual feedback
- ✅ Efficient lookup (O(n) where n = number of connections)
- ✅ Could optimize with dictionary lookup if needed (100+ connections)

## Debugging Tips

If drops aren't working:
1. Check that `.draggable()` type matches `.dropDestination()` type (`PersistentIdentifier`)
2. Verify `handleDrop()` returns `true`
3. Ensure connections array is populated
4. Check that folder is not nil when it shouldn't be
5. Use breakpoint in `handleDrop()` to verify it's called

If visual feedback isn't working:
1. Verify state variables are @State
2. Check that `isTargeted` closure updates state
3. Ensure modifiers are on correct view (section, not individual rows)

## Related Documentation

- QUICK_START_DRAG_DROP.md - User guide
- FOLDER_ORGANIZATION_GUIDE.md - Feature overview
- ContentView.swift - Implementation
