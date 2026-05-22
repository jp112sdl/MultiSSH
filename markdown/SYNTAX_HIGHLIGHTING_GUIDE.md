# Syntax Highlighting Configuration Guide

## Overview

Your SSH terminal application now includes a powerful and persistent syntax highlighting system. You can configure custom keywords and assign colors to them, and these settings will be saved automatically and restored when you relaunch the app.

## Features

### ✅ What's Included

- **Persistent Storage**: All keywords and colors are automatically saved to UserDefaults
- **Live Editing**: Changes apply instantly to all open terminal windows
- **Search & Filter**: Quickly find keywords in your configuration
- **Edit Mode**: Click any keyword to edit its color
- **Quick Presets**: Pre-configured collections for common scenarios
- **Default Keywords**: Starts with sensible defaults on first launch

## Opening the Configuration Window

There are **three ways** to open the Syntax Highlighting configuration:

### Option 1: Toolbar Button (Recommended)
1. Look in the sidebar toolbar (where your connections are listed)
2. Click the **paintbrush icon (🎨)** button
3. The configuration window will appear

### Option 2: Menu
1. Click the **"+" menu** in the sidebar toolbar
2. Select **"Syntax Highlighting"** from the menu
3. The configuration window will appear

### Option 3: When Sessions Are Active
1. Connect to at least one SSH session
2. Look for the **paintbrush icon** in the terminal controls toolbar (top of detail pane)
3. Click it to open the configuration window

**Note**: The paintbrush button is now always accessible in the sidebar, so you don't need an active connection to configure your highlights!

## Managing Keywords

### Adding a New Keyword

1. Type the keyword in the text field (e.g., "error", "success", "warning")
2. Click the color picker to choose a color
3. Press **Enter** or click **Add**
4. The keyword is immediately saved and active

### Editing an Existing Keyword

1. Click the **pencil icon** next to any keyword in the list
2. The keyword and its current color will appear in the edit area at the top
3. Modify the keyword text or change the color
4. Click **Update** to save changes
5. Click **Cancel** to discard changes

### Deleting a Keyword

1. Hover over any keyword in the list
2. Click the **trash icon** that appears
3. The keyword is immediately removed

### Searching Keywords

1. Use the search box to filter the keyword list
2. Type any part of a keyword to find it
3. Click the **X** button to clear the search

## Using Presets

The configuration window includes 4 pre-built presets:

### System Logs
Perfect for monitoring system logs and application output:
- **Red**: error, ERROR, fail, FAIL, fatal
- **Orange**: warning, WARNING, warn
- **Blue**: info, INFO
- **Green**: success, SUCCESS
- **Gray**: debug

### Git Output
Highlights Git status and operations:
- **Yellow**: modified
- **Red**: deleted
- **Green**: created, commit
- **Blue**: renamed, established
- **Orange**: conflict
- **Purple**: branch
- **Teal**: merge

### Docker
For Docker container management:
- **Green**: Up, running
- **Red**: Exited, stopped
- **Blue**: pulling
- **Yellow**: building

### Network
Network status monitoring:
- **Green**: connected, listening, established
- **Red**: disconnected, refused
- **Orange**: timeout

**To apply a preset**: Simply click the preset button. Keywords will be added to your existing configuration (not replaced).

## Bulk Actions

### Clear All Keywords
1. Click the **ellipsis icon (⋯)** in the keyword list header
2. Select "Clear All Keywords"
3. Confirm the action
4. All keywords will be removed

### Reset to Defaults
1. Click the **ellipsis icon (⋯)** in the keyword list header
2. Select "Reset to Defaults"
3. Confirm the action
4. All current keywords are removed and System Logs preset is applied

## How Highlighting Works

### Matching Rules
- **Whole word matching**: The keyword "error" will match "error" but not "errors"
- **Case insensitive**: Matches both uppercase and lowercase variations
- **Pattern matching**: Searches anywhere in the output text

### Color Priority
1. ANSI escape codes (terminal colors) take precedence
2. If text has no ANSI color, keyword highlighting applies
3. Default green terminal text is replaced by keyword colors

### Performance
- Efficient string searching using NSString APIs
- Only processes new text as it arrives
- Re-renders only when settings change

## Persistence

### Automatic Saving
- Keywords are automatically saved whenever you:
  - Add a new keyword
  - Edit an existing keyword
  - Delete a keyword
  - Apply a preset
  - Clear all keywords

### Storage Location
- Settings are stored in UserDefaults
- Keys and colors are encoded as hex strings
- No manual save action required

### First Launch
- On first launch, default System Logs keywords are loaded
- You can customize or clear these defaults immediately

## Tips & Best Practices

### Choosing Keywords
- **Be specific**: Use words that uniquely identify what you're looking for
- **Consider case**: Remember matching is case-insensitive
- **Test patterns**: Try your keywords in a real SSH session

### Color Selection
- **Red**: Errors, failures, critical issues
- **Orange/Yellow**: Warnings, cautions
- **Green**: Success, completion, active states
- **Blue**: Information, status updates
- **Purple/Magenta**: Special markers, user actions
- **Gray**: Debug info, less important items

### Organizing Keywords
- Start with a preset that matches your use case
- Add custom keywords as you discover patterns
- Use the search feature to audit your keywords
- Remove unused keywords to improve performance

## Keyboard Shortcuts

- **Enter**: Add new keyword (when text field has focus)
- **⌘ + Return**: Close configuration window (Done button)
- **Escape**: Cancel editing mode

## Programmatic Access

You can also manage keywords programmatically:

```swift
// Add a keyword
manager.addHighlight(keyword: "critical", color: .systemRed)

// Remove a keyword
manager.removeHighlight(keyword: "critical")

// Access all highlights
let highlights = manager.syntaxHighlights

// Clear everything
manager.syntaxHighlights.removeAll()
```

## Troubleshooting

### Keywords Not Highlighting
1. Check that the keyword is spelled correctly
2. Verify the terminal output actually contains the keyword
3. Remember: whole word matching is enforced
4. ANSI colors may override your highlighting

### Performance Issues
1. Limit keywords to essential patterns (< 50 recommended)
2. Avoid very common words like "the" or "is"
3. Clear unused keywords regularly

### Settings Not Persisting
1. Check that app has permission to write to UserDefaults
2. Verify changes appear immediately in the configuration window
3. Try clearing all and re-adding keywords

### Window Not Opening
1. Look for the paintbrush icon in the **sidebar toolbar** (it's always visible now)
2. Alternatively, click the **+ menu** and select "Syntax Highlighting"
3. If using macOS, check that the window didn't open behind other windows

## Examples

### Monitoring Web Server Logs
```
Keywords:
- "200" → Green (HTTP OK)
- "404" → Orange (Not Found)
- "500" → Red (Server Error)
- "GET" → Blue
- "POST" → Purple
```

### DevOps Monitoring
```
Keywords:
- "deployed" → Green
- "rollback" → Orange
- "crash" → Red
- "starting" → Blue
- "stopped" → Orange
```

### Database Administration
```
Keywords:
- "COMMIT" → Green
- "ROLLBACK" → Orange
- "ERROR" → Red
- "SELECT" → Blue
- "deadlock" → Red
```

## Future Enhancements

Potential improvements we're considering:
- Regular expression pattern support
- Background color highlighting
- Bold/italic text styles
- Import/export configurations as JSON
- Per-connection highlight profiles
- Highlight groups/categories

## Support

If you encounter any issues or have suggestions for improvements, please let us know!
