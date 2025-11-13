//
//  PreferencesView.swift
//  Simzone
//
//  Author: Rishi Pande
//  Date: 11/11/25
//

import SwiftUI
import AppKit

struct PreferencesView: View {
    @AppStorage("simzoneDateFormat")
    private var dateFormat: String = "MMM dd EEE hh:mm a"
    
    @State private var exampleNow = Date()

    private let formatOptions: [(label: String, pattern: String)] = [
        ("MON DD DAY hh:MM AM/PM",          "MMM dd EEE hh:mm a"),
        ("MON DD DAY HH:MM (24 hr)",        "MMM dd EEE HH:mm"),
        ("MON DD hh:MM AM/PM",              "MMM dd hh:mm a"),
        ("MON DD HH:MM (24 hr)",            "MMM dd HH:mm"),
        ("MON DD YYYY DAY HH:MM (24 hr)",   "MMM dd yyyy EEE HH:mm"),
        ("MM/DD/YY hh:MM AM/PM",            "MM/dd/yy hh:mm a"),
        ("MM/DD hh:MM AM/PM",               "MM/dd hh:mm a"),
        ("MM/DD HH:MM (24 hr)",             "MM/dd HH:mm"),
        ("MM/DD DAY hh:MM AM/PM",           "MM/dd EEE hh:mm a"),
        ("MM/DD DAY HH:MM (24 hr)",         "MM/dd EEE HH:mm"),
        ("DD/MM DAY hh:MM AM/PM",           "dd/MM EEE hh:mm a"),
        ("DD/MM DAY HH:MM (24 hr)",         "dd/MM EEE HH:mm"),
        ("DD DAY hh:MM AM/PM",              "dd EEE hh:mm a"),
        ("DD DAY HH:MM (24 hr)",            "dd EEE HH:mm"),
        ("DAY hh:MM AM/PM",                 "EEE hh:mm a"),
        ("DAY HH:MM (24 hr)",               "EEE HH:mm")
    ]
    
    // Menu bar-specific format options (smaller set)
    private let menuBarFormatOptions: [(label: String, pattern: String)] = [
        ("HH:MM (24 hr)",           "HH:mm"),
        ("hh:MM AM/PM",             "hh:mm a"),
        ("DAY HH:MM (24 hr)",       "EEE HH:mm"),
        ("DAY hh:MM AM/PM",         "EEE hh:mm a"),
        ("MON DD HH:MM (24 hr)",    "MMM dd HH:mm"),
        ("MON DD hh:MM AM/PM",      "MMM dd hh:mm a")
    ]

    @State private var licenseText: String = ""

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
    
    @AppStorage("simzoneShowTimeInMenuBar") private var showTimeInMenuBar: Bool = false
    @AppStorage("simzoneMenuBarShortName") private var menuBarShortName: String = ""
    @AppStorage("simzoneMenuBarTimeZoneId") private var menuBarTimeZoneId: String = "local"
    @AppStorage("simzoneMenuBarFormat") private var menuBarFormat: String = "HH:mm"
    @AppStorage("simzoneMenuBarEmoji") private var menuBarEmoji: String = "🌖"

    @State private var emojiPickerSelection: String = "🌖"
    @State private var showEmojiInfo = false

    private let menuBarEmojiOptions: [String] = [
        "🚀", "🌐", "🏢", "🏠", "🗽", "♨️", "🌓", "🌖"
    ]
    
    private let customEmojiTag = "custom"
    
    @State private var newTimeZoneId: String = TimeZone.current.identifier

    // For the dropdown options
    struct ZoneOption: Identifiable {
        let id: String        // time zone identifier
        let label: String     // "City (UTC +8)" etc.
    }

    // Current selected locations, in order
    private var currentLocationIds: [String] {
        [loc1, loc2, loc3, loc4, loc5].filter { !$0.isEmpty }
    }
    
    private func displayName(for identifier: String) -> String {
        let parts = identifier.split(separator: "/")
        if let last = parts.last {
            return last.replacingOccurrences(of: "_", with: " ")
        }
        return identifier
    }

    private func utcOffsetString(for timeZone: TimeZone, at date: Date) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let hours = Double(seconds) / 3600.0
        let sign = hours >= 0 ? "+" : "-"
        let absHours = abs(hours)
        
        let text: String
        if absHours == floor(absHours) {
            text = String(format: "%.0f", absHours)
        } else if (absHours * 2).truncatingRemainder(dividingBy: 1) == 0 {
            text = String(format: "%.1f", absHours)
        } else {
            text = String(format: "%.2f", absHours)
        }
        
        return "UTC \(sign)\(text)"
    }

    // All time zone options, sorted alphabetically by city name
    private var zoneOptions: [ZoneOption] {
        let now = Date()
        
        return TimeZone.knownTimeZoneIdentifiers.compactMap { id in
            guard let tz = TimeZone(identifier: id) else { return nil }
            let city = displayName(for: id)
            let offset = utcOffsetString(for: tz, at: now)
            return ZoneOption(id: id, label: "\(city) (\(offset))")
        }
        .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
    }

    private func addSelectedTimeZone() {
        guard !currentLocationIds.contains(newTimeZoneId) else { return }
        
        if loc1.isEmpty {
            loc1 = newTimeZoneId
        } else if loc2.isEmpty {
            loc2 = newTimeZoneId
        } else if loc3.isEmpty {
            loc3 = newTimeZoneId
        } else if loc4.isEmpty {
            loc4 = newTimeZoneId
        } else if loc5.isEmpty {
            loc5 = newTimeZoneId
        }
    }
    
    // Helpers for names / reorder / remove
    
    private func bindingForName(for identifier: String) -> Binding<String> {
        if identifier == loc1 { return $loc1Name }
        if identifier == loc2 { return $loc2Name }
        if identifier == loc3 { return $loc3Name }
        if identifier == loc4 { return $loc4Name }
        if identifier == loc5 { return $loc5Name }
        return .constant("")
    }

    private func applyReorder(_ transform: ([String]) -> [String]) {
        var namesById: [String: String] = [:]
        if !loc1.isEmpty { namesById[loc1] = loc1Name }
        if !loc2.isEmpty { namesById[loc2] = loc2Name }
        if !loc3.isEmpty { namesById[loc3] = loc3Name }
        if !loc4.isEmpty { namesById[loc4] = loc4Name }
        if !loc5.isEmpty { namesById[loc5] = loc5Name }

        var ids = currentLocationIds
        ids = transform(ids)
        
        loc1 = ""; loc2 = ""; loc3 = ""; loc4 = ""; loc5 = ""
        loc1Name = ""; loc2Name = ""; loc3Name = ""; loc4Name = ""; loc5Name = ""
        
        for (index, id) in ids.prefix(5).enumerated() {
            let name = namesById[id] ?? ""
            switch index {
            case 0:
                loc1 = id; loc1Name = name
            case 1:
                loc2 = id; loc2Name = name
            case 2:
                loc3 = id; loc3Name = name
            case 3:
                loc4 = id; loc4Name = name
            case 4:
                loc5 = id; loc5Name = name
            default:
                break
            }
        }
    }
    
    private func moveLocation(from: Int, to: Int) {
        applyReorder { current in
            var arr = current
            let clampedTo = max(0, min(arr.count - 1, to))
            let item = arr.remove(at: from)
            arr.insert(item, at: clampedTo)
            return arr
        }
    }
    
    private func removeLocation(at index: Int) {
        applyReorder { current in
            var arr = current
            if index < arr.count {
                arr.remove(at: index)
            }
            return arr
        }
    }
    
    @ViewBuilder
    private func locationRow(
        index: Int,
        identifier: String,
        name: Binding<String>,
        canMoveUp: Bool,
        canMoveDown: Bool
    ) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(displayName(for: identifier))
                    .font(.footnote)
                
                Text(identifier)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            TextField("Rename", text: name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 160)
            
            HStack(spacing: 4) {
                Button {
                    moveLocation(from: index, to: index - 1)
                } label: {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.borderless)
                .disabled(!canMoveUp)
                
                Button {
                    moveLocation(from: index, to: index + 1)
                } label: {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.borderless)
                .disabled(!canMoveDown)
                
                Button {
                    removeLocation(at: index)
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderless)
            }
        }
    }
    
    // Date format picker helpers
    
    private func sampleLabel(for pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = pattern
        formatter.timeZone = .current
        return formatter.string(from: exampleNow)
    }
    
    private var dateFormatBinding: Binding<String> {
        Binding(
            get: {
                if formatOptions.contains(where: { $0.pattern == dateFormat }) {
                    return dateFormat
                } else {
                    return formatOptions.first?.pattern ?? "EEE hh:mm a"
                }
            },
            set: { newValue in
                dateFormat = newValue
            }
        )
    }

    private var menuBarFormatBinding: Binding<String> {
        Binding(
            get: {
                if menuBarFormatOptions.contains(where: { $0.pattern == menuBarFormat }) {
                    return menuBarFormat
                } else {
                    return menuBarFormatOptions.first?.pattern ?? "HH:mm"
                }
            },
            set: { newValue in
                menuBarFormat = newValue
            }
        )
    }
    
    struct MenuBarZoneOption: Identifiable {
        let id: String      // "local" or time zone identifier
        let label: String   // what to show in the picker
    }

    private func customName(for identifier: String) -> String? {
        if identifier == loc1, !loc1Name.isEmpty { return loc1Name }
        if identifier == loc2, !loc2Name.isEmpty { return loc2Name }
        if identifier == loc3, !loc3Name.isEmpty { return loc3Name }
        if identifier == loc4, !loc4Name.isEmpty { return loc4Name }
        if identifier == loc5, !loc5Name.isEmpty { return loc5Name }
        return nil
    }

    private var menuBarZoneOptions: [MenuBarZoneOption] {
        var result: [MenuBarZoneOption] = [
            MenuBarZoneOption(id: "local", label: "Local Time")
        ]
        
        for id in currentLocationIds {
            let name = customName(for: id) ?? displayName(for: id)
            result.append(MenuBarZoneOption(id: id, label: name))
        }
        
        return result
    }

    private var appVersionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "Version \(version) (\(build))"
    }
    
    
    // Body
    
    var body: some View {
        TabView {
            formatTab
                .tabItem { Text("Date/Time Format") }
            
            timeZonesTab
                .tabItem { Text("Time Zones") }
            
            menuBarTab
                .tabItem { Text("Menu Bar") }
            
            aboutTab
                .tabItem { Text("About") }
        }
        .padding(20)
        .onAppear {
            exampleNow = Date()
            
            if !formatOptions.contains(where: { $0.pattern == dateFormat }) {
                dateFormat = formatOptions.first?.pattern ?? "EEE hh:mm a"
            }
            if !menuBarFormatOptions.contains(where: { $0.pattern == menuBarFormat }) {
                menuBarFormat = menuBarFormatOptions.first?.pattern ?? "HH:mm"
            }
            if !menuBarZoneOptions.contains(where: { $0.id == menuBarTimeZoneId }) {
                menuBarTimeZoneId = "local"
            }
            emojiPickerSelection = menuBarEmojiOptions.contains(menuBarEmoji) ? menuBarEmoji : customEmojiTag
            
            if let asset = NSDataAsset(name: "LICENSE"),
               let text = String(data: asset.data, encoding: .utf8) {
                licenseText = text
            } else {
                licenseText = "LICENSE file not found in assets."
            }
        }
    }

    // Tabs
    
    private var formatTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
            
            Text("Use a custom DateFormatter format string.")
            
            Picker("Format", selection: dateFormatBinding) {
                ForEach(formatOptions, id: \.pattern) { option in
                    Text(sampleLabel(for: option.pattern))
                        .tag(option.pattern)
                }
            }
            .pickerStyle(.menu)
            .font(.system(.body, design: .monospaced))
            
            Spacer()
        }
    }

    private var timeZonesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()

            Text("Add up to 5 additional time zones to show in Simzone.")

            HStack {
                Picker("Add Time Zone", selection: $newTimeZoneId) {
                    ForEach(zoneOptions) { option in
                        Text(option.label)
                            .tag(option.id)
                    }
                }
                .labelsHidden()
                
                Button("Add") {
                    addSelectedTimeZone()
                }
                .disabled(
                    currentLocationIds.count >= 5 ||
                    currentLocationIds.contains(newTimeZoneId)
                )
            }

            if !currentLocationIds.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Currently added:")
                        .font(.subheadline)
                    
                    ForEach(Array(currentLocationIds.enumerated()), id: \.element) { index, id in
                        locationRow(
                            index: index,
                            identifier: id,
                            name: bindingForName(for: id),
                            canMoveUp: index > 0,
                            canMoveDown: index < currentLocationIds.count - 1
                        )
                    }
                }
            }

            Spacer()
        }
    }

    private var menuBarTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
            
            HStack(spacing: 8) {
                Text("Simzone icon (Emoji)")
                
                Button {
                    showEmojiInfo.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Click for tips")
                .popover(isPresented: $showEmojiInfo, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Emoji Tips")
                            .font(.headline)
                        Text("""
                        • You can set your own emoji - just select "Bring Your Own".
                        • Paste any emoji (or any single character).
                        • The menu bar is tight on space—keep it to 1 char.
                        • Some emojis render wider; test a few to see what fits.
                        """)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        Button("Got it") { showEmojiInfo = false }
                            .keyboardShortcut(.defaultAction)
                            .padding(.top, 6)
                    }
                    .padding(12)
                    .frame(width: 280)
                }
                
                Picker("Simzone icon (Emoji Actually)", selection: $emojiPickerSelection) {
                    ForEach(menuBarEmojiOptions, id: \.self) { emoji in
                        Text(emoji)
                            .tag(emoji)
                    }
                    //Divider()
                    Text("Bring Your Own")
                        .tag(customEmojiTag)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .onChange(of: emojiPickerSelection) {
                    if emojiPickerSelection != customEmojiTag {
                        menuBarEmoji = emojiPickerSelection
                    }
                }
                
                if emojiPickerSelection == customEmojiTag {
                    TextField("🙂", text: $menuBarEmoji)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 40)
                        .multilineTextAlignment(.center)
                }
            }

            // Toggle controls whether the rest is active
            Toggle("Show time in menu bar instead of icon", isOn: $showTimeInMenuBar)

            // Everything AFTER the toggle gets grayed out & disabled when it's off
            Group {
                VStack(alignment: .leading, spacing: 4) {
                    Picker("Time zone to show", selection: $menuBarTimeZoneId) {
                        ForEach(menuBarZoneOptions) { option in
                            Text(option.label)
                                .tag(option.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                HStack(spacing: 8) {
                    Text("Short pre-fix label (optional / 5 char limit)")

                    TextField("e.g. NYC🗽", text: $menuBarShortName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .onChange(of: menuBarShortName) {
                            if menuBarShortName.count > 5 {
                                menuBarShortName = String(menuBarShortName.prefix(5))
                            }
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Picker("Menu Bar Time Format", selection: menuBarFormatBinding) {
                        ForEach(menuBarFormatOptions, id: \.pattern) { option in
                            Text(sampleLabel(for: option.pattern))
                                .tag(option.pattern)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.system(.body, design: .monospaced))
                }
            }
            .disabled(!showTimeInMenuBar)
            .opacity(showTimeInMenuBar ? 1.0 : 0.5)
        
            Spacer()
        }
    }
    
    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()

            Text("Simzone \(appVersionString)")
                .font(.subheadline)
                .bold()
                        
            Text("Free and configurable app, but if you like it, please donate at https://oneTreePlanted.org. Comments, questions, bugs, feature-requests welcome at: https://github.com/rishipande/simzone. See license below.")
                .font(.callout)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            // Scrollable license block
            ScrollView {
                Text(licenseText)
                    .font(.caption)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 80)   // keep it from taking over the window
            .border(Color.secondary.opacity(0.2))
        }
    }
}

#Preview {
    PreferencesView()
        .frame(width: 460, height: 260)
}
