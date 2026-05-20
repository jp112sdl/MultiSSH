import Foundation

@Observable
final class SSHSession: Identifiable {
    let id = UUID()
    let connection: SSHConnection
    var isConnected = false
    var isActive = true

    @ObservationIgnored var onNewOutput: ((String) -> Void)?
    @ObservationIgnored private(set) var rawOutput = ""

    @ObservationIgnored private var process: Process?
    @ObservationIgnored private var stdinPipe: Pipe?

    init(connection: SSHConnection) {
        self.connection = connection
    }

    func connect() {
        guard process == nil else { return }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")

        var args: [String] = [
            "-tt",
            "-p", "\(connection.port)",
            "-o", "StrictHostKeyChecking=accept-new",
            "-o", "ConnectTimeout=10",
            "-o", "ServerAliveInterval=30"
        ]
        if connection.useKeyAuth && !connection.identityFile.isEmpty {
            args += ["-i", connection.identityFile]
        }
        args.append("\(connection.username)@\(connection.host)")
        proc.arguments = args

        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"

        var askpassURL: URL?
        if !connection.useKeyAuth && !connection.password.isEmpty {
            let url = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("mssh_\(UUID().uuidString).sh")
            let escaped = connection.password.replacingOccurrences(of: "'", with: "'\\''")
            try? "#!/bin/sh\necho '\(escaped)'\n".write(to: url, atomically: true, encoding: .utf8)
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
            env["SSH_ASKPASS"] = url.path
            env["SSH_ASKPASS_REQUIRE"] = "force"
            env["DISPLAY"] = "dummy"
            askpassURL = url
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
                if self?.isConnected == false { self?.isConnected = true }
                self?.append(text)
            }
        }

        stderr.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            let text = String(data: data, encoding: .utf8) ?? ""
            DispatchQueue.main.async { [weak self] in
                self?.append(text)
            }
        }

        proc.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.isConnected = false
                self?.append("\r\n[Disconnected]\r\n")
                self?.process = nil
                self?.stdinPipe = nil
            }
        }

        append("[Connecting to \(connection.username)@\(connection.host):\(connection.port)...]\r\n")

        do {
            try proc.run()
        } catch {
            append("[Failed to launch ssh: \(error.localizedDescription)]\r\n")
        }

        if let url = askpassURL {
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    func disconnect() {
        process?.terminate()
        process = nil
        stdinPipe = nil
        if isConnected {
            isConnected = false
            append("\r\n[Disconnected]\r\n")
        }
    }

    func send(_ text: String) {
        guard let pipe = stdinPipe, let data = text.data(using: .utf8) else { return }
        pipe.fileHandleForWriting.write(data)
    }

    private func append(_ text: String) {
        rawOutput += text
        onNewOutput?(text)
    }

    deinit {
        process?.terminate()
    }
}
