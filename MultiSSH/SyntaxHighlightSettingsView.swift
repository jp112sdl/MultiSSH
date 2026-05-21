import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SyntaxHighlightSettingsView: View {
    @Bindable var manager: ConnectionManager
    @Environment(\.dismiss) private var dismiss
    
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
                    Text("Syntax Highlighting")
                        .font(.headline)
                    Text("Configure keyword colors for SSH terminal output")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            
            Divider()
            
            // Add/Edit keyword section
            VStack(alignment: .leading, spacing: 8) {
                Text(editingKeyword != nil ? "Edit Keyword" : "Add New Keyword")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    TextField("Keyword (e.g., error, success, warning)", text: $newKeyword)
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
                        Button("Update") {
                            updateKeyword()
                        }
                        .disabled(newKeyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                        Button("Cancel") {
                            cancelEditing()
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button("Add") {
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
                TextField("Search keywords...", text: $searchText)
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
                    Text("Saved Keywords (\(manager.syntaxHighlights.count))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if !searchText.isEmpty {
                        Text("• \(filteredKeywords.count) matching")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if !manager.syntaxHighlights.isEmpty {
                        Menu {
                            Button {
                                exportHighlights()
                            } label: {
                                Label("Export Keywords...", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                importHighlights()
                            } label: {
                                Label("Import Keywords...", systemImage: "square.and.arrow.down")
                            }
                            
                            Divider()
                            
                            Button("Clear All Keywords") {
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
                            Label("Import", systemImage: "square.and.arrow.down")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                if filteredKeywords.isEmpty {
                    ContentUnavailableView {
                        Label(searchText.isEmpty ? "No Keywords" : "No Matching Keywords", 
                              systemImage: "paintbrush.slash")
                    } description: {
                        Text(searchText.isEmpty ? "Add keywords to highlight them in terminal output" : "Try a different search term")
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
                Text("Import & Export")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Button {
                        exportHighlights()
                    } label: {
                        Label("Export to File", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(manager.syntaxHighlights.isEmpty)
                    
                    Button {
                        importHighlights()
                    } label: {
                        Label("Import from File", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                }
                .controlSize(.large)
                
                Text("Export keywords to share or backup. Import to merge or replace keywords.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .frame(width: 600, height: 600)
        .confirmationDialog(
            "Clear all keywords?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All", role: .destructive) {
                manager.syntaxHighlights.removeAll()
                cancelEditing()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all \(manager.syntaxHighlights.count) saved keywords. This action cannot be undone.")
        }
        .confirmationDialog(
            "Import Keywords",
            isPresented: $showingImportOptions,
            titleVisibility: .visible
        ) {
            Button("Merge with Existing") {
                performImport(replace: false)
            }
            Button("Replace All", role: .destructive) {
                performImport(replace: true)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose how to import the keywords")
        }
        .alert("Import Error", isPresented: $showingImportError) {
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
        panel.message = "Export syntax highlighting keywords"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try data.write(to: url)
                } catch {
                    importErrorMessage = "Failed to export: \(error.localizedDescription)"
                    showingImportError = true
                }
            }
        }
    }
    
    private func importHighlights() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.message = "Select a syntax highlights file to import"
        
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
                    .help("Edit keyword")
                    
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete keyword")
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
