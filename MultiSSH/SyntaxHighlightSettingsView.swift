import SwiftUI
import AppKit

struct SyntaxHighlightSettingsView: View {
    @Bindable var manager: ConnectionManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var newKeyword = ""
    @State private var newColor: Color = .red
    @State private var editingKeyword: String?
    @State private var showingClearConfirmation = false
    @State private var showingResetConfirmation = false
    @State private var searchText = ""
    
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
                            Button("Clear All Keywords") {
                                showingClearConfirmation = true
                            }
                            Button("Reset to Defaults") {
                                showingResetConfirmation = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .menuStyle(.borderlessButton)
                        .frame(width: 24, height: 24)
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
            
            // Presets section
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Presets")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    PresetButton(title: "System Logs", icon: "doc.text", color: .red) {
                        applySystemLogsPreset()
                    }
                    PresetButton(title: "Git Output", icon: "arrow.triangle.branch", color: .purple) {
                        applyGitPreset()
                    }
                    PresetButton(title: "Docker", icon: "shippingbox", color: .blue) {
                        applyDockerPreset()
                    }
                    PresetButton(title: "Network", icon: "network", color: .green) {
                        applyNetworkPreset()
                    }
                }
            }
            .padding()
        }
        .frame(width: 600, height: 700)
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
            "Reset to defaults?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                manager.syntaxHighlights.removeAll()
                applySystemLogsPreset()
                cancelEditing()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will replace all current keywords with the default System Logs preset.")
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
    
    // MARK: - Preset configurations
    private func applySystemLogsPreset() {
        manager.addHighlight(keyword: "error", color: .systemRed)
        manager.addHighlight(keyword: "ERROR", color: .systemRed)
        manager.addHighlight(keyword: "fail", color: .systemRed)
        manager.addHighlight(keyword: "FAIL", color: .systemRed)
        manager.addHighlight(keyword: "fatal", color: .systemRed)
        manager.addHighlight(keyword: "warning", color: .systemOrange)
        manager.addHighlight(keyword: "WARNING", color: .systemOrange)
        manager.addHighlight(keyword: "warn", color: .systemOrange)
        manager.addHighlight(keyword: "info", color: .systemBlue)
        manager.addHighlight(keyword: "INFO", color: .systemBlue)
        manager.addHighlight(keyword: "success", color: .systemGreen)
        manager.addHighlight(keyword: "SUCCESS", color: .systemGreen)
        manager.addHighlight(keyword: "debug", color: .systemGray)
    }
    
    private func applyGitPreset() {
        manager.addHighlight(keyword: "modified", color: .systemYellow)
        manager.addHighlight(keyword: "deleted", color: .systemRed)
        manager.addHighlight(keyword: "created", color: .systemGreen)
        manager.addHighlight(keyword: "renamed", color: .systemBlue)
        manager.addHighlight(keyword: "conflict", color: .systemOrange)
        manager.addHighlight(keyword: "branch", color: .systemPurple)
        manager.addHighlight(keyword: "commit", color: .systemGreen)
        manager.addHighlight(keyword: "merge", color: .systemTeal)
    }
    
    private func applyDockerPreset() {
        manager.addHighlight(keyword: "Up", color: .systemGreen)
        manager.addHighlight(keyword: "Exited", color: .systemRed)
        manager.addHighlight(keyword: "running", color: .systemGreen)
        manager.addHighlight(keyword: "stopped", color: .systemRed)
        manager.addHighlight(keyword: "pulling", color: .systemBlue)
        manager.addHighlight(keyword: "building", color: .systemYellow)
    }
    
    private func applyNetworkPreset() {
        manager.addHighlight(keyword: "connected", color: .systemGreen)
        manager.addHighlight(keyword: "disconnected", color: .systemRed)
        manager.addHighlight(keyword: "timeout", color: .systemOrange)
        manager.addHighlight(keyword: "refused", color: .systemRed)
        manager.addHighlight(keyword: "listening", color: .systemGreen)
        manager.addHighlight(keyword: "established", color: .systemBlue)
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

struct PresetButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "plus.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SyntaxHighlightSettingsView(manager: ConnectionManager())
}
