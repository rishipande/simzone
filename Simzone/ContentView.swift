//
//  ContentView.swift
//  Simzone
//
//  Author: Rishi Pande
//  Date: 11/11/25
//

import SwiftUI
import Combine

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
    
    @AppStorage("simzoneShowLocalTime") private var showLocalTime: Bool = true
    @AppStorage("simzoneLocalTimeLabel") private var localTimeLabel: String = "Local Time"
    
    @AppStorage("simzoneShowAdjustButtons") private var showAdjustButtons: Bool = true
    
    @AppStorage("simzoneShowTimeDifferences") private var showTimeDifferences: Bool = true
    @AppStorage("simzoneShowCopyButtons") private var showCopyButtons: Bool = true

    
    @State private var now = Date()
    @State private var offsetMinutes: Int = 0
    @State private var hoveredRowID: String? = nil
    
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
    
    // calculate time difference - uses the now state so DST and current offsets stay correct
    private func timeDifferenceString(for timeZone: TimeZone) -> String {
        
        let adjustedNow = now.addingTimeInterval(TimeInterval(offsetMinutes * 60))

        let localTZ = TimeZone.current
        let localSeconds = localTZ.secondsFromGMT(for: adjustedNow)
        let otherSeconds = timeZone.secondsFromGMT(for: adjustedNow)
        let diffSeconds = otherSeconds - localSeconds

        if diffSeconds == 0 {
            return "Local"
        }

        let hours = Double(diffSeconds) / 3600.0
        let sign = hours > 0 ? "+" : "-"
        let absHours = abs(hours)

        let hoursText: String
        if absHours == floor(absHours) {
            hoursText = String(format: "%.0f", absHours)
        } else if (absHours * 2).truncatingRemainder(dividingBy: 1) == 0 {
            // e.g. 3.5 hours
            hoursText = String(format: "%.1f", absHours)
        } else {
            hoursText = String(format: "%.2f", absHours)
        }

        return "\(sign)\(hoursText) hrs"
    }

    
    private func customName(for identifier: String) -> String? {
        if identifier == loc1, !loc1Name.isEmpty { return loc1Name }
        if identifier == loc2, !loc2Name.isEmpty { return loc2Name }
        if identifier == loc3, !loc3Name.isEmpty { return loc3Name }
        if identifier == loc4, !loc4Name.isEmpty { return loc4Name }
        if identifier == loc5, !loc5Name.isEmpty { return loc5Name }
        return nil
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    
    private var invertedLabelColor: Color {
        colorScheme == .dark ? .white : .black  // light on dark / dark on light
    }
    
    private func closeMenuBarPopover() {
        NSApplication.shared.keyWindow?.close()
    }
    
    private func clearFirstResponder() {
        if let window = NSApp.windows.first(where: { $0.isKeyWindow }) {
            window.makeFirstResponder(nil)
        }
    }
    
    struct RepeatButton<Label: View>: View {
        let action: () -> Void
        let label: () -> Label

        @State private var timer: Timer?
        @State private var startDate: Date?

        var body: some View {
            label()
                // normal click = single action
                .onTapGesture {
                    action()
                }
                // press & hold = start repeating
                .onLongPressGesture(
                    minimumDuration: 0.2,
                    maximumDistance: 10,
                    pressing: { isPressing in
                        if isPressing {
                            startRepeating()
                        } else {
                            stopRepeating()
                        }
                    },
                    perform: {
                        // nothing needed here; timer is doing the work
                    }
                )
        }

        private func startRepeating() {
            startDate = Date()
            
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
                let elapsed = Date().timeIntervalSince(startDate ?? Date())
                let multiplier: Int
                
                switch elapsed {
                case 0..<4:
                    multiplier = 1      // first four seconds: 1x
                case 4..<8:
                    multiplier = 2      // next four seconds: 2x
                case 8..<12:
                    multiplier = 32      // after 8 seconds: 4x
                case 12..<16:
                    multiplier = 128      // after 12 seconds: 32x
                case 16..<20:
                    multiplier = 512     // after 16 seconds: 64x
                case 20..<24:
                    multiplier = 1024    // after 20 seconds: 128x
                default:
                    multiplier = 1024     // after 24s: 128x
                }
                
                for _ in 0..<multiplier {
                    action()
                }
            }
            if let timer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }

        private func stopRepeating() {
            timer?.invalidate()
            timer = nil
            startDate = nil
        }
    }
    
    struct CloseShortcutsHandler: View {
        let action: () -> Void

        var body: some View {
            Group {
                // ESC key
                Button(action: action) {
                    EmptyView()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .frame(width: 0, height: 0)
                .opacity(0.001)
                .buttonStyle(.borderless)

                // ⌘W
                Button(action: action) {
                    EmptyView()
                }
                .keyboardShortcut("w", modifiers: [.command])
                .frame(width: 0, height: 0)
                .opacity(0.001)
                .buttonStyle(.borderless)
            }
        }
    }


    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // first block that shows "Local Time" and then the time
            VStack(alignment: .leading, spacing: 6) {
                if showLocalTime {
                    Text(localTimeLabel.isEmpty ? "Local Time" : localTimeLabel)
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    
                    HStack(spacing: 4) {
                        Text(formattedDate(for: .current))
                            .font(.body)
                            .foregroundStyle(.primary)
                        
                        Spacer()  // pushes the copy button to the right
                        
                        // time adjustment buttons
                        if showAdjustButtons {
                            HStack(spacing: 4) {
                                // -30 min button // "➖"
                                RepeatButton() {
                                    offsetMinutes -= 30
                                }
                                label: {
                                    Image(systemName: "minus.circle") //Text("−") // or Image(systemName: "minus.circle")
                                }
                                //.buttonStyle(.borderless)
                                .help("Subtract 30 minutes / Keep pressing and every 4s the speed will increase")
                                
                                // +30 min button // "➕"
                                RepeatButton() {
                                    offsetMinutes += 30
                                } label: {
                                    Image(systemName: "plus.circle") //Text("−") // or Image(systemName: "minus.circle")
                                }
                                //.buttonStyle(.borderless)
                                .help("Add 30 minutes / Keep pressing and every 4s the speed will increase")
                                
                                // Now button // "🟰"
                                RepeatButton() {
                                    offsetMinutes = 0
                                }
                                label: {
                                    Image(systemName: "arrow.counterclockwise") //Text("−") // or
                                }
                                //.buttonStyle(.borderless)
                                .help("Go to now")
                            }
                            .opacity(hoveredRowID == "local" ? 1 : 0)
                            .allowsHitTesting(hoveredRowID == "local")
                        }
                        
                        
                        // copy button
                        if showCopyButtons {
                            Button {
                                let value = formattedDate(for: .current)
                                copyToClipboard(value)
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .imageScale(.small)
                            }
                            .buttonStyle(.borderless)
                            .help("Copy to clipboard")
                        }
                    }
                    .contentShape(Rectangle())   // hover works over whole row
                    .onHover { inside in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredRowID = inside ? "local" : nil
                        }
                    }
                    
                    Divider()
                }
            }

            // second block that shows extra time zones from preferences
            if !selectedTimeZones.isEmpty {
                ForEach(selectedTimeZones) { city in
                    VStack(alignment: .leading, spacing: 6) {
                        // the city
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            let zone = TimeZone(identifier: city.identifier) ?? .current

                            Text(city.name)
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                            
                            Spacer()
                            
                            if showTimeDifferences {
                                Text("\(timeDifferenceString(for: zone))")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        // time/date for the city
                        HStack(spacing: 4) {
                            Text(formattedDate(for: TimeZone(identifier: city.identifier) ?? .current))
                                .font(.body)
                                .foregroundColor(invertedLabelColor)
                            
                            Spacer()  // pushes the copy button to the right
                            
                            
                            if showAdjustButtons {
                                HStack(spacing: 4) {
                                    // -30 min button // "➖"
                                    RepeatButton() {
                                        offsetMinutes -= 30
                                    }
                                    label: {
                                        Image(systemName: "minus.circle") //Text("−") // or Image(systemName: "minus.circle")
                                    }
                                    //.buttonStyle(.borderless)
                                    .help("Subtract 30 minutes")
                                    
                                    // +30 min button // "➕"
                                    RepeatButton() {
                                        offsetMinutes += 30
                                    } label: {
                                        Image(systemName: "plus.circle") //Text("−") // or Image(systemName: "minus.circle")
                                    }
                                    //.buttonStyle(.borderless)
                                    .help("Add 30 minutes")
                                    
                                    // Now button // "🟰"
                                    RepeatButton() {
                                        offsetMinutes = 0
                                    }
                                    label: {
                                        Image(systemName: "arrow.counterclockwise") //Text("−") // or
                                    }
                                    //.buttonStyle(.borderless)
                                    .help("Go to now")
                                }
                                .opacity(hoveredRowID == city.id ? 1 : 0)
                                .allowsHitTesting(hoveredRowID == city.id)
                            }
                            
                            // copy button
                            if showCopyButtons {
                                Button {
                                    let value = formattedDate(for: TimeZone(identifier: city.identifier) ?? .current)
                                    copyToClipboard(value)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .imageScale(.small)
                                }
                                .buttonStyle(.borderless)
                                .help("Copy to clipboard")
                            }
                        }
                        .contentShape(Rectangle())   // hover works over whole row
                        .onHover { inside in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                hoveredRowID = inside ? city.id : nil
                            }
                        }
                    }
                    
                    if city.id != selectedTimeZones.last?.id {
                        Divider()
                    }
                }
            }
            
            Divider()
            
            // settings and quit buttons
            VStack(alignment: .leading) {
                
                Toggle("Show Local Time", isOn: $showLocalTime)
                
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
        .onAppear {
            clearFirstResponder()
        }
        .background(
            CloseShortcutsHandler {
                closeMenuBarPopover()
            }
        )
    }
    
    private func formattedDate(for timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.timeZone = timeZone
        
        let adjustedNow = now.addingTimeInterval(TimeInterval(offsetMinutes * 60))

        return formatter.string(from: adjustedNow)
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
