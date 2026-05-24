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
    @State private var detailViewSize: CGSize = .zero
    @State private var showCredentialManager = false
    @State private var ciscoConfigConnection: SSHConnection?
    @Environment(LanguageSettings.self) private var lang

    private var columns: [GridItem] {
        let count = manager.sessions.count
        guard count > 0 else { return [GridItem(.flexible())] }
        
        // Calculate optimal grid layout
        let cols = Int(ceil(sqrt(Double(count))))
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: cols)
    }
    
    private func calculateDynamicSize() -> CGSize {
        let count = manager.sessions.count
        guard count > 0 else { return CGSize(width: 380, height: 260) }
        
        // Calculate grid dimensions
        let cols = Int(ceil(sqrt(Double(count))))
        let rows = Int(ceil(Double(count) / Double(cols)))
        
        // Account for padding and spacing
        let horizontalPadding: CGFloat = 16 // 8px on each side
        let verticalPadding: CGFloat = 16
        let spacing: CGFloat = 8
        
        let availableWidth = max(detailViewSize.width - horizontalPadding - (CGFloat(cols - 1) * spacing), 300)
        let availableHeight = max(detailViewSize.height - verticalPadding - (CGFloat(rows - 1) * spacing), 200)
        
        let width = availableWidth / CGFloat(cols)
        let height = availableHeight / CGFloat(rows)
        
        return CGSize(width: width, height: height)
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
    
    // Clone a connection
    private func cloneConnection(_ connection: SSHConnection) {
        let clonedConnection = SSHConnection(
            name: "\(connection.name) \(lang.s("Copy", "Kopie"))",
            host: connection.host,
            port: connection.port,
            username: connection.username,
            useKeyAuth: connection.useKeyAuth,
            identityFile: connection.identityFile,
            password: connection.password,
            folder: connection.folder
        )
        modelContext.insert(clonedConnection)
        try? modelContext.save()
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
                                onClone: { cloneConnection(connection) },
                                onDelete: {
                                    manager.disconnect(connection)
                                    connection.deletePassword()
                                    modelContext.delete(connection)
                                },
                                onCiscoConfig: connection.isCiscoDevice ? { ciscoConfigConnection = connection } : nil
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
                        Text(lang.s("Drop here to remove from folder", "Hierher ziehen, um aus Ordner zu entfernen"))
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
                                    onClone: { cloneConnection(connection) },
                                    onDelete: {
                                        manager.disconnect(connection)
                                        connection.deletePassword()
                                        modelContext.delete(connection)
                                    },
                                    onCiscoConfig: connection.isCiscoDevice ? { ciscoConfigConnection = connection } : nil
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
                                    .help(lang.s("Disconnect all sessions in this folder", "Alle Sitzungen dieses Ordners trennen"))
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
                                    .help(lang.s("Connect all servers in this folder", "Alle Server dieses Ordners verbinden"))
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
                            Button(isFolderCollapsed(folder) ? lang.s("Expand", "Ausklappen") : lang.s("Collapse", "Einklappen")) {
                                toggleFolderCollapse(folder)
                            }
                            Divider()
                            
                            if !folder.connections.isEmpty {
                                Button {
                                    connectAll(in: folder)
                                } label: {
                                    Label(lang.s("Connect All", "Alle verbinden"), systemImage: "play.circle.fill")
                                }
                                .disabled(allConnected(in: folder))
                                
                                Button {
                                    disconnectAll(in: folder)
                                } label: {
                                    Label(lang.s("Disconnect All", "Alle trennen"), systemImage: "stop.circle.fill")
                                }
                                .disabled(!hasConnectedSessions(in: folder))
                                
                                Divider()
                            }
                            
                            Button(lang.s("Edit Folder", "Ordner bearbeiten")) { editingFolder = folder }
                            Divider()
                            Button(lang.s("Delete Folder", "Ordner löschen"), role: .destructive) {
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
            .navigationTitle(lang.s("Connections", "Verbindungen"))
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        lang.toggle()
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "globe")
                                .font(.caption)
                            Text(lang.current.code)
                                .font(.caption.bold())
                        }
                    }
                    .help(lang.s("Switch to German", "Auf Englisch umschalten"))

                    Button {
                        showCredentialManager = true
                    } label: {
                        Image(systemName: "key.fill")
                    }
                    .help(lang.s("Credential manager", "Anmeldedaten-Manager"))
                    
                    Button {
                        showSyntaxSettings = true
                    } label: {
                        Image(systemName: "paintbrush")
                    }
                    .help(lang.s("Syntax highlighting settings", "Syntax-Hervorhebungseinstellungen"))
                    
                    Menu {
                        Button {
                            showAddConnection = true
                        } label: {
                            Label(lang.s("New Connection", "Neue Verbindung"), systemImage: "server.rack")
                        }
                        Button {
                            showAddFolder = true
                        } label: {
                            Label(lang.s("New Folder", "Neuer Ordner"), systemImage: "folder.badge.plus")
                        }
                        Divider()
                        Button {
                            showCredentialManager = true
                        } label: {
                            Label(lang.s("Manage Credentials", "Anmeldedaten verwalten"), systemImage: "key.fill")
                        }
                        Divider()
                        Button {
                            showSyntaxSettings = true
                        } label: {
                            Label(lang.s("Syntax Highlighting", "Syntax-Hervorhebung"), systemImage: "paintbrush")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        } detail: {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    if manager.sessions.isEmpty {
                        ContentUnavailableView(
                            lang.s("No Active Connections", "Keine aktiven Verbindungen"),
                            systemImage: "terminal",
                            description: Text(lang.s("Connect to a server from the sidebar to get started", "Verbinden Sie sich über die Seitenleiste mit einem Server"))
                        )
                    } else {
                        // Toolbar for sync resize control
                        HStack {
                            Toggle(lang.s("Auto-scale", "Auto-Skalierung"), isOn: $syncResize)
                                .toggleStyle(.checkbox)
                                .font(.caption)
                                .help(lang.s("Automatically scale terminals to fill available space", "Terminals automatisch auf den verfügbaren Platz skalieren"))
                            
                            if !syncResize {
                                Text("W:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Slider(value: $terminalWidth, in: 300...1024, step: 10)
                                    .frame(width: 100)
                                Text("\(Int(terminalWidth))px")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 45, alignment: .leading)
                                
                                Text("H:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Slider(value: $terminalHeight, in: 200...1024, step: 10)
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
                            .help(lang.s("Reset font size to 11pt", "Schriftgröße auf 11 Pt. zurücksetzen"))
                            
                            Divider()
                                .frame(height: 16)
                            
                            Button {
                                showSyntaxSettings = true
                            } label: {
                                Image(systemName: "paintbrush")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .help(lang.s("Syntax highlighting settings", "Syntax-Hervorhebungseinstellungen"))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        
                        Divider()
                        
                        ScrollView {
                            let dynamicSize = calculateDynamicSize()
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(manager.sessions) { session in
                                    TerminalPaneView(
                                        session: session,
                                        width: syncResize ? .constant(dynamicSize.width) : $terminalWidth,
                                        height: syncResize ? .constant(dynamicSize.height) : $terminalHeight,
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
                .onAppear {
                    detailViewSize = geometry.size
                }
                .onChange(of: geometry.size) { _, newSize in
                    detailViewSize = newSize
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
        .sheet(isPresented: $showCredentialManager) {
            CredentialManagerView()
        }
        .sheet(item: $ciscoConfigConnection) { connection in
            CiscoConfigSheet(connection: connection)
        }
    }
}

// MARK: - Cisco Config Sheet

struct CiscoConfigSheet: View {
    let connection: SSHConnection
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageSettings.self) private var lang
    @State private var downloader = CiscoConfigDownloader()
    @State private var showConfig = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "switch.2")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(connection.name)
                        .font(.headline)
                    Text(downloader.statusMessage.isEmpty ? lang.s("Starting...", "Starte...") : downloader.statusMessage)
                        .font(.caption)
                        .foregroundStyle(stateColor)
                }
                Spacer()
                if downloader.isRunning {
                    ProgressView()
                        .scaleEffect(0.75)
                }
                if case .done = downloader.state {
                    Picker("", selection: $showConfig) {
                        Label(lang.s("Log", "Protokoll"), systemImage: "terminal").tag(false)
                        Label(lang.s("Config", "Konfiguration"), systemImage: "doc.text").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Main content
            Group {
                if showConfig, case .done = downloader.state {
                    configView
                } else {
                    liveOutputView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Footer
            HStack {
                Button(lang.s("Close", "Schließen")) {
                    downloader.cancel()
                    dismiss()
                }

                Spacer()

                if case .failed = downloader.state {
                    Button(lang.s("Retry", "Wiederholen")) {
                        showConfig = false
                        downloader.start(connection: connection)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if case .done = downloader.state {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(downloader.configOutput, forType: .string)
                    } label: {
                        Label(lang.s("Copy Config", "Config kopieren"), systemImage: "doc.on.doc")
                    }

                    Button {
                        downloader.saveToFile(suggestedName: "\(connection.name)-running-config.txt")
                    } label: {
                        Label(lang.s("Save…", "Speichern…"), systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                } else if downloader.isRunning {
                    Button(lang.s("Cancel", "Abbrechen"), role: .destructive) {
                        downloader.cancel()
                    }
                }
            }
            .padding()
        }
        .frame(width: 760, height: 540)
        .onAppear {
            downloader.start(connection: connection)
        }
        .onChange(of: downloader.state.isDone) { _, done in
            if done { showConfig = true }
        }
    }

    // MARK: - Subviews

    private var liveOutputView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(downloader.liveOutput)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(NSColor.labelColor))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .id("bottom")
                    .textSelection(.enabled)
            }
            .background(Color(NSColor.textBackgroundColor))
            .onChange(of: downloader.liveOutput) { _, _ in
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    private var configView: some View {
        ScrollView {
            Text(downloader.configOutput)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color(NSColor.labelColor))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .textSelection(.enabled)
        }
        .background(Color(NSColor.textBackgroundColor))
    }

    private var stateColor: Color {
        switch downloader.state {
        case .done: return .green
        case .failed: return .red
        default: return .secondary
        }
    }
}

extension CiscoConfigDownloader.State {
    var isDone: Bool {
        if case .done = self { return true }
        return false
    }
}

// MARK: - Connection Row

struct ConnectionRowView: View {
    let connection: SSHConnection
    let isConnected: Bool
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    let onEdit: () -> Void
    let onClone: () -> Void
    let onDelete: () -> Void
    let onCiscoConfig: (() -> Void)?
    @Environment(LanguageSettings.self) private var lang

    init(connection: SSHConnection, isConnected: Bool,
         onConnect: @escaping () -> Void, onDisconnect: @escaping () -> Void,
         onEdit: @escaping () -> Void, onClone: @escaping () -> Void,
         onDelete: @escaping () -> Void, onCiscoConfig: (() -> Void)? = nil) {
        self.connection = connection
        self.isConnected = isConnected
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
        self.onEdit = onEdit
        self.onClone = onClone
        self.onDelete = onDelete
        self.onCiscoConfig = onCiscoConfig
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Circle()
                    .fill(isConnected ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: 8, height: 8)
                Text(connection.name)
                    .fontWeight(.medium)
                if connection.isCiscoDevice {
                    Image(systemName: "switch.2")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .help(lang.s("Cisco Device", "Cisco-Gerät"))
                }
                Spacer()
                if isConnected {
                    Button(lang.s("Disconnect", "Trennen"), action: onDisconnect)
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Button(lang.s("Connect", "Verbinden"), action: onConnect)
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }
            HStack(spacing: 4) {
                if let credential = connection.credential {
                    Image(systemName: "key.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text(credential.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(connection.effectiveUsername)@\(connection.host):\(connection.port)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button {
                onConnect()
            } label: {
                Label(lang.s("Connect", "Verbinden"), systemImage: "play.circle")
            }
            .disabled(isConnected)

            Button {
                onDisconnect()
            } label: {
                Label(lang.s("Disconnect", "Trennen"), systemImage: "stop.circle")
            }
            .disabled(!isConnected)

            if connection.isCiscoDevice {
                Divider()
                Button {
                    onCiscoConfig?()
                } label: {
                    Label(lang.s("Download Running Config", "Running-Config herunterladen"), systemImage: "arrow.down.doc")
                }
            }

            Divider()

            Button {
                onEdit()
            } label: {
                Label(lang.s("Edit", "Bearbeiten"), systemImage: "pencil")
            }

            Button {
                onClone()
            } label: {
                Label(lang.s("Duplicate", "Duplizieren"), systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(lang.s("Delete", "Löschen"), systemImage: "trash")
            }
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
    @Environment(LanguageSettings.self) private var lang
    
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
                    Toggle(lang.s("Sync", "Sync"), isOn: $session.isActive)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                        .help(lang.s("Include this session in broadcast input", "Diese Sitzung in die Broadcast-Eingabe einbeziehen"))
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
    @Environment(LanguageSettings.self) private var lang

    private var activeCount: Int {
        manager.sessions.filter { $0.isActive && $0.isConnected }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Command history popover
            if showHistory && !commandHistory.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(lang.s("Command History", "Befehlsverlauf"))
                            .font(.caption.bold())
                        Spacer()
                        Button {
                            commandHistory.removeAll()
                            showHistory = false
                        } label: {
                            Text(lang.s("Clear", "Löschen"))
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

                TextField(lang.s("Broadcast to \(activeCount) session(s)...", "Senden an \(activeCount) Sitzung(en)..."), text: $command)
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
                    Button(lang.s("Send", "Senden")) { sendCommand() }
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
                .help(lang.s("Command history (\(commandHistory.count)/50)", "Befehlsverlauf (\(commandHistory.count)/50)"))
                .disabled(commandHistory.isEmpty)

                Divider().frame(height: 16)

                Button("^C") {
                    manager.broadcast("\u{03}")
                    if instantMode { command = "" }
                }
                .foregroundStyle(.red)
                .help(lang.s("Send Ctrl+C (interrupt) to active sessions", "Strg+C (Abbruch) an aktive Sitzungen senden"))

                Button("^D") {
                    manager.broadcast("\u{04}")
                    if instantMode { command = "" }
                }
                .foregroundStyle(.orange)
                .help(lang.s("Send Ctrl+D (EOF) to active sessions", "Strg+D (EOF) an aktive Sitzungen senden"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Instant mode toggle
            HStack {
                Toggle(lang.s("Instant transmission (keystrokes sent immediately)", "Sofortübertragung (Tastendrücke werden sofort gesendet)"), isOn: $instantMode)
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
    @Query(sort: \Credential.sortOrder) private var credentials: [Credential]
    @Environment(LanguageSettings.self) private var lang

    @State private var name = ""
    @State private var host = ""
    @State private var port = "22"
    @State private var useCredential = false
    @State private var selectedCredential: Credential?
    @State private var username = ""
    @State private var useKeyAuth = true
    @State private var identityFile = ""
    @State private var password = ""
    @State private var selectedFolder: ConnectionFolder?
    @State private var isCiscoDevice = false

    var body: some View {
        Form {
            Section(lang.s("Connection", "Verbindung")) {
                TextField(lang.s("Display Name", "Anzeigename"), text: $name)
                TextField(lang.s("Hostname or IP", "Hostname oder IP"), text: $host)
                    .onChange(of: host) {
                        if name.isEmpty { name = host }
                    }
                TextField(lang.s("Port", "Port"), text: $port)
                Toggle(lang.s("Cisco Device (IOS/IOS-XE)", "Cisco-Gerät (IOS/IOS-XE)"), isOn: $isCiscoDevice)
            }
            
            Section(lang.s("Organization", "Organisation")) {
                Picker(lang.s("Folder", "Ordner"), selection: $selectedFolder) {
                    Text(lang.s("None", "Kein")).tag(nil as ConnectionFolder?)
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

            Section(lang.s("Authentication", "Authentifizierung")) {
                Toggle(lang.s("Use Saved Credential", "Gespeicherte Anmeldedaten verwenden"), isOn: $useCredential)
                    .onChange(of: useCredential) { oldValue, newValue in
                        if newValue && selectedCredential == nil && !credentials.isEmpty {
                            selectedCredential = credentials.first
                        }
                    }
                
                if useCredential {
                    if credentials.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lang.s("No saved credentials", "Keine gespeicherten Anmeldedaten"))
                                .foregroundStyle(.secondary)
                            Text(lang.s("Create credentials in the Credential Manager", "Anmeldedaten im Anmeldedaten-Manager erstellen"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Picker(lang.s("Credential", "Anmeldedaten"), selection: $selectedCredential) {
                            Text(lang.s("Select...", "Auswählen...")).tag(nil as Credential?)
                            ForEach(credentials) { credential in
                                Text(credential.displayText).tag(credential as Credential?)
                            }
                        }
                    }
                } else {
                    TextField(lang.s("Username", "Benutzername"), text: $username)
                    
                    Picker(lang.s("Method", "Methode"), selection: $useKeyAuth) {
                        Text(lang.s("SSH Key / Agent", "SSH-Schlüssel / Agent")).tag(true)
                        Text(lang.s("Password", "Passwort")).tag(false)
                    }
                    .pickerStyle(.segmented)

                    if useKeyAuth {
                        HStack {
                            TextField(lang.s("Identity file (leave blank for default/agent)", "Identitätsdatei (leer lassen für Standard/Agent)"), text: $identityFile)
                            Button(lang.s("Browse…", "Durchsuchen…")) { browseForKey() }
                        }
                    } else {
                        SecureField(lang.s("Password", "Passwort"), text: $password)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: useCredential ? 420 : 520)
        .navigationTitle(lang.s("Add Connection", "Verbindung hinzufügen"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(lang.s("Cancel", "Abbrechen")) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(lang.s("Add", "Hinzufügen")) { save() }
                    .disabled(host.isEmpty || (useCredential ? selectedCredential == nil : username.isEmpty))
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
            username: useCredential ? "" : username,
            useKeyAuth: useCredential ? true : useKeyAuth,
            identityFile: useCredential ? "" : identityFile,
            password: useCredential ? "" : password,
            isCiscoDevice: isCiscoDevice,
            folder: selectedFolder,
            credential: useCredential ? selectedCredential : nil
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
    @Query(sort: \Credential.sortOrder) private var credentials: [Credential]
    @Environment(LanguageSettings.self) private var lang
    
    @State private var useCredential: Bool = false

    var body: some View {
        Form {
            Section(lang.s("Connection", "Verbindung")) {
                TextField(lang.s("Display name", "Anzeigename"), text: $connection.name)
                TextField(lang.s("Hostname or IP", "Hostname oder IP"), text: $connection.host)
                TextField(lang.s("Port", "Port"), value: $connection.port, format: .number)
                Toggle(lang.s("Cisco Device (IOS/IOS-XE)", "Cisco-Gerät (IOS/IOS-XE)"), isOn: $connection.isCiscoDevice)
            }

            Section(lang.s("Organization", "Organisation")) {
                Picker(lang.s("Folder", "Ordner"), selection: $connection.folder) {
                    Text(lang.s("None", "Kein")).tag(nil as ConnectionFolder?)
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

            Section(lang.s("Authentication", "Authentifizierung")) {
                Toggle(lang.s("Use Saved Credential", "Gespeicherte Anmeldedaten verwenden"), isOn: $useCredential)
                    .onChange(of: useCredential) { oldValue, newValue in
                        if newValue {
                            if connection.credential == nil && !credentials.isEmpty {
                                connection.credential = credentials.first
                            }
                        } else {
                            connection.credential = nil
                        }
                    }
                
                if useCredential {
                    if credentials.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lang.s("No saved credentials", "Keine gespeicherten Anmeldedaten"))
                                .foregroundStyle(.secondary)
                            Text(lang.s("Create credentials in the Credential Manager", "Anmeldedaten im Anmeldedaten-Manager erstellen"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Picker(lang.s("Credential", "Anmeldedaten"), selection: $connection.credential) {
                            Text(lang.s("Select...", "Auswählen...")).tag(nil as Credential?)
                            ForEach(credentials) { credential in
                                Text(credential.displayText).tag(credential as Credential?)
                            }
                        }
                    }
                } else {
                    TextField(lang.s("Username", "Benutzername"), text: $connection.username)
                    
                    Picker(lang.s("Method", "Methode"), selection: $connection.useKeyAuth) {
                        Text(lang.s("SSH Key / Agent", "SSH-Schlüssel / Agent")).tag(true)
                        Text(lang.s("Password", "Passwort")).tag(false)
                    }
                    .pickerStyle(.segmented)

                    if connection.useKeyAuth {
                        HStack {
                            TextField(lang.s("Identity file (leave blank for default/agent)", "Identitätsdatei (leer lassen für Standard/Agent)"), text: $connection.identityFile)
                            Button(lang.s("Browse…", "Durchsuchen…")) { browseForKey() }
                        }
                    } else {
                        SecureField(lang.s("Password", "Passwort"), text: $connection.password)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: useCredential ? 420 : 525)
        .navigationTitle(lang.s("Edit", "Bearbeiten") + ": \(connection.name)")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(lang.s("Done", "Fertig")) { dismiss() }
            }
        }
        .onAppear {
            useCredential = connection.credential != nil
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
    @Environment(LanguageSettings.self) private var lang
    
    @State private var name = ""
    @State private var colorHex = "#3B82F6"
    
    private var availableColors: [(String, String)] {
        [
            (lang.s("Blue", "Blau"), "#3B82F6"),
            (lang.s("Green", "Grün"), "#10B981"),
            (lang.s("Red", "Rot"), "#EF4444"),
            (lang.s("Yellow", "Gelb"), "#F59E0B"),
            (lang.s("Purple", "Lila"), "#8B5CF6"),
            (lang.s("Pink", "Rosa"), "#EC4899"),
            (lang.s("Orange", "Orange"), "#F97316"),
            (lang.s("Cyan", "Türkis"), "#06B6D4"),
        ]
    }
    
    var body: some View {
        Form {
            Section(lang.s("Folder Details", "Ordnerdetails")) {
                TextField(lang.s("Name", "Name"), text: $name)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(lang.s("Color", "Farbe"))
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ForEach(availableColors, id: \.1) { colorName, hex in
                            Button {
                                colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(colorHex == hex ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .help(colorName)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 220)
        .navigationTitle(lang.s("New Folder", "Neuer Ordner"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(lang.s("Cancel", "Abbrechen")) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(lang.s("Create", "Erstellen")) {
                    let folder = ConnectionFolder(name: name.isEmpty ? lang.s("New Folder", "Neuer Ordner") : name, colorHex: colorHex)
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
    @Environment(LanguageSettings.self) private var lang
    
    private var availableColors: [(String, String)] {
        [
            (lang.s("Blue", "Blau"), "#3B82F6"),
            (lang.s("Green", "Grün"), "#10B981"),
            (lang.s("Red", "Rot"), "#EF4444"),
            (lang.s("Yellow", "Gelb"), "#F59E0B"),
            (lang.s("Purple", "Lila"), "#8B5CF6"),
            (lang.s("Pink", "Rosa"), "#EC4899"),
            (lang.s("Orange", "Orange"), "#F97316"),
            (lang.s("Cyan", "Türkis"), "#06B6D4"),
        ]
    }
    
    var body: some View {
        Form {
            Section(lang.s("Folder Details", "Ordnerdetails")) {
                TextField(lang.s("Name", "Name"), text: $folder.name)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(lang.s("Color", "Farbe"))
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ForEach(availableColors, id: \.1) { colorName, hex in
                            Button {
                                folder.colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(folder.colorHex == hex ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .help(colorName)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section(lang.s("Connections", "Verbindungen")) {
                Text("\(folder.connections.count) \(lang.s("connection(s)", "Verbindung(en)"))")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 280)
        .navigationTitle(lang.s("Edit Folder", "Ordner bearbeiten"))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(lang.s("Done", "Fertig")) { dismiss() }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SSHConnection.self, inMemory: true)
}
