import SwiftUI
import SwiftData
import AppKit

// MARK: - Credential Manager View

struct CredentialManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Credential.sortOrder) private var credentials: [Credential]
    @Environment(LanguageSettings.self) private var lang

    @State private var showAddCredential = false
    @State private var editingCredential: Credential?

    var body: some View {
        NavigationStack {
            List {
                if credentials.isEmpty {
                    ContentUnavailableView(
                        lang.s("No Saved Credentials", "Keine gespeicherten Anmeldedaten"),
                        systemImage: "key.fill",
                        description: Text(lang.s("Create reusable credentials to use across multiple connections", "Wiederverwendbare Anmeldedaten für mehrere Verbindungen erstellen"))
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
            .navigationTitle(lang.s("Credential Manager", "Anmeldedaten-Manager"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lang.s("Done", "Fertig")) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddCredential = true
                    } label: {
                        Label(lang.s("Add Credential", "Anmeldedaten hinzufügen"), systemImage: "plus")
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
    @Environment(LanguageSettings.self) private var lang

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundStyle(.blue)
                    .frame(width: 20)
                Text(credential.name)
                    .font(.headline)
                Spacer()
                Button(lang.s("Edit", "Bearbeiten")) {
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
                Label(lang.s("Edit", "Bearbeiten"), systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(lang.s("Delete", "Löschen"), systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Credential View

struct AddCredentialView: View {
    let onSave: (Credential) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageSettings.self) private var lang

    @State private var name = ""
    @State private var username = ""
    @State private var useKeyAuth = true
    @State private var identityFile = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(lang.s("Credential Details", "Anmeldedaten-Details")) {
                    TextField(lang.s("Name", "Name"), text: $name)
                        .help(lang.s("A descriptive name for this credential set", "Ein beschreibender Name für diesen Anmeldedatensatz"))
                    TextField(lang.s("Username", "Benutzername"), text: $username)
                }

                Section(lang.s("Authentication", "Authentifizierung")) {
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
                        .help(lang.s("Path to private key file, or leave blank to use SSH agent", "Pfad zur privaten Schlüsseldatei oder leer lassen für SSH-Agent"))
                    } else {
                        SecureField(lang.s("Password", "Passwort"), text: $password)
                            .help(lang.s("Password will be stored securely in Keychain", "Passwort wird sicher in der Keychain gespeichert"))
                    }
                }

                Section {
                    Text(lang.s("Credentials are stored securely and can be reused across multiple connections.", "Anmeldedaten werden sicher gespeichert und können für mehrere Verbindungen verwendet werden."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(lang.s("Add Credential", "Anmeldedaten hinzufügen"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lang.s("Cancel", "Abbrechen")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lang.s("Add", "Hinzufügen")) {
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
    @Environment(LanguageSettings.self) private var lang

    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(lang.s("Credential Details", "Anmeldedaten-Details")) {
                    TextField(lang.s("Name", "Name"), text: $credential.name)
                        .help(lang.s("A descriptive name for this credential set", "Ein beschreibender Name für diesen Anmeldedatensatz"))
                    TextField(lang.s("Username", "Benutzername"), text: $credential.username)
                }

                Section(lang.s("Authentication", "Authentifizierung")) {
                    Picker(lang.s("Method", "Methode"), selection: $credential.useKeyAuth) {
                        Text(lang.s("SSH Key / Agent", "SSH-Schlüssel / Agent")).tag(true)
                        Text(lang.s("Password", "Passwort")).tag(false)
                    }
                    .pickerStyle(.segmented)

                    if credential.useKeyAuth {
                        HStack {
                            TextField(lang.s("Identity file (leave blank for default/agent)", "Identitätsdatei (leer lassen für Standard/Agent)"), text: $credential.identityFile)
                            Button(lang.s("Browse…", "Durchsuchen…")) { browseForKey() }
                        }
                        .help(lang.s("Path to private key file, or leave blank to use SSH agent", "Pfad zur privaten Schlüsseldatei oder leer lassen für SSH-Agent"))
                    } else {
                        SecureField(lang.s("Password", "Passwort"), text: $password, prompt: Text(lang.s("Leave blank to keep existing", "Leer lassen, um vorhandenes beizubehalten")))
                            .help(lang.s("Enter new password or leave blank to keep existing", "Neues Passwort eingeben oder leer lassen"))
                            .onAppear {
                                // Don't pre-fill password for security
                                password = ""
                            }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(lang.s("Edit Credential", "Anmeldedaten bearbeiten"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(lang.s("Done", "Fertig")) {
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
