# Syntax Highlighting

## Overview

The SSH terminal now supports custom keyword-based syntax highlighting. You can define keywords and assign colors to them, and those keywords will be highlighted in all terminal output.

## How to Use

1. **Open Settings**: When you have active SSH sessions, click the paintbrush icon (🎨) in the toolbar
2. **Add Keywords**: Enter a keyword and select a color, then click "Add"
3. **Use Presets**: Choose from preset collections like "System Logs", "Git Output", "Docker", or "Network"
4. **Edit/Delete**: Click the pencil icon to edit a keyword's color, or the trash icon to remove it

## Features

### Word Matching
- Keywords are matched as whole words only (e.g., "error" won't match "errors")
- Case-insensitive matching (e.g., "ERROR" and "error" are treated the same in matching)
- You can add multiple variations if you want different colors (e.g., "ERROR" in red, "error" in orange)

### Live Updates
- Changes to syntax highlighting apply immediately to all open terminal windows
- Existing content is re-rendered with the new highlighting rules

### Preset Collections

**System Logs**
- error/ERROR/fail/FAIL/fatal → Red
- warning/WARNING/warn → Orange
- info/INFO → Blue
- success/SUCCESS → Green
- debug → Gray

**Git Output**
- modified → Yellow
- deleted → Red
- created → Green
- renamed → Blue
- conflict → Orange
- branch → Purple
- commit → Green
- merge → Teal

**Docker**
- Up/running → Green
- Exited/stopped → Red
- pulling → Blue
- building → Yellow

**Network**
- connected/listening/established → Green
- disconnected/refused → Red
- timeout → Orange

## Technical Details

### Implementation
- Keywords are stored in the `ConnectionManager` as a dictionary: `[String: NSColor]`
- The `ANSIParser` applies keyword highlighting after processing ANSI escape codes
- ANSI colors take precedence - keywords only colorize text that would otherwise be the default green

### Adding Programmatically

You can also add highlights programmatically in code:

```swift
manager.addHighlight(keyword: "critical", color: .systemRed)
manager.addHighlight(keyword: "debug", color: .systemGray)
manager.removeHighlight(keyword: "debug")
```

### Performance
- Keyword matching uses efficient string searching with NSString APIs
- Only whole word matches are considered to avoid false positives
- Re-rendering is triggered only when settings change or new text arrives

## Examples

### Common Use Cases

**System Administration**
```swift
manager.addHighlight(keyword: "sudo", color: .systemYellow)
manager.addHighlight(keyword: "root", color: .systemPurple)
manager.addHighlight(keyword: "permission denied", color: .systemRed)
```

**Application Monitoring**
```swift
manager.addHighlight(keyword: "started", color: .systemGreen)
manager.addHighlight(keyword: "stopped", color: .systemRed)
manager.addHighlight(keyword: "restart", color: .systemOrange)
```

**Custom Status Indicators**
```swift
manager.addHighlight(keyword: "✓", color: .systemGreen)
manager.addHighlight(keyword: "✗", color: .systemRed)
manager.addHighlight(keyword: "⚠", color: .systemOrange)
```

## Future Enhancements

Potential improvements:
- Regular expression support for pattern matching
- Import/export highlight configurations
- Per-connection highlight profiles
- Background color highlighting
- Bold/italic text styles
- Persistent storage of custom keywords
