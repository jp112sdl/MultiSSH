import AppKit

final class ANSIParser {
    private var foreground: NSColor = NSColor(white: 0.85, alpha: 1.0) // Light gray
    private var background: NSColor = .black
    private var bold = false
    var fontSize: CGFloat = 11 // Make this configurable
    var syntaxHighlights: [String: NSColor] = [:] // Keyword highlighting dictionary

    private static let escapeRegex = try! NSRegularExpression(
        pattern: "\u{1B}\\[([0-9;]*)([A-Za-z])",
        options: []
    )

    private var currentAttributes: [NSAttributedString.Key: Any] {
        [
            .font: bold
                ? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
                : NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: foreground,
            .backgroundColor: background
        ]
    }

    func parse(_ input: String) -> NSAttributedString {
        // Normalize CRLF and lone CR to LF for NSTextView display
        let normalized = input
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let result = NSMutableAttributedString()
        let nsStr = normalized as NSString
        var lastEnd = 0

        let matches = ANSIParser.escapeRegex.matches(
            in: normalized,
            range: NSRange(normalized.startIndex..., in: normalized)
        )

        for match in matches {
            let range = match.range

            if range.location > lastEnd {
                let text = nsStr.substring(with: NSRange(location: lastEnd, length: range.location - lastEnd))
                let highlighted = applyKeywordHighlighting(to: text)
                result.append(highlighted)
            }

            if let paramsRange = Range(match.range(at: 1), in: normalized),
               let cmdRange = Range(match.range(at: 2), in: normalized) {
                let cmd = String(normalized[cmdRange])
                if cmd == "m" {
                    applyColorCode(String(normalized[paramsRange]))
                }
            }

            lastEnd = range.location + range.length
        }

        if lastEnd < nsStr.length {
            let remaining = nsStr.substring(from: lastEnd)
            if !remaining.isEmpty {
                let highlighted = applyKeywordHighlighting(to: remaining)
                result.append(highlighted)
            }
        }

        return result
    }
    
    // Apply keyword-based syntax highlighting to a text string
    private func applyKeywordHighlighting(to text: String) -> NSAttributedString {
        guard !syntaxHighlights.isEmpty else {
            return NSAttributedString(string: text, attributes: currentAttributes)
        }
        
        let result = NSMutableAttributedString(string: text, attributes: currentAttributes)
        let nsText = text as NSString
        
        // Find and highlight each keyword
        for (keyword, color) in syntaxHighlights {
            var searchRange = NSRange(location: 0, length: nsText.length)
            
            while searchRange.location < nsText.length {
                let foundRange = nsText.range(of: keyword, options: [.caseInsensitive], range: searchRange)
                
                if foundRange.location == NSNotFound {
                    break
                }
                
                // Check if this is a whole word (optional: you can make this configurable)
                let isWholeWord = isWholeWordMatch(in: text, range: foundRange, keyword: keyword)
                
                if isWholeWord {
                    // Create attributes that preserve current style but override foreground color
                    var highlightAttrs = currentAttributes
                    highlightAttrs[.foregroundColor] = color
                    
                    result.addAttributes(highlightAttrs, range: foundRange)
                }
                
                // Move search range forward
                searchRange.location = foundRange.location + foundRange.length
                searchRange.length = nsText.length - searchRange.location
            }
        }
        
        return result
    }
    
    // Check if a match is a whole word (not part of a larger word)
    private func isWholeWordMatch(in text: String, range: NSRange, keyword: String) -> Bool {
        let nsText = text as NSString
        
        // Check character before match
        if range.location > 0 {
            let charBefore = nsText.substring(with: NSRange(location: range.location - 1, length: 1))
            if charBefore.rangeOfCharacter(from: .alphanumerics) != nil {
                return false
            }
        }
        
        // Check character after match
        let endLocation = range.location + range.length
        if endLocation < nsText.length {
            let charAfter = nsText.substring(with: NSRange(location: endLocation, length: 1))
            if charAfter.rangeOfCharacter(from: .alphanumerics) != nil {
                return false
            }
        }
        
        return true
    }

    private func applyColorCode(_ params: String) {
        let codes = params.isEmpty ? [0] : params.split(separator: ";").compactMap { Int($0) }
        for code in codes {
            switch code {
            case 0:
                foreground = NSColor(white: 0.85, alpha: 1.0) // Light gray
                background = .black
                bold = false
            case 1:  bold = true
            case 22: bold = false
            case 30...37: foreground = ansiColor(code - 30, bright: false)
            case 39:      foreground = NSColor(white: 0.85, alpha: 1.0) // Reset to light gray
            case 40...47: background = ansiColor(code - 40, bright: false)
            case 49:      background = .black
            case 90...97:   foreground = ansiColor(code - 90, bright: true)
            case 100...107: background = ansiColor(code - 100, bright: true)
            default: break
            }
        }
    }

    private func ansiColor(_ index: Int, bright: Bool) -> NSColor {
        let b: CGFloat = bright ? 1.0 : 0.75
        switch index {
        case 0: return NSColor(white: bright ? 0.4 : 0.05, alpha: 1)
        case 1: return NSColor(red: b,   green: 0,   blue: 0,   alpha: 1)
        case 2: return NSColor(red: 0,   green: b,   blue: 0,   alpha: 1)
        case 3: return NSColor(red: b,   green: b*0.75, blue: 0, alpha: 1)
        case 4: return NSColor(red: 0,   green: 0.3, blue: b,   alpha: 1)
        case 5: return NSColor(red: b,   green: 0,   blue: b,   alpha: 1)
        case 6: return NSColor(red: 0,   green: b,   blue: b,   alpha: 1)
        case 7: return NSColor(white: bright ? 1.0 : 0.8, alpha: 1)
        default: return .white
        }
    }
}
