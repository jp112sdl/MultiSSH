# Syntax Highlighting Import/Export Guide

## Overview

MultiSSH now supports importing and exporting syntax highlighting keywords and colors. This allows you to:
- **Backup** your custom highlighting configuration
- **Share** highlighting profiles with team members
- **Transfer** settings between machines
- **Version control** your syntax highlighting preferences

## What Changed

### ✅ Added
- ✨ Import keywords from JSON files
- ✨ Export keywords to JSON files
- ✨ Merge or replace options when importing
- ✨ No default keywords on first launch (clean slate)

### ❌ Removed
- Quick preset buttons (System Logs, Git, Docker, Network)
- Default keywords loaded automatically
- "Reset to Defaults" option

## File Format

Syntax highlighting configurations are stored as JSON files with keyword-color pairs:

```json
{
  "error": "#FF453A",
  "warning": "#FF9F0A",
  "success": "#32D74B",
  "info": "#0A84FF"
}
```

### Format Specification

- **File extension**: `.json`
- **Structure**: JSON object with string key-value pairs
- **Keys**: Keywords to highlight (case-sensitive)
- **Values**: Hex color codes (with or without `#` prefix)
- **Supported formats**: 
  - 6-digit hex: `#RRGGBB` (e.g., `#FF453A`)
  - 3-digit hex: `#RGB` (e.g., `#F4A`)
  - Without hash: `RRGGBB` (e.g., `FF453A`)

## How to Export

### From the UI

1. Open **Syntax Highlighting Settings** (paintbrush icon)
2. Click the **•••** menu button (top right)
3. Select **"Export Keywords..."**
4. Choose a location and filename
5. Click **Save**

### What Gets Exported

- All currently saved keywords
- Colors in hex format (`#RRGGBB`)
- Formatted JSON with sorted keys
- Human-readable formatting

### Export Button Location

- **When you have keywords**: Top-right menu (•••)
- **From Import & Export section**: Large "Export to File" button at bottom

## How to Import

### From the UI

1. Open **Syntax Highlighting Settings**
2. Click **"Import from File"** button
   - Or from the **•••** menu → **"Import Keywords..."**
3. Select a `.json` file
4. Choose import mode:
   - **Merge with Existing**: Keep current keywords, add new ones
   - **Replace All**: Delete all current keywords, use only imported ones
5. Keywords are imported immediately

### Import Modes

#### Merge with Existing
- Keeps all current keywords
- Adds new keywords from file
- Overwrites conflicting keywords with imported colors
- **Use when**: Adding to your existing setup

#### Replace All
- Deletes all current keywords
- Imports only keywords from file
- **Use when**: Starting fresh or adopting a complete profile

### Import Behavior

- Duplicate keywords (same name) use the imported color
- Invalid color codes default to black
- Malformed JSON shows an error message
- Empty files are valid (removes all keywords if replacing)

## Common Use Cases

### 1. Backing Up Your Configuration

```bash
# Export your keywords regularly
# File: syntax-highlights-backup-2026-05-21.json
```

**Steps:**
1. Export to your backup location
2. Name file with date for easy tracking
3. Store in version control or cloud storage

### 2. Sharing with Team

```bash
# Create a team standard
# File: team-syntax-highlights.json
```

**Steps:**
1. One team member creates the ideal setup
2. Export to file
3. Share file via email, Slack, or repository
4. Team members import with "Replace All"

### 3. Different Profiles for Different Projects

```bash
# Create multiple profiles
syntax-highlights-production.json
syntax-highlights-development.json
syntax-highlights-debugging.json
```

**Steps:**
1. Configure keywords for each scenario
2. Export each to a separate file
3. Import appropriate file when switching contexts

### 4. Version Control

```bash
# In your dotfiles repository
~/dotfiles/multissh/syntax-highlights.json
```

**Steps:**
1. Export to your dotfiles repo
2. Commit and push
3. On new machines, clone repo and import

## Example Configurations

### Minimal Configuration
```json
{
  "error": "#FF0000",
  "success": "#00FF00",
  "warning": "#FFA500"
}
```

### System Administrator
```json
{
  "ERROR": "#FF453A",
  "FAIL": "#FF453A",
  "denied": "#FF6961",
  "permission denied": "#FF6961",
  "success": "#32D74B",
  "completed": "#32D74B",
  "WARNING": "#FF9F0A",
  "timeout": "#FF9F0A",
  "critical": "#FF453A",
  "info": "#0A84FF",
  "started": "#0A84FF",
  "stopped": "#FFD60A"
}
```

### Developer
```json
{
  "error": "#FF453A",
  "exception": "#FF453A",
  "failed": "#FF453A",
  "success": "#32D74B",
  "passed": "#32D74B",
  "warning": "#FF9F0A",
  "deprecated": "#FF9F0A",
  "info": "#0A84FF",
  "debug": "#8E8E93",
  "trace": "#636366"
}
```

### Network Engineer
```json
{
  "connected": "#32D74B",
  "established": "#32D74B",
  "up": "#32D74B",
  "disconnected": "#FF453A",
  "down": "#FF453A",
  "timeout": "#FF9F0A",
  "refused": "#FF6961",
  "listening": "#0A84FF",
  "closed": "#8E8E93"
}
```

### Container/Docker
```json
{
  "Up": "#32D74B",
  "running": "#32D74B",
  "healthy": "#32D74B",
  "Exited": "#FF453A",
  "stopped": "#FF453A",
  "unhealthy": "#FF6961",
  "pulling": "#0A84FF",
  "building": "#FFD60A",
  "created": "#30D158",
  "restarting": "#FF9F0A"
}
```

## File Locations

### Recommended Locations

**Personal Backups:**
```
~/Documents/MultiSSH/syntax-highlights.json
~/Library/Application Support/MultiSSH/syntax-highlights.json
```

**Team Shared:**
```
~/Shared/team-configs/multissh-highlights.json
/path/to/team-repo/configs/syntax-highlights.json
```

**Version Control:**
```
~/dotfiles/multissh/syntax-highlights.json
~/.config/multissh/syntax-highlights.json
```

## Troubleshooting

### Import Shows "Invalid Format"

**Causes:**
- File is not valid JSON
- File structure is incorrect
- File is empty or corrupted

**Solutions:**
1. Open file in text editor
2. Validate JSON at jsonlint.com
3. Ensure structure is `{ "keyword": "#color" }`
4. Check for missing quotes, commas, or braces

### Colors Don't Look Right

**Causes:**
- Incorrect hex color format
- Colors designed for light mode (or vice versa)

**Solutions:**
1. Use 6-digit hex codes with `#` prefix
2. Test colors in system color picker
3. Adjust for your macOS appearance setting

### Import Doesn't Add Keywords

**Causes:**
- File contains no keywords
- Import dialog was cancelled
- File read permission issue

**Solutions:**
1. Check file contains valid keywords
2. Ensure file is readable (`chmod 644 file.json`)
3. Try "Replace All" instead of "Merge"

### Keywords Disappeared After Import

**Cause:**
- Selected "Replace All" with empty or minimal file

**Solution:**
- Re-import your backup file
- Or manually add keywords again

## Best Practices

### 1. Regular Backups
Export your configuration monthly or after major changes.

### 2. Meaningful Names
Use descriptive filenames:
- ✅ `syntax-highlights-production-red-theme.json`
- ❌ `config.json`

### 3. Documentation
Add a README next to your exports:
```markdown
# MultiSSH Syntax Highlights

- `default.json` - General purpose highlighting
- `debug.json` - Extra verbose for debugging
- `minimal.json` - Only critical keywords
```

### 4. Version Control
Track changes to your profiles:
```bash
git add syntax-highlights.json
git commit -m "Add docker keywords to syntax highlighting"
```

### 5. Test Before Sharing
Before sharing with team, test the import:
1. Export current config (backup)
2. Clear all keywords
3. Import new config
4. Verify it works
5. Export again if needed

## Technical Details

### Storage Location

Keywords are stored in:
```
UserDefaults.standard
Key: "SyntaxHighlights"
Format: Dictionary [String: String]
```

### Color Conversion

During export:
1. NSColor → RGB components
2. RGB → Hex string format
3. JSON serialization with sorted keys

During import:
1. JSON deserialization
2. Hex string → RGB components
3. RGB → NSColor object

### Performance

- Export: O(n) where n = number of keywords
- Import: O(n) where n = number of keywords
- Merge: O(n + m) where m = existing keywords
- No impact on runtime highlighting performance

## API for Advanced Users

If you want to programmatically work with the files:

### Reading with Python
```python
import json

with open('syntax-highlights.json') as f:
    highlights = json.load(f)
    
for keyword, color in highlights.items():
    print(f"{keyword}: {color}")
```

### Creating with Shell Script
```bash
cat > my-highlights.json << EOF
{
  "error": "#FF0000",
  "success": "#00FF00"
}
EOF
```

### Merging Multiple Files
```bash
jq -s '.[0] * .[1]' file1.json file2.json > merged.json
```

## Related Documentation

- `SYNTAX_HIGHLIGHTING_GUIDE.md` - Using syntax highlighting
- `sample-syntax-highlights.json` - Example file
- `ConnectionManager.swift` - Implementation details

## Support

If you encounter issues:
1. Check file format is valid JSON
2. Verify color codes are correct
3. Try export → import test
4. Check file permissions
5. Open an issue with example file attached

---

**Remember**: Always keep a backup before replacing all keywords!
