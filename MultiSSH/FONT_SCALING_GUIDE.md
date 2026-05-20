# Font Scaling Feature

## Overview

You can now scale the font size of all SSH terminal sessions simultaneously using a convenient slider in the toolbar.

## How to Use

### Font Size Controls

Located in the toolbar at the top of the detail view (when you have active connections):

1. **Font Slider**: Adjust from 8pt to 24pt
2. **Font Size Display**: Shows current size (e.g., "11pt")
3. **Reset Button**: Click the ↺ icon to reset to default 11pt

### Features

✅ **Real-time Updates**: Font size changes apply immediately to all terminals
✅ **Persistent Content**: When you change font size, all existing terminal output is re-rendered
✅ **Global Control**: One slider affects all terminal windows
✅ **Wide Range**: From 8pt (tiny) to 24pt (large)
✅ **Easy Reset**: One-click return to default 11pt

## Font Size Range

- **Minimum**: 8pt (very small, for fitting lots of content)
- **Default**: 11pt (comfortable for most users)
- **Maximum**: 24pt (very large, for accessibility)

## Keyboard Shortcuts

While there are no built-in keyboard shortcuts, you can use standard macOS accessibility features:

- **⌘+** : Zoom in (system-wide)
- **⌘-** : Zoom out (system-wide)
- **⌘0** : Reset zoom (system-wide)

## Use Cases

### Small Font (8-10pt)
- Monitoring many servers at once
- Fitting more content on screen
- When window space is limited

### Default Font (11pt)
- General everyday use
- Good balance of readability and content density

### Large Font (16-24pt)
- Accessibility needs
- Presentations or demos
- When sitting far from screen
- Eyestrain reduction

## Technical Details

### Implementation

The font scaling system consists of three components:

1. **ANSIParser** - Now has configurable `fontSize` property
2. **TerminalView** - Accepts `fontSize` parameter and updates in real-time
3. **ContentView** - Global `fontSize` state controlled by slider

### Font Rendering

- Uses **monospaced system font** (SF Mono on macOS)
- Maintains proper spacing and alignment at all sizes
- ANSI color codes and formatting preserved
- Bold text scales proportionally

### Performance

- Font size changes trigger a re-parse of terminal content
- This is fast and imperceptible for normal terminal output
- Very long terminal sessions (thousands of lines) may have a brief delay

## Accessibility

This feature improves accessibility by:
- ✅ Supporting users with visual impairments
- ✅ Reducing eye strain for users who prefer larger text
- ✅ Allowing customization for different viewing distances
- ✅ Working alongside macOS system accessibility features

## Tips

1. **Find Your Sweet Spot**: Experiment to find the most comfortable size for your workflow
2. **Combine with Window Sizing**: Use both font size and window dimensions for optimal layout
3. **Reset Often**: Use the reset button to quickly return to defaults when needed
4. **Zoom Alternative**: Remember you can also use macOS system zoom (⌘+ / ⌘-) for temporary magnification

## Future Enhancements

Potential future improvements:
- Per-session font sizes (different size for each terminal)
- Font family selection (different monospace fonts)
- Keyboard shortcuts for font scaling
- Saved font size preferences
- Font size presets (small/medium/large buttons)
