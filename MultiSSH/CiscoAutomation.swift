import Foundation
import AppKit
import UniformTypeIdentifiers

// MARK: - Cisco Config Downloader

@Observable
final class CiscoConfigDownloader {

    enum State {
        case idle
        case connecting
        case disablingPager
        case downloading
        case done
        case failed(String)
    }

    var state: State = .idle
    var statusMessage: String = ""
    var configOutput: String = ""
    /// All raw SSH output accumulated for display in the live view
    var liveOutput: String = ""

    private var process: Process?
    private var stdinPipe: Pipe?
    /// Buffer for the current state's output (reset on each state transition)
    private var stateBuf: String = ""
    /// Timeout timer: advance state if prompt not seen within N seconds
    private var timeoutTimer: Timer?
    private var connectionName: String = ""

    var isRunning: Bool {
        switch state {
        case .idle, .done, .failed: return false
        default: return true
        }
    }

    // MARK: - Public API

    func start(connection: SSHConnection) {
        guard !isRunning else { return }
        connectionName = connection.name
        reset()
        state = .connecting
        statusMessage = "Verbinde mit \(connection.host)..."
        appendLog("▶ Starte Verbindung zu \(connection.effectiveUsername)@\(connection.host):\(connection.port)")

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")

        let username = connection.effectiveUsername
        let useKeyAuth = connection.effectiveUseKeyAuth
        let identityFile = connection.effectiveIdentityFile
        let password = connection.effectivePassword

        var args: [String] = [
            "-tt",
            "-p", "\(connection.port)",
            "-o", "StrictHostKeyChecking=accept-new",
            "-o", "ConnectTimeout=15",
            "-o", "ServerAliveInterval=30",
            "-o", "LogLevel=ERROR"
        ]
        if useKeyAuth && !identityFile.isEmpty {
            args += ["-i", identityFile]
        }
        args.append("\(username)@\(connection.host)")
        proc.arguments = args
        appendLog("  SSH-Argumente: \(args.joined(separator: " "))")

        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "vt100"

        var askpassURL: URL?
        if !useKeyAuth && !password.isEmpty {
            let url = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("cisco_\(UUID().uuidString).sh")
            let escaped = password.replacingOccurrences(of: "'", with: "'\\''")
            try? "#!/bin/sh\necho '\(escaped)'\n".write(to: url, atomically: true, encoding: .utf8)
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
            env["SSH_ASKPASS"] = url.path
            env["SSH_ASKPASS_REQUIRE"] = "force"
            env["DISPLAY"] = "dummy"
            askpassURL = url
            appendLog("  Passwort-Auth via SSH_ASKPASS")
        } else if useKeyAuth {
            appendLog("  Key-Auth\(identityFile.isEmpty ? " (Agent/Standard)" : ": \(identityFile)")")
        }
        proc.environment = env

        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()
        proc.standardInput = stdin
        proc.standardOutput = stdout
        proc.standardError = stderr
        stdinPipe = stdin
        process = proc

        stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1) ?? ""
            DispatchQueue.main.async { [weak self] in
                self?.handleOutput(text, isStderr: false)
            }
        }

        stderr.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            let text = String(data: data, encoding: .utf8) ?? ""
            DispatchQueue.main.async { [weak self] in
                self?.handleOutput(text, isStderr: true)
            }
        }

        proc.terminationHandler = { [weak self] p in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.cancelTimeout()
                switch self.state {
                case .downloading:
                    self.appendLog("  Prozess beendet – verarbeite gesammelte Ausgabe")
                    self.finalize()
                case .connecting, .disablingPager:
                    self.fail("SSH-Verbindung unerwartet beendet (Exit-Code \(p.terminationStatus))")
                default:
                    break
                }
                self.process = nil
                self.stdinPipe = nil
            }
        }

        do {
            try proc.run()
            appendLog("  SSH-Prozess gestartet (PID \(proc.processIdentifier))")
            scheduleTimeout(seconds: 20, action: { [weak self] in
                self?.appendLog("⚠ Timeout: Kein Prompt erkannt – sende Befehle trotzdem")
                self?.advanceFromConnecting()
            })
        } catch {
            fail("SSH konnte nicht gestartet werden: \(error.localizedDescription)")
        }

        if let url = askpassURL {
            DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    func cancel() {
        cancelTimeout()
        process?.terminate()
        process = nil
        stdinPipe = nil
        state = .idle
        statusMessage = ""
        appendLog("✖ Abgebrochen")
    }

    func saveToFile(suggestedName: String = "running-config.txt") {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = suggestedName
        panel.message = "Running Config speichern"
        if panel.runModal() == .OK, let url = panel.url {
            try? configOutput.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Output handling

    private func handleOutput(_ text: String, isStderr: Bool) {
        // Always show raw output in live view
        let cleaned = cleanForDisplay(text)
        if !cleaned.isEmpty {
            liveOutput += cleaned
        }

        if isStderr {
            // Show stderr as event (SSH error messages etc.)
            let stripped = stripANSI(text).trimmingCharacters(in: .whitespacesAndNewlines)
            if !stripped.isEmpty {
                appendLog("  [stderr] \(stripped)")
            }
            return
        }

        stateBuf += text

        switch state {
        case .connecting:
            cancelTimeout()
            if looksLikePrompt(stateBuf) {
                advanceFromConnecting()
            } else {
                // Re-schedule timeout if still receiving data
                scheduleTimeout(seconds: 8, action: { [weak self] in
                    self?.appendLog("⚠ Timeout nach letzter Ausgabe – sende Befehle trotzdem")
                    self?.advanceFromConnecting()
                })
            }
        case .disablingPager:
            if looksLikePrompt(stateBuf) {
                cancelTimeout()
                advanceToDownloading()
            }
        case .downloading:
            if hasConfigEnd(stateBuf) {
                cancelTimeout()
                finalize()
                send("exit\n")
            }
        default:
            break
        }
    }

    // MARK: - State transitions

    private func advanceFromConnecting() {
        guard case .connecting = state else { return }
        cancelTimeout()
        state = .disablingPager
        statusMessage = "Deaktiviere Pager (terminal length 0)..."
        stateBuf = ""
        appendLog("✔ Prompt erkannt – sende: terminal length 0")
        send("terminal length 0\n")
        scheduleTimeout(seconds: 10, action: { [weak self] in
            self?.appendLog("⚠ Timeout nach terminal length 0 – sende show running-config")
            self?.advanceToDownloading()
        })
    }

    private func advanceToDownloading() {
        guard case .disablingPager = state else { return }
        cancelTimeout()
        state = .downloading
        statusMessage = "Lade Running-Config..."
        stateBuf = ""
        appendLog("✔ Bereit – sende: show running-config")
        send("show running-config\n")
        scheduleTimeout(seconds: 60, action: { [weak self] in
            self?.appendLog("⚠ Timeout beim Download – verarbeite bisherige Ausgabe")
            self?.finalize()
            self?.send("exit\n")
        })
    }

    private func finalize() {
        guard case .downloading = state else { return }
        cancelTimeout()
        let raw = stripANSI(stateBuf)
        let cleaned = cleanConfigOutput(raw)
        configOutput = cleaned
        let lineCount = cleaned.components(separatedBy: .newlines).filter { !$0.isEmpty }.count
        state = .done
        statusMessage = "✔ Fertig – \(lineCount) Zeilen"
        appendLog("✔ Running-Config empfangen: \(lineCount) Zeilen")
    }

    private func fail(_ message: String) {
        cancelTimeout()
        state = .failed(message)
        statusMessage = message
        appendLog("✖ Fehler: \(message)")
    }

    // MARK: - Helpers

    private func looksLikePrompt(_ text: String) -> Bool {
        let stripped = stripANSI(text)
        let lines = stripped.components(separatedBy: CharacterSet.newlines)
        for line in lines.reversed() {
            let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty { continue }
            if t.hasSuffix("#") || t.hasSuffix(">") { return true }
        }
        return false
    }

    private func hasConfigEnd(_ text: String) -> Bool {
        let stripped = stripANSI(text)
        let lines = stripped.components(separatedBy: CharacterSet.newlines)
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if t == "end" { return true }
        }
        return false
    }

    private func cleanConfigOutput(_ text: String) -> String {
        var lines = text.components(separatedBy: "\n")
        // Drop everything up to and including the echoed "show running-config" line
        if let idx = lines.firstIndex(where: { $0.contains("show running-config") }) {
            lines = Array(lines.dropFirst(idx + 1))
        }
        // Keep only up to and including the final "end" line
        if let endIdx = lines.lastIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "end" }) {
            lines = Array(lines.prefix(endIdx + 1))
        }
        // Clean up carriage returns
        return lines.map { $0.replacingOccurrences(of: "\r", with: "") }.joined(separator: "\n")
    }

    private func cleanForDisplay(_ text: String) -> String {
        var s = text
        // Normalize line endings
        s = s.replacingOccurrences(of: "\r\n", with: "\n")
        s = s.replacingOccurrences(of: "\r", with: "\n")
        // Strip ANSI escape sequences
        s = stripANSI(s)
        return s
    }

    private func stripANSI(_ text: String) -> String {
        // Covers CSI sequences, OSC sequences, and standalone ESC codes
        let pattern = "\u{1B}\\[[0-9;]*[A-Za-z]|\u{1B}[()][A-Za-z0-9]|\u{1B}[A-Za-z]|\u{1B}\\][^\u{1B}\\a]*[\u{1B}\\a]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
    }

    private func send(_ text: String) {
        guard let pipe = stdinPipe, let data = text.data(using: .utf8) else { return }
        pipe.fileHandleForWriting.write(data)
    }

    private func appendLog(_ message: String) {
        let ts = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        liveOutput += "[\(ts)] \(message)\n"
    }

    private func reset() {
        state = .idle
        statusMessage = ""
        configOutput = ""
        liveOutput = ""
        stateBuf = ""
        cancelTimeout()
    }

    // MARK: - Timeout

    private func scheduleTimeout(seconds: TimeInterval, action: @escaping () -> Void) {
        cancelTimeout()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
            action()
        }
    }

    private func cancelTimeout() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
}
