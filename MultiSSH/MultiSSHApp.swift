//
//  MultiSSHApp.swift
//  MultiSSH
//
//  Created by Jérôme Pech on 19.05.26.
//

import SwiftUI
import SwiftData

@main
struct MultiSSHApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SSHConnection.self, ConnectionFolder.self, Credential.self])
        
        // Create custom URL in ~/Library/Application Support/MultiSSH
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let multiSSHURL = appSupportURL.appendingPathComponent("MultiSSH", isDirectory: true)
        
        // Ensure the directory exists
        try? FileManager.default.createDirectory(at: multiSSHURL, withIntermediateDirectories: true)
        
        let storeURL = multiSSHURL.appendingPathComponent("default.store")
        let modelConfiguration = ModelConfiguration(url: storeURL)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("[MultiSSH] SwiftData store: \(storeURL.path)")
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @State private var languageSettings = LanguageSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(languageSettings)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 1100, height: 700)
    }
}
