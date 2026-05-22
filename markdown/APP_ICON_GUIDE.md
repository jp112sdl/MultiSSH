# App Icon Guide for MultiSSH

## Option 1: Generate Custom Icon (Recommended)

I've created a Swift script that generates a custom icon for your SSH terminal app.

### Steps:
1. Run the generator script:
   ```bash
   swift GenerateAppIcon.swift
   ```

2. This will create PNG files for all required sizes

3. In Xcode:
   - Open `Assets.xcassets`
   - Right-click and select "New App Icon"
   - Name it "AppIcon"
   - Drag and drop the generated PNG files into their respective slots

4. Update your project settings:
   - Select your app target
   - Go to "General" tab
   - Under "App Icons and Launch Screen" select your new AppIcon

### What the Icon Looks Like:
- Dark terminal-like background with gradient
- 2x2 grid representing multiple terminal windows
- Green ">" terminal prompts in each window
- Orange connection node in the center
- Professional, modern design

## Option 2: Use Free Icon Resources

### Free Icon Websites:

1. **SF Symbols** (Apple's official icons - FREE)
   - Download: https://developer.apple.com/sf-symbols/
   - Suggested symbols: `terminal`, `network`, `server.rack`
   - Can be exported as PNG and customized

2. **Iconduck** (FREE, No attribution required)
   - https://iconduck.com
   - Search for: "terminal", "ssh", "console", "server"
   - License: Free for commercial use

3. **Iconoir** (FREE, MIT License)
   - https://iconoir.com
   - Search for: "terminal", "server"
   - License: MIT (free for any use)

4. **Heroicons** (FREE, MIT License)
   - https://heroicons.com
   - Search for: "terminal", "server"
   - License: MIT

5. **Tabler Icons** (FREE, MIT License)
   - https://tabler-icons.io
   - Search for: "terminal", "server", "prompt"
   - License: MIT

6. **Phosphor Icons** (FREE, MIT License)
   - https://phosphoricons.com
   - Search for: "terminal", "terminal-window"
   - License: MIT

## Option 3: Create Icon with iconutil (macOS)

If you have PNG files, convert them to .icns format:

```bash
# Create iconset directory
mkdir AppIcon.iconset

# Copy your PNGs with proper naming
cp icon_16x16.png AppIcon.iconset/icon_16x16.png
cp icon_16x16@2x.png AppIcon.iconset/icon_16x16@2x.png
cp icon_32x32.png AppIcon.iconset/icon_32x32.png
cp icon_32x32@2x.png AppIcon.iconset/icon_32x32@2x.png
cp icon_128x128.png AppIcon.iconset/icon_128x128.png
cp icon_128x128@2x.png AppIcon.iconset/icon_128x128@2x.png
cp icon_256x256.png AppIcon.iconset/icon_256x256.png
cp icon_256x256@2x.png AppIcon.iconset/icon_256x256@2x.png
cp icon_512x512.png AppIcon.iconset/icon_512x512.png
cp icon_512x512@2x.png AppIcon.iconset/icon_512x512@2x.png

# Convert to .icns
iconutil -c icns AppIcon.iconset
```

## Option 4: Quick SF Symbols Icon

For a quick solution, you can use an SF Symbol as your app icon:

1. Open SF Symbols app (free from Apple)
2. Search for "terminal" or "rectangle.3.group"
3. Export as PNG at 1024x1024
4. Add to your project

Suggested SF Symbols:
- `terminal` - Classic terminal icon
- `rectangle.3.group` - Multiple windows
- `server.rack` - Server icon
- `network` - Network/connections

## Recommended Design Concepts:

For an SSH multi-terminal app, your icon should convey:
1. **Terminal/Console** - Use terminal prompt symbols (>, $, #)
2. **Multiple Sessions** - Show grid or multiple windows
3. **Connectivity** - Network lines or connection points
4. **Professional** - Clean, modern design with good contrast

## Colors That Work Well:

- **Background**: Dark gray/blue (#1A1D23, #151821)
- **Accent**: Terminal green (#4CAF50, #50FA7B)
- **Secondary**: Orange/amber for highlights (#FF9800, #FFB86C)
- **Text/Lines**: Light blue/cyan (#64B5F6, #8BE9FD)

## License Note:

The generated icon script creates 100% original artwork that you own completely. No attribution required, free for commercial use.
