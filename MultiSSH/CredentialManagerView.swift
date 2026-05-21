import SwiftUI
import SwiftData
import AppKit

// MARK: - Credential Manager View

struct CredentialManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Credential.sortOrder) private var credentials: [Credential]
    
    @State private var showAddCredential = false
    @State private var editingCredential: Credential?
    
    var body: some View {
        NavigationStack {
            List {
                if credentials.isEmpty {
                    ContentUnavailableView(
                        "No Saved Credentials",
                        systemImage: "key.fill",
                        description: Text("Create reusable credentials to use across multiple connections")
                    )
                } else {
                    ForEach(credentials) { credential in
                        CredentialRowView(
                            credential: credential,
                            onEdit: { editingCredential = credential },
                            onDelete: {
                                credential.deletePassword()
                                modelContext.delete(credential)
                            }
                        )
                    }
                }
            }
            .navigationTitle("Credential Manager")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddCredential = true
                    } label: {
                        Label("Add Credential", systemImage: "plus")
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
        .sheet(isPresented: $showAddCredential) {
            AddCredentialView { credential in
                modelContext.insert(credential)
            }
        }
        .sheet(item: $editingCredential) { credential in
            EditCredentialView(credential: credential)
        }
    }
}

// MARK: - Credential Row

struct CredentialRowView: View {
    let credential: Credential
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundStyle(.blue)
                    .frame(width: 20)
                Text(credential.name)
                    .font(.headline)
                Spacer()
                Button("Edit") {
                    onEdit()
                }
                .buttonStyle(.plain)
                .font(.caption)
            }
            
            Text(credential.displayText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Credential View

struct AddCredentialView: View {
    let onSave: (Credential) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var username = ""
    @State private var useKeyAuth = true
    @State private var identityFile = ""
    @State private var password = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Credential Details") {
                    TextField("Name", text: $name)
                        .help("A descriptive name for this credential set")
                    TextField("Username", text: $username)
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
                        .help("Path to private key file, or leave blank to use SSH agent")
                    } else {
                        SecureField("Password", text: $password)
                            .help("Password will be stored securely in Keychain")
                    }
                }
                
                Section {
                    Text("Credentials are stored securely and can be reused across multiple connections.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Credential")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        save()
                    }
                    .disabled(name.isEmpty || username.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 400)
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
        let credential = Credential(
            name: name,
            username: username,
            useKeyAuth: useKeyAuth,
            identityFile: identityFile,
            password: password
        )
        onSave(credential)
        dismiss()
    }
}

// MARK: - Edit Credential View

struct EditCredentialView: View {
    @Bindable var credential: Credential
    @Environment(\.dismiss) private var dismiss
    
    @State private var password = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Credential Details") {
                    TextField("Name", text: $credential.name)
                        .help("A descriptive name for this credential set")
                    TextField("Username", text: $credential.username)
                }
                
                Section("Authentication") {
                    Picker("Method", selection: $credential.useKeyAuth) {
                        Text("SSH Key / Agent").tag(true)
                        Text("Password").tag(false)
                    }
                    .pickerStyle(.segmented)
                    
                    if credential.useKeyAuth {
                        HStack {
                            TextField("Identity file (leave blank for default/agent)", text: $credential.identityFile)
                            Button("Browse…") { browseForKey() }
                        }
                        .help("Path to private key file, or leave blank to use SSH agent")
                    } else {
                        SecureField("Password", text: $password, prompt: Text("Leave blank to keep existing"))
                            .help("Enter new password or leave blank to keep existing")
                            .onAppear {
                                // Don't pre-fill password for security
                                password = ""
                            }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Credential")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // Only update password if a new one was entered
                        if !password.isEmpty {
                            credential.password = password
                        }
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func browseForKey() {
        let panel = NSOpenPanel()
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            credential.identityFile = panel.url?.path ?? ""
        }
    }
}
