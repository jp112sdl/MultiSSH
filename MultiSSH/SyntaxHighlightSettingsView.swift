import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SyntaxHighlightSettingsView: View {
    @Bindable var manager: ConnectionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(LanguageSettings.self) private var lang

    @State private var newKeyword = ""
    @State private var newColor: Color = .red
    @State private var editingKeyword: String?
    @State private var showingClearConfirmation = false
    @State private var searchText = ""
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    @State private var showingImportOptions = false

    var filteredKeywords: [String] {
        let keywords = Array(manager.syntaxHighlights.keys.sorted())
        if searchText.isEmpty {
            return keywords
        }
        return keywords.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.s("Syntax Highlighting", "Syntax-Hervorhebung"))
                        .font(.headline)
                    Text(lang.s("Configure keyword colors for SSH terminal output", "Schlüsselwortfarben für SSH-Terminalausgabe konfigurieren"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(lang.s("Done", "Fertig")) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            // Add/Edit keyword section
            VStack(alignment: .leading, spacing: 8) {
                Text(editingKeyword != nil ? lang.s("Edit Keyword", "Schlüsselwort bearbeiten") : lang.s("Add New Keyword", "Neues Schlüsselwort hinzufügen"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    TextField(lang.s("Keyword (e.g., error, success, warning)", "Schlüsselwort (z.B. Fehler, Erfolg, Warnung)"), text: $newKeyword)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            if !newKeyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                addKeyword()
                            }
                        }

                    ColorPicker("Color", selection: $newColor)
                        .labelsHidden()
                        .frame(width: 50)

                    if editingKeyword != nil {
                        Button(lang.s("Update", "Aktualisieren")) {
                            updateKeyword()
                        }
                        .disabled(newKeyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button(lang.s("Cancel", "Abbrechen")) {
                            cancelEditing()
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(lang.s("Add", "Hinzufügen")) {
                            addKeyword()
                        }
                        .disabled(newKeyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .keyboardShortcut(.return, modifiers: [])
                    }
                }
            }
            .padding()
            .background(editingKeyword != nil ? Color.accentColor.opacity(0.05) : Color.clear)

            Divider()

            // Search and filter
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(lang.s("Search keywords...", "Schlüsselwörter suchen..."), text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // List of current highlights
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(lang.s("Saved Keywords (\(manager.syntaxHighlights.count))", "Gespeicherte Schlüsselwörter (\(manager.syntaxHighlights.count))"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !searchText.isEmpty {
                        Text("• \(filteredKeywords.count) \(lang.s("matching", "gefunden"))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if !manager.syntaxHighlights.isEmpty {
                        Menu {
                            Button {
                                exportHighlights()
                            } label: {
                                Label(lang.s("Export Keywords...", "Schlüsselwörter exportieren..."), systemImage: "square.and.arrow.up")
                            }

                            Button {
                                importHighlights()
                            } label: {
                                Label(lang.s("Import Keywords...", "Schlüsselwörter importieren..."), systemImage: "square.and.arrow.down")
                            }

                            Divider()

                            Button(lang.s("Clear All Keywords", "Alle Schlüsselwörter löschen")) {
                                showingClearConfirmation = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .menuStyle(.borderlessButton)
                        .frame(width: 24, height: 24)
                    } else {
                        // Show import button when empty
                        Button {
                            importHighlights()
                        } label: {
                            Label(lang.s("Import", "Importieren"), systemImage: "square.and.arrow.down")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }

                if filteredKeywords.isEmpty {
                    ContentUnavailableView {
                        Label(searchText.isEmpty ? lang.s("No Keywords", "Keine Schlüsselwörter") : lang.s("No Matching Keywords", "Keine übereinstimmenden Schlüsselwörter"),
                              systemImage: "paintbrush.slash")
                    } description: {
                        Text(searchText.isEmpty ? lang.s("Add keywords to highlight them in terminal output", "Schlüsselwörter hinzufügen, um sie in der Terminalausgabe hervorzuheben") : lang.s("Try a different search term", "Versuchen Sie einen anderen Suchbegriff"))
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(filteredKeywords, id: \.self) { keyword in
                                if let color = manager.syntaxHighlights[keyword] {
                                    KeywordRowView(
                                        keyword: keyword,
                                        color: color,
                                        isEditing: editingKeyword == keyword,
                                        onEdit: {
                                            editingKeyword = keyword
                                            newKeyword = keyword
                                            newColor = Color(nsColor: color)
                                        },
                                        onDelete: {
                                            manager.removeHighlight(keyword: keyword)
                                            if editingKeyword == keyword {
                                                cancelEditing()
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()

            Divider()

            // Import/Export section
            VStack(alignment: .leading, spacing: 8) {
                Text(lang.s("Import & Export", "Import & Export"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button {
                        exportHighlights()
                    } label: {
                        Label(lang.s("Export to File", "In Datei exportieren"), systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(manager.syntaxHighlights.isEmpty)

                    Button {
                        importHighlights()
                    } label: {
                        Label(lang.s("Import from File", "Aus Datei importieren"), systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                }
                .controlSize(.large)

                Text(lang.s("Export keywords to share or backup. Import to merge or replace keywords.", "Schlüsselwörter zum Teilen oder Sichern exportieren. Importieren zum Zusammenführen oder Ersetzen."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .frame(width: 600, height: 600)
        .confirmationDialog(
            lang.s("Clear all keywords?", "Alle Schlüsselwörter löschen?"),
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button(lang.s("Clear All", "Alle löschen"), role: .destructive) {
                manager.syntaxHighlights.removeAll()
                cancelEditing()
            }
            Button(lang.s("Cancel", "Abbrechen"), role: .cancel) {}
        } message: {
            Text(lang.s("This will remove all \(manager.syntaxHighlights.count) saved keywords. This action cannot be undone.", "Dadurch werden alle \(manager.syntaxHighlights.count) gespeicherten Schlüsselwörter gelöscht. Diese Aktion kann nicht rückgängig gemacht werden."))
        }
        .confirmationDialog(
            lang.s("Import Keywords", "Schlüsselwörter importieren"),
            isPresented: $showingImportOptions,
            titleVisibility: .visible
        ) {
            Button(lang.s("Merge with Existing", "Mit vorhandenen zusammenführen")) {
                performImport(replace: false)
            }
            Button(lang.s("Replace All", "Alle ersetzen"), role: .destructive) {
                performImport(replace: true)
            }
            Button(lang.s("Cancel", "Abbrechen"), role: .cancel) {}
        } message: {
            Text(lang.s("Choose how to import the keywords", "Wählen Sie, wie die Schlüsselwörter importiert werden sollen"))
        }
        .alert(lang.s("Import Error", "Importfehler"), isPresented: $showingImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage)
        }
    }

    // MARK: - Helper Functions

    private func addKeyword() {
        let trimmed = newKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        manager.addHighlight(keyword: trimmed, color: NSColor(newColor))

        // Reset form
        resetForm()
    }

    private func updateKeyword() {
        guard let oldKeyword = editingKeyword else { return }
        let trimmed = newKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Remove old keyword if name changed
        if oldKeyword != trimmed {
            manager.removeHighlight(keyword: oldKeyword)
        }

        // Add/update with new values
        manager.addHighlight(keyword: trimmed, color: NSColor(newColor))

        // Reset form
        resetForm()
    }

    private func cancelEditing() {
        resetForm()
    }

    private func resetForm() {
        newKeyword = ""
        newColor = .red
        editingKeyword = nil
    }

    // MARK: - Import/Export Functions

    @State private var importFileURL: URL?

    private func exportHighlights() {
        guard let data = manager.exportHighlights() else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "syntax-highlights.json"
        panel.message = lang.s("Export syntax highlighting keywords", "Syntax-Hervorhebungs-Schlüsselwörter exportieren")

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try data.write(to: url)
                } catch {
                    importErrorMessage = lang.s("Failed to export: ", "Export fehlgeschlagen: ") + error.localizedDescription
                    showingImportError = true
                }
            }
        }
    }

    private func importHighlights() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.message = lang.s("Select a syntax highlights file to import", "Datei mit Syntax-Hervorhebungen zum Importieren auswählen")

        panel.begin { response in
            if response == .OK, let url = panel.url {
                importFileURL = url
                // Ask user if they want to merge or replace
                if !manager.syntaxHighlights.isEmpty {
                    showingImportOptions = true
                } else {
                    // If empty, just import
                    performImport(replace: false)
                }
            }
        }
    }

    private func performImport(replace: Bool) {
        guard let url = importFileURL else { return }

        do {
            let data = try Data(contentsOf: url)
            try manager.importHighlights(from: data, replace: replace)
            importFileURL = nil
        } catch {
            importErrorMessage = error.localizedDescription
            showingImportError = true
        }
    }
}

// MARK: - Supporting Views

struct KeywordRowView: View {
    let keyword: String
    let color: NSColor
    let isEditing: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(LanguageSettings.self) private var lang

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(nsColor: color))
                .frame(width: 40, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )

            // Keyword text
            Text(keyword)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)

            Spacer()

            // Action buttons (shown on hover or when editing)
            if isHovering || isEditing {
                HStack(spacing: 8) {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(lang.s("Edit keyword", "Schlüsselwort bearbeiten"))

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help(lang.s("Delete keyword", "Schlüsselwort löschen"))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isEditing ? Color.accentColor.opacity(0.15) :
                      (isHovering ? Color(NSColor.controlBackgroundColor) : Color.clear))
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    SyntaxHighlightSettingsView(manager: ConnectionManager())
}
