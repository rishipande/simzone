//
//  ContentView.swift
//  Simzone
//
//  Author: Rishi Pande
//  Date: 11/11/25
//

import SwiftUI
import Combine
import AppKit

struct CityTimeZone: Identifiable {
    let id: String          // unique
    let name: String        // display name
    let identifier: String  // TimeZone identifier
}

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    // Stored time zones (up to 5) coming from Preferences
    @AppStorage("simzoneLocation1") private var loc1: String = ""
    @AppStorage("simzoneLocation2") private var loc2: String = ""
    @AppStorage("simzoneLocation3") private var loc3: String = ""
    @AppStorage("simzoneLocation4") private var loc4: String = ""
    @AppStorage("simzoneLocation5") private var loc5: String = ""
    
    @AppStorage("simzoneLocation1Name") private var loc1Name: String = ""
    @AppStorage("simzoneLocation2Name") private var loc2Name: String = ""
    @AppStorage("simzoneLocation3Name") private var loc3Name: String = ""
    @AppStorage("simzoneLocation4Name") private var loc4Name: String = ""
    @AppStorage("simzoneLocation5Name") private var loc5Name: String = ""

    @AppStorage("simzoneDateFormat") private var dateFormat: String = "MMM dd EEE hh:mm a"
    
    @State private var now = Date()
    
    private let timer = Timer
        .publish(every: 10, on: .main, in: .common)   // every 10s; no seconds so no flicker
        .autoconnect()
    
    // All selected time zones from preferences
    private var selectedTimeZones: [CityTimeZone] {
        let stored = [loc1, loc2, loc3, loc4, loc5]
            .filter { !$0.isEmpty }
        
        var seen = Set<String>()
        var result: [CityTimeZone] = []
        
        for identifier in stored where !seen.contains(identifier) {
            seen.insert(identifier)
            result.append(
                CityTimeZone(
                    id: identifier,
                    name: customName(for: identifier) ?? displayName(for: identifier),
                    identifier: identifier
                )
            )
        }
        return result
    }
    
    private func customName(for identifier: String) -> String? {
        if identifier == loc1, !loc1Name.isEmpty { return loc1Name }
        if identifier == loc2, !loc2Name.isEmpty { return loc2Name }
        if identifier == loc3, !loc3Name.isEmpty { return loc3Name }
        if identifier == loc4, !loc4Name.isEmpty { return loc4Name }
        if identifier == loc5, !loc5Name.isEmpty { return loc5Name }
        return nil
    }
    
    private var invertedLabelColor: Color {
        colorScheme == .dark ? .white : .black  // light on dark / dark on light
    }
    
    private func closeMenuBarPopover() {
        NSApplication.shared.keyWindow?.close()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Local time
            VStack(alignment: .leading, spacing: 6) {
                Text("Local Time")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                
                Text(formattedDate(for: .current))
                    .font(.body)
                    .textSelection(.enabled)
                    .foregroundStyle(.primary)
                    .iBeamCursorOnHover()
            }

            // Extra time zones from preferences
            if !selectedTimeZones.isEmpty {
                Divider()
                
                ForEach(selectedTimeZones) { city in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(city.name)
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                        
                        Text(formattedDate(for: TimeZone(identifier: city.identifier) ?? .current))
                            .font(.body)
                            .foregroundColor(invertedLabelColor)
                            .textSelection(.enabled)
                            .iBeamCursorOnHover()
                    }
                    
                    if city.id != selectedTimeZones.last?.id {
                        Divider()
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading) {
                MenuRow(title: "Settings", shortcut: "⌘,") {
                    closeMenuBarPopover()
                    PreferencesWindowController.shared.show()
                }

                MenuRow(title: "Quit Simzone", shortcut: "⌘Q") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .onReceive(timer) { current in
            now = current
        }
    }
    
    private func formattedDate(for timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.timeZone = timeZone
        return formatter.string(from: now)
    }
    
    private func displayName(for identifier: String) -> String {
        // e.g. "America/Los_Angeles" -> "Los Angeles"
        let parts = identifier.split(separator: "/")
        if let last = parts.last {
            return last.replacingOccurrences(of: "_", with: " ")
        }
        return identifier
    }
}

private struct IBeamOnHoverModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { inside in
            if inside {
                NSCursor.iBeam.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

private extension View {
    func iBeamCursorOnHover() -> some View {
        modifier(IBeamOnHoverModifier())
    }
}

struct MenuRow: View {
    let title: String
    let shortcut: String?
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if let shortcut {
                Text(shortcut)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .background(
            isHovering
            ? Color.accentColor.opacity(0.12)   // hover highlight
            : Color.clear
        )
        .contentShape(Rectangle())        // full row is clickable
        .onTapGesture {
            action()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 260)
        .padding()
}
