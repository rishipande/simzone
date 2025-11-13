//
//  SimzoneApp.swift
//  Simzone
//
//  Author: Rishi Pande
//  Date: 11/11/25
//

import SwiftUI
import Combine

@main
struct SimzoneApp: App {
    var body: some Scene {
        // Menu bar icon + popover
        MenuBarExtra {
            ContentView()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: 260, alignment: .topLeading)
        } label: {
            MenuBarLabelView()
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarLabelView: View {
    @AppStorage("simzoneMenuBarEmoji") private var menuBarEmoji: String = "🌖"
    @AppStorage("simzoneShowTimeInMenuBar") private var showTimeInMenuBar: Bool = false
    @AppStorage("simzoneMenuBarShortName") private var menuBarShortName: String = ""
    @AppStorage("simzoneMenuBarTimeZoneId") private var menuBarTimeZoneId: String = "local"
    @AppStorage("simzoneMenuBarFormat") private var menuBarFormat: String = "HH:mm"

    @State private var now = Date()

    private let timer = Timer
        .publish(every: 10, on: .main, in: .common)
        .autoconnect()

    var body: some View {
        Group {
            if showTimeInMenuBar {
                Text(menuBarTitle)
                    .monospacedDigit()
            } else {
                Text(menuBarEmoji)
                    .font(.system(size: 13))   // a hair bigger so it reads nicely
            }
        }
        .onReceive(timer) { current in
            now = current
        }
    }

    private var menuBarTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = menuBarFormat
        formatter.timeZone = selectedTimeZone
        
        let timeString = formatter.string(from: now)
        let prefix = menuBarShortName.trimmingCharacters(in: .whitespaces)

        return prefix.isEmpty ? timeString : "\(prefix) \(timeString)"
    }

    private var selectedTimeZone: TimeZone {
        if menuBarTimeZoneId == "local" || menuBarTimeZoneId.isEmpty {
            return .current
        }
        return TimeZone(identifier: menuBarTimeZoneId) ?? .current
    }
}
