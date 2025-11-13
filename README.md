# Simzone

Simzone is a tiny macOS menu bar app that helps you keep track of multiple time zones at a glance.

It sits in your menu bar and shows:

- Your **local time**
- Up to **five additional time zones**
- An optional **menu bar time display** (with your own label + emoji)

No accounts. No internet access. Just local Date/Time APIs and a small preferences window.

Learn more on why/how this was written, screenshots, and download the latest build from: [here](https://fryol.net/r/simzone/).

---

## Features

### Menu bar time (optional)

- Show the current time **directly in the menu bar** instead of an icon
- Choose **which time zone** the menu bar time should represent:
  - Local time
  - Any of your added time zones
- Use a **separate, compact format** for the menu bar (e.g. `HH:mm`, `EEE HH:mm`, `MMM dd HH:mm`)
- Optionally prepend a **short label** (up to 5 characters), e.g.:
  - `NYC 11:32`
  - `LON 07:32`
  - `🏠 21:14`

### Extra time zones

- Add up to **5 additional time zones** to the main Simzone popover
- Each zone:
  - Shows its current time using your chosen format
  - Can be **renamed** (“New York” → “HQ”, “Tokyo” → “Dev Team”)
  - Can be **reordered** using up/down arrows
  - Can be **removed** with a minus button

### Custom date & time formats

- A **Format** tab in Preferences lets you choose from multiple DateFormatter patterns, including:
  - `MMM dd EEE HH:mm`
  - `MM/dd/yy hh:mm a`
  - `EEE HH:mm`
  - And more variations with / without day, year, and 24-hour formats
- A live **preview** shows what the current time looks like in that format
- The main format is used for:
  - Local time in the popover
  - All additional time zones

### Menu bar emoji icon

When the “Show time in menu bar instead of icon” toggle is **off**, Simzone can show a **text/emoji icon** instead:

- Pick from a small set of built-in emojis:
  - `🚀` `🌐` `🏢` `🏠` `🗽` `♨️` `🌓`
- Or choose **“Bring Your Own”** and paste any emoji or single character
- A small `(i)` info button in Preferences gives tips on choosing emojis that fit well in the menu bar

### Preferences, nicely organized

The Preferences window is split into four tabs:

- **Format** – Global date & time format for the app
- **Time Zones** – Add, rename, reorder, and remove extra time zones
- **Menu Bar** – Control menu bar time vs icon, label, emoji, and format
- **About** – Version info, a short description, and the license

---

## Keyboard Shortcuts

Inside the Simzone popover:

- **Open Preferences**: `⌘,`
- **Quit Simzone**: `⌘Q` or click **Quit Simzone**

---

## Building & Running

Simzone is a standard SwiftUI macOS app.

### Requirements

- macOS (Ventura / Sonoma or later recommended)
- Xcode (15+ recommended)
- SwiftUI & Swift Concurrency toolchains included with Xcode

### Build steps

1. Clone or download the project.
2. Open `Simzone.xcodeproj` (or the `.xcworkspace` if you have one) in Xcode.
3. Select the **Simzone** scheme.
4. Build & run (`⌘R`).

Once running:

- A **Simzone** item appears in your menu bar.
- Click it to open the popover showing local time + configured zones.
- Go to **Settings…** from the popover (or press `⌘,`) to configure everything.

---

## Configuration Details

Simzone stores its settings using `@AppStorage` (UserDefaults), including:

- `simzoneDateFormat` – main display format
- `simzoneLocation1...simzoneLocation5` – selected time zone identifiers
- `simzoneLocation1Name...simzoneLocation5Name` – custom display names
- `simzoneShowTimeInMenuBar` – toggle for time vs icon in the menu bar
- `simzoneMenuBarShortName` – short label shown before the menu bar time
- `simzoneMenuBarTimeZoneId` – which time zone the menu bar time tracks
- `simzoneMenuBarFormat` – compact time format for the menu bar
- `simzoneMenuBarEmoji` – emoji/text shown when time is hidden

Everything is stored locally and can be reset by deleting the app’s preferences if needed.

---

## Design Notes

- **Update frequency**: times are refreshed every 10 seconds (no seconds shown, so no flicker).
- **Copyable text**: times in the popover are selectable so you can copy them quickly.
- **Reordering**: extra time zones are kept in a simple ordered list behind the scenes, and re-ordering keeps custom names attached to the right zone.

---

## Donations

Simzone is free and configurable.  
If you find it useful and feel like giving back, please consider donating to:

**[oneTreePlanted.org](https://oneTreePlanted.org)**

They plant trees. Trees are good. 🌲

---

## Feedback

Comments, questions, bugs, and feature requests welcome!

- 📧 Email: `sphinx-either-jeep@duck.com`

---

## License

Simzone is distributed under the terms of the license found in [`LICENSE`](./LICENSE).
