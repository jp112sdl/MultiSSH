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
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
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
