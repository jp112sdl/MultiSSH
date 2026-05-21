import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

// MARK: - Transferable Connection ID

struct TransferableConnectionID: Codable, Transferable {
    let id: String
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

// MARK: - Main View

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SSHConnection.name) private var connections: [SSHConnection]
    @Query(sort: \ConnectionFolder.sortOrder) private var folders: [ConnectionFolder]
    @State private var manager = ConnectionManager()
    @State private var showAddConnection = false
    @State private var showAddFolder = false
    @State private var editingConnection: SSHConnection?
    @State private var editingFolder: ConnectionFolder?
    @State private var terminalHeight: CGFloat = 260
    @State private var terminalWidth: CGFloat = 380
    @State private var syncResize = true
    @State private var fontSize: CGFloat = 11
    @State private var collapsedFolders: Set<PersistentIdentifier> = []
    @State private var showSyntaxSettings = false
    @State private var dropTargetFolder: ConnectionFolder?
    @State private var isDropTargetingUnfoldered = false

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: syncResize ? terminalWidth : 380), spacing: 8)]
    }
    
    // Organize connections by folder
    private var unfoldered: [SSHConnection] {
        connections.filter { $0.folder == nil }
    }
    
    private func isFolderCollapsed(_ folder: ConnectionFolder) -> Bool {
        collapsedFolders.contains(folder.id)
    }
    
    private func toggleFolderCollapse(_ folder: ConnectionFolder) {
        if collapsedFolders.contains(folder.id) {
            collapsedFolders.remove(folder.id)
        } else {
            collapsedFolders.insert(folder.id)
        }
    }
    
    // Helper to handle connection drops
    private func handleDrop(items: [TransferableConnectionID], targetFolder: ConnectionFolder?) -> Bool {
        guard let transferableID = items.first else { return false }
        
        // Find the connection in our list by comparing ID descriptions
        if let connection = connections.first(where: { $0.id.hashValue.description == transferableID.id }) {
            connection.folder = targetFolder
            try? modelContext.save()
        }
        
        return true
    }
    
    // Helper to connect all connections in a folder
    private func connectAll(in folder: ConnectionFolder) {
        for connection in folder.connections {
            if manager.session(for: connection) == nil {
                manager.connect(connection)
            }
        }
    }
    
    // Helper to disconnect all connections in a folder
    private func disconnectAll(in folder: ConnectionFolder) {
        for connection in folder.connections {
            if manager.session(for: connection) != nil {
                manager.disconnect(connection)
            }
        }
    }
    
    // Check if any connection in folder is connected
    private func hasConnectedSessions(in folder: ConnectionFolder) -> Bool {
        folder.connections.contains { manager.session(for: $0) != nil }
    }
    
    // Check if all connections in folder are connected
    private func allConnected(in folder: ConnectionFolder) -> Bool {
        !folder.connections.isEmpty && folder.connections.allSatisfy { manager.session(for: $0) != nil }
    }

    var body: some View {
        NavigationSplitView {
            List {
                // Unfoldered connections
                if !unfoldered.isEmpty {
                    Section {
                        ForEach(unfoldered) { connection in
                            ConnectionRowView(
                                connection: connection,
                                isConnected: manager.session(for: connection) != nil,
                                onConnect: { manager.connect(connection) },
                                onDisconnect: { manager.disconnect(connection) },
                                onEdit: { editingConnection = connection },
                                onDelete: {
                                    manager.disconnect(connection)
                                    connection.deletePassword()
                                    modelContext.delete(connection)
                                }
                            )
                        }
                    }
                    .listRowBackground(isDropTargetingUnfoldered ? Color.accentColor.opacity(0.2) : nil)
                    .dropDestination(for: TransferableConnectionID.self) { items, location in
                        handleDrop(items: items, targetFolder: nil)
                    } isTargeted: { isTargeted in
                        isDropTargetingUnfoldered = isTargeted
                    }
                } else if !folders.isEmpty {
                    // Show a drop zone when there are no unfoldered connections
                    Section {
                        Text("Drop here to remove from folder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .listRowBackground(isDropTargetingUnfoldered ? Color.accentColor.opacity(0.2) : nil)
                    .dropDestination(for: TransferableConnectionID.self) { items, location in
                        handleDrop(items: items, targetFolder: nil)
                    } isTargeted: { isTargeted in
                        isDropTargetingUnfoldered = isTargeted
                    }
                }
                
                // Folders with their connections
                ForEach(folders) { folder in
                    Section {
                        if !isFolderCollapsed(folder) {
                            ForEach(folder.connections.sorted(by: { $0.name < $1.name })) { connection in
                                ConnectionRowView(
                                    connection: connection,
                                    isConnected: manager.session(for: connection) != nil,
                                    onConnect: { manager.connect(connection) },
                                    onDisconnect: { manager.disconnect(connection) },
                                    onEdit: { editingConnection = connection },
                                    onDelete: {
                                        manager.disconnect(connection)
                                        connection.deletePassword()
                                        modelContext.delete(connection)
                                    }
                                )
                            }
                        }
                    } header: {
                        HStack {
                            Button {
                                toggleFolderCollapse(folder)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: isFolderCollapsed(folder) ? "chevron.right" : "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Circle()
                                        .fill(folder.color)
                                        .frame(width: 8, height: 8)
                                    Text(folder.name)
                                        .font(.headline)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            // Connect/Disconnect All buttons
                            if !folder.connections.isEmpty {
                                if hasConnectedSessions(in: folder) {
                                    Button {
                                        disconnectAll(in: folder)
                                    } label: {
                                        Image(systemName: "stop.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Disconnect all sessions in this folder")
                                }
                                
                                if !allConnected(in: folder) {
                                    Button {
                                        connectAll(in: folder)
                                    } label: {
                                        Image(systemName: "play.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                    .buttonStyle(.plain)
                                    .help("Connect all servers in this folder")
                                }
                            }
                            
                            Button {
                                editingFolder = folder
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(dropTargetFolder?.id == folder.id ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(4)
                        .contextMenu {
                            Button(isFolderCollapsed(folder) ? "Expand" : "Collapse") {
                                toggleFolderCollapse(folder)
                            }
                            Divider()
                            
                            if !folder.connections.isEmpty {
                                Button {
                                    connectAll(in: folder)
                                } label: {
                                    Label("Connect All", systemImage: "play.circle.fill")
                                }
                                .disabled(allConnected(in: folder))
                                
                                Button {
                                    disconnectAll(in: folder)
                                } label: {
                                    Label("Disconnect All", systemImage: "stop.circle.fill")
                                }
                                .disabled(!hasConnectedSessions(in: folder))
                                
                                Divider()
                            }
                            
                            Button("Edit Folder") { editingFolder = folder }
                            Divider()
                            Button("Delete Folder", role: .destructive) {
                                // Remove folder reference from connections
                                for connection in folder.connections {
                                    connection.folder = nil
                                }
                                modelContext.delete(folder)
                            }
                        }
                    }
                    .dropDestination(for: TransferableConnectionID.self) { items, location in
                        handleDrop(items: items, targetFolder: folder)
                    } isTargeted: { isTargeted in
                        if isTargeted {
                            dropTargetFolder = folder
                        } else if dropTargetFolder?.id == folder.id {
                            dropTargetFolder = nil
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 210, ideal: 280)
            .navigationTitle("Connections")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        showSyntaxSettings = true
                    } label: {
                        Image(systemName: "paintbrush")
                    }
                    .help("Syntax highlighting settings")
                    
                    Menu {
                        Button {
                            showAddConnection = true
                        } label: {
                            Label("New Connection", systemImage: "server.rack")
                        }
                        Button {
                            showAddFolder = true
                        } label: {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }
                        Divider()
                        Button {
                            showSyntaxSettings = true
                        } label: {
                            Label("Syntax Highlighting", systemImage: "paintbrush")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        } detail: {
            VStack(spacing: 0) {
                if manager.sessions.isEmpty {
                    ContentUnavailableView(
                        "No Active Connections",
                        systemImage: "terminal",
                        description: Text("Connect to a server from the sidebar to get started")
                    )
                } else {
                    // Toolbar for sync resize control
                    HStack {
                        Toggle("Sync resize", isOn: $syncResize)
                            .toggleStyle(.checkbox)
                            .font(.caption)
                            .help("Resize all terminal windows together")
                        
                        if syncResize {
                            Text("W:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $terminalWidth, in: 300...800, step: 10)
                                .frame(width: 100)
                            Text("\(Int(terminalWidth))px")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 45, alignment: .leading)
                            
                            Text("H:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Slider(value: $terminalHeight, in: 200...800, step: 10)
                                .frame(width: 100)
                            Text("\(Int(terminalHeight))px")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 45, alignment: .leading)
                        }
                        
                        Divider()
                            .frame(height: 16)
                        
                        Text("Font:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $fontSize, in: 8...24, step: 1)
                            .frame(width: 100)
                        Text("\(Int(fontSize))pt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 35, alignment: .leading)
                        Button {
                            fontSize = 11
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .help("Reset font size to 11pt")
                        
                        Divider()
                            .frame(height: 16)
                        
                        Button {
                            showSyntaxSettings = true
                        } label: {
                            Image(systemName: "paintbrush")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .help("Syntax highlighting settings")
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(manager.sessions) { session in
                                TerminalPaneView(
                                    session: session,
                                    width: syncResize ? $terminalWidth : .constant(terminalWidth),
                                    height: syncResize ? $terminalHeight : .constant(terminalHeight),
                                    fontSize: fontSize,
                                    syntaxHighlights: manager.syntaxHighlights,
                                    onDisconnect: {
                                        manager.disconnect(session.connection)
                                    }
                                )
                            }
                        }
                        .padding(8)
                    }
                }

                if !manager.sessions.isEmpty {
                    BroadcastInputView(manager: manager)
                }
            }
        }
        .sheet(isPresented: $showAddConnection) {
            AddConnectionView(folders: folders) { conn in
                modelContext.insert(conn)
            }
        }
        .sheet(item: $editingConnection) { connection in
            EditConnectionView(connection: connection, folders: folders)
        }
        .sheet(isPresented: $showAddFolder) {
            AddFolderView { folder in
                modelContext.insert(folder)
            }
        }
        .sheet(item: $editingFolder) { folder in
            EditFolderView(folder: folder)
        }
        .sheet(isPresented: $showSyntaxSettings) {
            SyntaxHighlightSettingsView(manager: manager)
        }
    }
}

// MARK: - Connection Row

struct ConnectionRowView: View {
    let connection: SSHConnection
    let isConnected: Bool
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Circle()
                    .fill(isConnected ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: 8, height: 8)
                Text(connection.name)
                    .fontWeight(.medium)
                Spacer()
                if isConnected {
                    Button("Disconnect", action: onDisconnect)
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Button("Connect", action: onConnect)
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }
            Text("\(connection.username)@\(connection.host):\(connection.port)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button("Edit", action: onEdit)
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        }
        .draggable(TransferableConnectionID(id: connection.id.hashValue.description)) {
            // Preview view shown while dragging
            Label(connection.name, systemImage: "server.rack")
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
        }
    }
}

// MARK: - Terminal Pane

struct TerminalPaneView: View {
    @Bindable var session: SSHSession
    @Binding var width: CGFloat
    @Binding var height: CGFloat
    var fontSize: CGFloat = 11
    var syntaxHighlights: [String: NSColor] = [:]
    let onDisconnect: () -> Void
    
    @State private var isDraggingHeight = false
    @State private var isDraggingWidth = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(session.isConnected ? Color.green : Color.red)
                        .frame(width: 7, height: 7)
                    Text(session.connection.name)
                        .font(.caption.bold())
                    Text(session.connection.host)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Toggle("Sync", isOn: $session.isActive)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                        .help("Include this session in broadcast input")
                    Button {
                        onDisconnect()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(NSColor.windowBackgroundColor))

                Divider()

                TerminalView(session: session, fontSize: fontSize, syntaxHighlights: syntaxHighlights)
                    .frame(width: width, height: height)
                
                // Bottom resize handle
                HStack {
                    Spacer()
                    Image(systemName: "chevron.compact.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(height: 8)
                .background(isDraggingHeight ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDraggingHeight = true
                            let newHeight = height + value.translation.height
                            height = max(200, min(800, newHeight))
                        }
                        .onEnded { _ in
                            isDraggingHeight = false
                        }
                )
                .onHover { hovering in
                    if hovering {
                        NSCursor.resizeUpDown.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            
            // Right resize handle
            VStack {
                Spacer()
                Image(systemName: "chevron.compact.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(width: 8)
            .background(isDraggingWidth ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDraggingWidth = true
                        let newWidth = width + value.translation.width
                        width = max(300, min(800, newWidth))
                    }
                    .onEnded { _ in
                        isDraggingWidth = false
                    }
            )
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    session.isActive ? Color.accentColor.opacity(0.5) : Color(NSColor.separatorColor),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Broadcast Input Bar

struct BroadcastInputView: View {
    let manager: ConnectionManager
    @State private var command = ""
    @State private var instantMode = false
    @State private var commandHistory: [String] = []
    @State private var historyIndex: Int?
    @State private var temporaryCommand = ""
    @State private var showHistory = false
    @FocusState private var focused: Bool

    private var activeCount: Int {
        manager.sessions.filter { $0.isActive && $0.isConnected }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Command history popover
            if showHistory && !commandHistory.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Command History")
                            .font(.caption.bold())
                        Spacer()
                        Button {
                            commandHistory.removeAll()
                            showHistory = false
                        } label: {
                            Text("Clear")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 1) {
                            ForEach(Array(commandHistory.enumerated().reversed()), id: \.offset) { index, cmd in
                                Button {
                                    command = cmd
                                    showHistory = false
                                    focused = true
                                } label: {
                                    HStack {
                                        Text("\(commandHistory.count - index).")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 30, alignment: .trailing)
                                        Text(cmd)
                                            .font(.system(.caption, design: .monospaced))
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .background(
                                    historyIndex == index ? Color.accentColor.opacity(0.2) : Color.clear
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .frame(width: 400)
                .background(Color(NSColor.windowBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
                .shadow(radius: 8)
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Main input row
            HStack(spacing: 8) {
                Image(systemName: instantMode ? "bolt.fill" : "arrow.right.to.line")
                    .foregroundStyle(activeCount > 0 ? (instantMode ? .orange : .green) : .secondary)
                    .frame(width: 16)

                TextField("Broadcast to \(activeCount) session(s)...", text: $command)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .focused($focused)
                    .onSubmit {
                        if !instantMode {
                            sendCommand()
                        }
                    }
                    .onChange(of: command) { oldValue, newValue in
                        // If user starts typing, exit history navigation
                        if historyIndex != nil && newValue != commandHistory[safe: historyIndex ?? 0] {
                            historyIndex = nil
                        }
                    }
                    .onKeyPress(.upArrow) {
                        if !instantMode {
                            navigateHistory(direction: .up)
                            return .handled
                        }
                        return .ignored
                    }
                    .onKeyPress(.downArrow) {
                        if !instantMode {
                            navigateHistory(direction: .down)
                            return .handled
                        }
                        return .ignored
                    }
                    .onKeyPress { press in
                        if instantMode && activeCount > 0 {
                            // Handle special keys
                            if press.key == .delete {
                                manager.broadcast("\u{7F}")
                            } else if press.key == .return {
                                manager.broadcast("\n")
                            } else if press.key == .tab {
                                manager.broadcast("\t")
                            } else if press.key == .escape {
                                manager.broadcast("\u{1B}")
                            } else if !press.characters.isEmpty {
                                // Handle regular characters
                                manager.broadcast(press.characters)
                            }
                        }
                        return .ignored // Let the text field update normally
                    }

                if !instantMode {
                    Button("Send") { sendCommand() }
                        .disabled(command.isEmpty || activeCount == 0)
                        .keyboardShortcut(.return, modifiers: [])
                }
                
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        showHistory.toggle()
                    }
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .help("Command history (\(commandHistory.count)/50)")
                .disabled(commandHistory.isEmpty)

                Divider().frame(height: 16)

                Button("^C") {
                    manager.broadcast("\u{03}")
                    if instantMode { command = "" }
                }
                .foregroundStyle(.red)
                .help("Send Ctrl+C (interrupt) to active sessions")

                Button("^D") {
                    manager.broadcast("\u{04}")
                    if instantMode { command = "" }
                }
                .foregroundStyle(.orange)
                .help("Send Ctrl+D (EOF) to active sessions")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Instant mode toggle
            HStack {
                Toggle("Instant transmission (keystrokes sent immediately)", isOn: $instantMode)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .onChange(of: instantMode) { _, _ in
                        if instantMode {
                            command = ""
                        }
                    }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color(NSColor.separatorColor)),
            alignment: .top
        )
        .onAppear { 
            focused = true
            loadHistory()
        }
    }

    private func sendCommand() {
        guard !command.isEmpty else { return }
        
        // Add to history (avoid duplicates of the last command)
        if commandHistory.last != command {
            commandHistory.append(command)
            // Keep only last 50 commands
            if commandHistory.count > 50 {
                commandHistory.removeFirst()
            }
            saveHistory()
        }
        
        manager.broadcast(command + "\n")
        command = ""
        historyIndex = nil
        temporaryCommand = ""
    }
    
    private enum NavigationDirection {
        case up, down
    }
    
    private func navigateHistory(direction: NavigationDirection) {
        guard !commandHistory.isEmpty else { return }
        
        // Save current command if entering history for the first time
        if historyIndex == nil {
            temporaryCommand = command
        }
        
        switch direction {
        case .up:
            if let current = historyIndex {
                if current < commandHistory.count - 1 {
                    historyIndex = current + 1
                }
            } else {
                historyIndex = 0
            }
        case .down:
            if let current = historyIndex {
                if current > 0 {
                    historyIndex = current - 1
                } else {
                    // Back to the temporary command
                    historyIndex = nil
                    command = temporaryCommand
                    return
                }
            }
        }
        
        if let index = historyIndex {
            command = commandHistory[commandHistory.count - 1 - index]
        }
    }
    
    private func saveHistory() {
        UserDefaults.standard.set(commandHistory, forKey: "CommandHistory")
    }
    
    private func loadHistory() {
        if let saved = UserDefaults.standard.array(forKey: "CommandHistory") as? [String] {
            commandHistory = Array(saved.suffix(50))
        }
    }
}

// Helper extension for safe array access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Add Connection Sheet

struct AddConnectionView: View {
    let folders: [ConnectionFolder]
    let onSave: (SSHConnection) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var host = ""
    @State private var port = "22"
    @State private var username = ""
    @State private var useKeyAuth = true
    @State private var identityFile = ""
    @State private var password = ""
    @State private var selectedFolder: ConnectionFolder?

    var body: some View {
        Form {
            Section("Connection") {
                TextField("Display Name", text: $name)
                TextField("Hostname or IP", text: $host)
                    .onChange(of: host) {
                        if name.isEmpty { name = host }
                    }
                TextField("Port", text: $port)
                TextField("Username", text: $username)
            }
            
            Section("Organization") {
                Picker("Folder", selection: $selectedFolder) {
                    Text("None").tag(nil as ConnectionFolder?)
                    ForEach(folders) { folder in
                        HStack {
                            Circle()
                                .fill(folder.color)
                                .frame(width: 8, height: 8)
                            Text(folder.name)
                        }
                        .tag(folder as ConnectionFolder?)
                    }
                }
            }

            Section("Authentication") {
                Picker("Method", selection: $useKeyAuth) {
                    Text("SSH Key / Agent").tag(true)
                    Text("Password").tag(false)
                }
                .pickerStyle(.segmented)

                if useKeyAuth {
                    HStack {
                        TextField("Identity file (leave blank for default/agent)", text: $identityFile)
                        Button("Browse…") { browseForKey() }
                    }
                } else {
                    SecureField("Password", text: $password)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 450)
        .navigationTitle("Add Connection")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") { save() }
                    .disabled(host.isEmpty || username.isEmpty)
            }
        }
    }

    private func browseForKey() {
        let panel = NSOpenPanel()
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            identityFile = panel.url?.path ?? ""
        }
    }

    private func save() {
        let conn = SSHConnection(
            name: name.isEmpty ? host : name,
            host: host,
            port: Int(port) ?? 22,
            username: username,
            useKeyAuth: useKeyAuth,
            identityFile: identityFile,
            password: password,
            folder: selectedFolder
        )
        onSave(conn)
        dismiss()
    }
}
// MARK: - Edit Connection Sheet

struct EditConnectionView: View {
    @Bindable var connection: SSHConnection
    let folders: [ConnectionFolder]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Connection") {
                TextField("Display name", text: $connection.name)
                TextField("Hostname or IP", text: $connection.host)
                TextField("Port", value: $connection.port, format: .number)
                TextField("Username", text: $connection.username)
            }
            
            Section("Organization") {
                Picker("Folder", selection: $connection.folder) {
                    Text("None").tag(nil as ConnectionFolder?)
                    ForEach(folders) { folder in
                        HStack {
                            Circle()
                                .fill(folder.color)
                                .frame(width: 8, height: 8)
                            Text(folder.name)
                        }
                        .tag(folder as ConnectionFolder?)
                    }
                }
            }

            Section("Authentication") {
                Picker("Method", selection: $connection.useKeyAuth) {
                    Text("SSH Key / Agent").tag(true)
                    Text("Password").tag(false)
                }
                .pickerStyle(.segmented)

                if connection.useKeyAuth {
                    HStack {
                        TextField("Identity file (leave blank for default/agent)", text: $connection.identityFile)
                        Button("Browse…") { browseForKey() }
                    }
                } else {
                    SecureField("Password", text: $connection.password)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 370)
        .navigationTitle("Edit: \(connection.name)")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func browseForKey() {
        let panel = NSOpenPanel()
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            connection.identityFile = panel.url?.path ?? ""
        }
    }
}

// MARK: - Add Folder Sheet

struct AddFolderView: View {
    let onSave: (ConnectionFolder) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var colorHex = "#3B82F6"
    
    private let availableColors: [(String, String)] = [
        ("Blue", "#3B82F6"),
        ("Green", "#10B981"),
        ("Red", "#EF4444"),
        ("Yellow", "#F59E0B"),
        ("Purple", "#8B5CF6"),
        ("Pink", "#EC4899"),
        ("Orange", "#F97316"),
        ("Cyan", "#06B6D4"),
    ]
    
    var body: some View {
        Form {
            Section("Folder Details") {
                TextField("Name", text: $name)
                
                Picker("Color", selection: $colorHex) {
                    ForEach(availableColors, id: \.1) { colorName, hex in
                        HStack {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 12, height: 12)
                            Text(colorName)
                        }
                        .tag(hex)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 200)
        .navigationTitle("New Folder")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    let folder = ConnectionFolder(name: name.isEmpty ? "New Folder" : name, colorHex: colorHex)
                    onSave(folder)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Edit Folder Sheet

struct EditFolderView: View {
    @Bindable var folder: ConnectionFolder
    @Environment(\.dismiss) private var dismiss
    
    private let availableColors: [(String, String)] = [
        ("Blue", "#3B82F6"),
        ("Green", "#10B981"),
        ("Red", "#EF4444"),
        ("Yellow", "#F59E0B"),
        ("Purple", "#8B5CF6"),
        ("Pink", "#EC4899"),
        ("Orange", "#F97316"),
        ("Cyan", "#06B6D4"),
    ]
    
    var body: some View {
        Form {
            Section("Folder Details") {
                TextField("Name", text: $folder.name)
                
                Picker("Color", selection: $folder.colorHex) {
                    ForEach(availableColors, id: \.1) { colorName, hex in
                        HStack {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 12, height: 12)
                            Text(colorName)
                        }
                        .tag(hex)
                    }
                }
            }
            
            Section("Connections") {
                Text("\(folder.connections.count) connection(s)")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 220)
        .navigationTitle("Edit Folder")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SSHConnection.self, inMemory: true)
}
