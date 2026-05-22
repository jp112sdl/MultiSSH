#!/bin/bash

# Generate App Icons for MultiSSH
# This script creates PNG icons using Swift code

echo "Generating app icons..."

swift - <<'EOF'
import AppKit
import Foundation

func generateIcon(size: CGSize, outputPath: String) {
    let image = NSImage(size: size)
    
    image.lockFocus()
    
    // Background gradient (terminal-like colors)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.1, green: 0.12, blue: 0.15, alpha: 1.0),
        NSColor(red: 0.15, green: 0.18, blue: 0.22, alpha: 1.0)
    ])
    let rect = NSRect(origin: .zero, size: size)
    gradient?.draw(in: rect, angle: 135)
    
    // Draw rounded rectangle background
    let roundedRect = NSBezierPath(roundedRect: rect.insetBy(dx: size.width * 0.05, dy: size.height * 0.05),
                                   xRadius: size.width * 0.15,
                                   yRadius: size.width * 0.15)
    NSColor(red: 0.2, green: 0.24, blue: 0.28, alpha: 1.0).setFill()
    roundedRect.fill()
    
    // Draw grid pattern (representing multiple terminals)
    let gridColor = NSColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 0.6)
    gridColor.setStroke()
    
    let gridSize = size.width * 0.25
    let gridSpacing = size.width * 0.05
    let startX = (size.width - (gridSize * 2 + gridSpacing)) / 2
    let startY = (size.height - (gridSize * 2 + gridSpacing)) / 2
    
    for row in 0..<2 {
        for col in 0..<2 {
            let x = startX + CGFloat(col) * (gridSize + gridSpacing)
            let y = startY + CGFloat(row) * (gridSize + gridSpacing)
            let termRect = NSRect(x: x, y: y, width: gridSize, height: gridSize)
            let termPath = NSBezierPath(roundedRect: termRect, xRadius: gridSize * 0.1, yRadius: gridSize * 0.1)
            termPath.lineWidth = size.width * 0.015
            termPath.stroke()
            
            // Add terminal prompt symbol
            let promptText = ">" as NSString
            let fontSize = gridSize * 0.4
            let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .semibold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
            ]
            let textSize = promptText.size(withAttributes: attributes)
            let textRect = NSRect(
                x: x + (gridSize - textSize.width) / 2,
                y: y + (gridSize - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            promptText.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    // Add a connection symbol at the center
    let centerX = size.width / 2
    let centerY = size.height / 2
    let nodeRadius = size.width * 0.03
    
    NSColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0).setFill()
    let centerNode = NSBezierPath(ovalIn: NSRect(
        x: centerX - nodeRadius,
        y: centerY - nodeRadius,
        width: nodeRadius * 2,
        height: nodeRadius * 2
    ))
    centerNode.fill()
    
    image.unlockFocus()
    
    // Save the image
    if let tiffData = image.tiffRepresentation,
       let bitmapImage = NSBitmapImageRep(data: tiffData),
       let pngData = bitmapImage.representation(using: .png, properties: [:]) {
        try? pngData.write(to: URL(fileURLWithPath: outputPath))
        print("✓ Generated: \(outputPath)")
    }
}

// Generate icons for different sizes
let sizes: [(size: CGSize, name: String)] = [
    (CGSize(width: 16, height: 16), "icon_16x16.png"),
    (CGSize(width: 32, height: 32), "icon_16x16@2x.png"),
    (CGSize(width: 32, height: 32), "icon_32x32.png"),
    (CGSize(width: 64, height: 64), "icon_32x32@2x.png"),
    (CGSize(width: 128, height: 128), "icon_128x128.png"),
    (CGSize(width: 256, height: 256), "icon_128x128@2x.png"),
    (CGSize(width: 256, height: 256), "icon_256x256.png"),
    (CGSize(width: 512, height: 512), "icon_256x256@2x.png"),
    (CGSize(width: 512, height: 512), "icon_512x512.png"),
    (CGSize(width: 1024, height: 1024), "icon_512x512@2x.png"),
]

for (size, name) in sizes {
    generateIcon(size: size, outputPath: name)
}
EOF

echo ""
echo "✅ Done! Icon files generated."
echo ""
echo "Next steps:"
echo "1. In Xcode, open Assets.xcassets"
echo "2. Right-click and select 'App Icons & Launch Images' → 'New macOS App Icon'"
echo "3. Drag and drop the generated PNG files into the icon set"
echo ""
echo "Generated files:"
ls -lh icon_*.png 2>/dev/null || echo "No files found. Make sure the script ran successfully."
