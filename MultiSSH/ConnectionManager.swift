import Foundation
import SwiftData
import AppKit

@Observable
final class ConnectionManager {
    var sessions: [SSHSession] = []
    
    // Syntax highlighting keywords dictionary: [keyword: color]
    var syntaxHighlights: [String: NSColor] = [:] {
        didSet {
            saveSyntaxHighlights()
        }
    }
    
    init() {
        loadSyntaxHighlights()
    }

    func session(for connection: SSHConnection) -> SSHSession? {
        sessions.first { $0.connection.id == connection.id }
    }

    func connect(_ connection: SSHConnection) {
        guard session(for: connection) == nil else { return }
        let s = SSHSession(connection: connection)
        sessions.append(s)
        s.connect()
    }

    func disconnect(_ connection: SSHConnection) {
        guard let s = session(for: connection) else { return }
        s.disconnect()
        sessions.removeAll { $0.connection.id == connection.id }
    }

    func broadcast(_ text: String) {
        for s in sessions where s.isActive && s.isConnected {
            s.send(text)
        }
    }
    
    // MARK: - Syntax Highlighting Management
    
    /// Add or update a keyword highlight
    func addHighlight(keyword: String, color: NSColor) {
        syntaxHighlights[keyword] = color
    }
    
    /// Remove a keyword highlight
    func removeHighlight(keyword: String) {
        syntaxHighlights.removeValue(forKey: keyword)
    }
    
    // MARK: - Persistence
    
    private func saveSyntaxHighlights() {
        // Convert NSColor to hex strings for storage
        var savedHighlights: [String: String] = [:]
        for (keyword, color) in syntaxHighlights {
            savedHighlights[keyword] = color.hexString
        }
        UserDefaults.standard.set(savedHighlights, forKey: "SyntaxHighlights")
    }
    
    private func loadSyntaxHighlights() {
        guard let saved = UserDefaults.standard.dictionary(forKey: "SyntaxHighlights") as? [String: String] else {
            // Start with empty highlights - no defaults
            return
        }
        
        // Convert hex strings back to NSColor
        for (keyword, hexString) in saved {
            syntaxHighlights[keyword] = NSColor(hex: hexString)
        }
    }
    
    // MARK: - Import/Export
    
    /// Export syntax highlights to JSON format
    func exportHighlights() -> Data? {
        var exportData: [String: String] = [:]
        for (keyword, color) in syntaxHighlights {
            exportData[keyword] = color.hexString
        }
        
        return try? JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
    }
    
    /// Import syntax highlights from JSON data
    func importHighlights(from data: Data, replace: Bool = false) throws {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: String] else {
            throw ImportError.invalidFormat
        }
        
        if replace {
            syntaxHighlights.removeAll()
        }
        
        for (keyword, hexString) in json {
            syntaxHighlights[keyword] = NSColor(hex: hexString)
        }
    }
    
    enum ImportError: LocalizedError {
        case invalidFormat
        
        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "Invalid file format. Expected JSON with keyword-color pairs."
            }
        }
    }
}

// MARK: - NSColor Extensions

extension NSColor {
    /// Convert NSColor to hex string
    var hexString: String {
        guard let rgbColor = usingColorSpace(.deviceRGB) else {
            return "#000000"
        }
        let r = Int(rgbColor.redComponent * 255)
        let g = Int(rgbColor.greenComponent * 255)
        let b = Int(rgbColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    /// Create NSColor from hex string
    convenience init(hex: String) {
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
            (a, r, g, b) = (255, 0, 0, 0) // Default black if invalid
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
