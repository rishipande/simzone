//
//  PreferencesWindow.swift
//  Simzone
//
//  Author: Rishi Pande
//  Date: 11/11/25
//

import SwiftUI
import AppKit

final class PreferencesWindowController: NSWindowController {
    static let shared = PreferencesWindowController()
    
    private init() {
        let hosting = NSHostingController(rootView: PreferencesView())
        
        let window = NSWindow(
            contentViewController: hosting
        )
        window.title = "Simzone Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 460, height: 260))
        
        super.init(window: window)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        guard let window = self.window else { return }
        window.center()
        self.showWindow(nil)
        
        // make sure it comes to the front even for menu bar apps
        NSApp.activate(ignoringOtherApps: true)
    }
}
