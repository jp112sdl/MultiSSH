import Foundation
import SwiftData
import SwiftUI
import AppKit

@Model
final class ConnectionFolder {
    var name: String = "New Folder"
    var colorHex: String = "#3B82F6" // Blue default
    var sortOrder: Int = 0
    
    // Relationship to connections
    @Relationship(deleteRule: .nullify, inverse: \SSHConnection.folder)
    var connections: [SSHConnection] = []
    
    init(name: String, colorHex: String = "#3B82F6", sortOrder: Int = 0) {
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }
    
    /// Get the SwiftUI Color from the hex string
    var color: Color {
        Color(hex: colorHex)
    }
}

// Helper extension to create Color from hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 59, 130, 246) // Default blue if invalid
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    var hexString: String {
        // Convert SwiftUI Color to NSColor to get components
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else {
            return "#000000"
        }
        let r = Int(rgbColor.redComponent * 255)
        let g = Int(rgbColor.greenComponent * 255)
        let b = Int(rgbColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

