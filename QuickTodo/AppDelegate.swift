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
    var isAlwaysOnTop: Bool = false

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

    // 菜单栏图标：只负责 popover 的开关，不直接唤起主页面
    @objc func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    // 唯一打开主页面的入口（由 popover 内「编辑」按钮触发）
    func openStickyNote() {
        popover.performClose(nil)

        if let panel = stickyPanel {
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKeyAndOrderFront(nil)
            return
        }

        let panel = NSPanel(
            contentRect: savedPanelFrame(),
            // 去掉 .nonactivatingPanel，让窗口参与系统窗口管理（Mission Control / Cmd+Tab）
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = ""
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = isAlwaysOnTop ? .floating : .normal
        // .managed 让窗口出现在 Mission Control；.participatesInCycle 参与 Cmd+` 切换
        panel.collectionBehavior = [.managed, .participatesInCycle, .fullScreenAuxiliary]
        panel.delegate = self
        updatePanelContent(panel)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        stickyPanel = panel
    }

    func toggleAlwaysOnTop() {
        isAlwaysOnTop.toggle()
        guard let panel = stickyPanel else { return }
        panel.level = isAlwaysOnTop ? .floating : .normal
        updatePanelContent(panel)
    }

    private func updatePanelContent(_ panel: NSPanel) {
        panel.contentView = NSHostingView(rootView: StickyNoteView(
            store: store,
            onToggleAlwaysOnTop: { [weak self] in self?.toggleAlwaysOnTop() },
            isAlwaysOnTop: isAlwaysOnTop
        ))
    }

    private func savedPanelFrame() -> NSRect {
        if let saved = UserDefaults.standard.string(forKey: "panel_frame"),
           let rect = NSRectFromString(saved) as NSRect?,
           rect != .zero {
            return rect
        }
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        return NSRect(x: screen.maxX - 280, y: screen.maxY - 400, width: 260, height: 360)
    }
}

extension AppDelegate: NSWindowDelegate {
    // Mission Control 或系统手势激活窗口时，确保 app 获得焦点
    func windowDidBecomeKey(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowDidMove(_ notification: Notification) {
        guard let panel = stickyPanel else { return }
        UserDefaults.standard.set(NSStringFromRect(panel.frame), forKey: "panel_frame")
    }

    func windowWillClose(_ notification: Notification) {
        stickyPanel = nil
    }
}
