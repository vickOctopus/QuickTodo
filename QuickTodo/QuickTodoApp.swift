//
//  QuickTodoApp.swift
//  QuickTodo
//

import SwiftUI

@main
struct QuickTodoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
