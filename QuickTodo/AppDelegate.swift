//
//  AppDelegate.swift
//  QuickTodo
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var stickyPanel: NSPanel?
    let store = TodoStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 菜单栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "QuickTodo")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 360)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(store: store, onOpenStickyNote: { [weak self] in
                self?.openStickyNote()
            })
        )
    }

    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func openStickyNote() {
        popover.performClose(nil)

        if let panel = stickyPanel {
            panel.makeKeyAndOrderFront(nil)
            return
        }

        let panel = NSPanel(
            contentRect: savedPanelFrame(),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "QuickTodo"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: StickyNoteView(store: store))
        panel.delegate = self
        panel.makeKeyAndOrderFront(nil)
        stickyPanel = panel
    }

    private func savedPanelFrame() -> NSRect {
        if let saved = UserDefaults.standard.string(forKey: "panel_frame"),
           let rect = NSRectFromString(saved) as NSRect?,
           rect != .zero {
            return rect
        }
        // 默认位置：屏幕右上角
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        return NSRect(x: screen.maxX - 280, y: screen.maxY - 400, width: 260, height: 360)
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        guard let panel = stickyPanel else { return }
        UserDefaults.standard.set(NSStringFromRect(panel.frame), forKey: "panel_frame")
    }

    func windowWillClose(_ notification: Notification) {
        stickyPanel = nil
    }
}
