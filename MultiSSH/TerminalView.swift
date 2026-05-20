import SwiftUI
import AppKit

struct TerminalView: NSViewRepresentable {
    let session: SSHSession
    var fontSize: CGFloat = 11
    var syntaxHighlights: [String: NSColor] = [:]

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session, fontSize: fontSize, syntaxHighlights: syntaxHighlights)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = .black
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .black
        textView.drawsBackground = true
        textView.textContainerInset = NSSize(width: 6, height: 6)
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        scrollView.documentView = textView

        context.coordinator.textView = textView

        if !session.rawOutput.isEmpty {
            context.coordinator.append(session.rawOutput)
        }

        session.onNewOutput = { [weak coord = context.coordinator] text in
            coord?.append(text)
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // Update font size if it changed
        context.coordinator.updateFontSize(fontSize)
        // Update syntax highlights if they changed
        context.coordinator.updateSyntaxHighlights(syntaxHighlights)
    }

    static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
        coordinator.session?.onNewOutput = nil
    }

    final class Coordinator {
        weak var session: SSHSession?
        var textView: NSTextView?
        private var parser: ANSIParser

        init(session: SSHSession, fontSize: CGFloat, syntaxHighlights: [String: NSColor]) {
            self.session = session
            self.parser = ANSIParser()
            self.parser.fontSize = fontSize
            self.parser.syntaxHighlights = syntaxHighlights
        }
        
        func updateFontSize(_ newSize: CGFloat) {
            guard parser.fontSize != newSize else { return }
            parser.fontSize = newSize
            
            // Re-parse and redisplay existing content with new font size
            if let session = session, !session.rawOutput.isEmpty {
                textView?.textStorage?.setAttributedString(NSAttributedString())
                append(session.rawOutput)
            }
        }
        
        func updateSyntaxHighlights(_ highlights: [String: NSColor]) {
            parser.syntaxHighlights = highlights
            
            // Re-parse existing content to apply new highlights
            if let session = session, !session.rawOutput.isEmpty {
                textView?.textStorage?.setAttributedString(NSAttributedString())
                append(session.rawOutput)
            }
        }

        func append(_ text: String) {
            guard let textView else { return }
            let attributed = parser.parse(text)
            textView.textStorage?.append(attributed)
            textView.scrollToEndOfDocument(nil)
        }
    }
}
