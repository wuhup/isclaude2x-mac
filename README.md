# isclaude2x-mac

Native macOS status bar app for [isclaude2x.com](https://isclaude2x.com).

![Menu bar screenshot](docs/screenshot.png)

The app lives in the menu bar and shows:

- `yes` in green when `https://isclaude2x.com/short` returns `yes`
- `no` in red when `https://isclaude2x.com/short` returns `no`

It fetches once on launch, then polls every 15 minutes at 2 seconds after each quarter hour:

- `:00:02`
- `:15:02`
- `:30:02`
- `:45:02`

For example: `13:00:02`, `13:15:02`, `13:30:02`, `13:45:02`.

## Features

- Native SwiftUI macOS app
- Status bar only, with no Dock icon
- Manual refresh from the menu
- Open Website action
- Launch at Login toggle
- Keeps the last known status if a refresh fails

## Requirements

- macOS 13 or newer
- Xcode 26+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Development

Generate the Xcode project:

```bash
xcodegen generate
```

Run the test suite:

```bash
xcodebuild test \
  -project IsClaude2xMenuBar.xcodeproj \
  -scheme IsClaude2xMenuBar \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGNING_ALLOWED=NO
```

Build the app:

```bash
xcodebuild build \
  -project IsClaude2xMenuBar.xcodeproj \
  -scheme IsClaude2xMenuBar \
  -configuration Debug \
  -derivedDataPath ./.derivedData \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGNING_ALLOWED=NO
```

Launch the built app:

```bash
open ./.derivedData/Build/Products/Debug/IsClaude2xMenuBar.app
```

## Project Files

- `Sources/IsClaude2xMenuBar/` contains the app code
- `Tests/IsClaude2xMenuBarTests/` contains unit tests for parsing, refresh behavior, and poll scheduling
- `project.yml` is the XcodeGen project spec

## Upstream

This app is a native macOS client for [mehulmpt/isclaude2x](https://github.com/mehulmpt/isclaude2x).
