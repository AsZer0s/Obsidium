# Obsidium

A minimal, local-first TOTP (2FA) authenticator for iOS. No cloud, no accounts,
no sync — it does one job: show 2FA codes. Secrets live only in the device
Keychain.

- **TOTP** generation per RFC 6238 (SHA1/256/512, 6/8 digits, custom period)
- **Import** accounts by scanning `otpauth://` QR codes
- **List** of tokens with a live 30s countdown ring; tap a row to copy
- **Storage** in the iOS Keychain (device-only, never iCloud-synced)
- **Edit** a token's name, account, or key; **backup** export & import/restore
- **Face ID** (optional) gating delete & export

## Requirements

- Xcode 26+ and a Mac
- iOS 26+ deployment target
- [XcodeGen](https://github.com/yonsei/XcodeGen) (`brew install xcodegen`) — the
  Xcode project is generated from `project.yml`, not committed
- A physical device to scan QR codes (the camera is unavailable in the Simulator)

## Getting started

```bash
brew install xcodegen      # one-time
xcodegen generate          # creates Obsidium.xcodeproj from project.yml
open Obsidium.xcodeproj     # then build/run as usual
```

`Obsidium.xcodeproj` is git-ignored on purpose — `project.yml` is the single
source of truth. Re-run `xcodegen generate` whenever you add files or change
build settings. The camera usage string and launch screen are injected via
build settings in `project.yml` (no hand-maintained Info.plist).

## Project layout

```
Obsidium/
├── ObsidiumApp.swift          # @main entry, injects VaultStore
├── Core/
│   ├── Account.swift          # model + OTPAlgorithm
│   ├── Base32.swift           # RFC 4648 decoder
│   └── TOTPGenerator.swift    # RFC 6238 generation + countdown helpers
├── Storage/
│   └── KeychainVault.swift    # load/save the account list as one JSON blob
├── State/
│   └── VaultStore.swift       # @Observable single source of truth
├── Import/
│   ├── OTPAuthParser.swift    # otpauth:// -> Account
│   └── QRScannerView.swift    # AVFoundation camera scanner
└── UI/
    ├── Theme.swift            # design tokens: spacing, radii, dark palette
    ├── TokenListView.swift    # main screen (dark, card list, empty state)
    ├── TokenCardView.swift    # one token as a "security card" (code = hero)
    ├── ScannerScreen.swift    # scan sheet + permission handling
    └── Components/
        └── CountdownRing.swift # demoted ring + chip + ambient bar
ObsidiumTests/                 # Swift Testing unit tests
project.yml                    # XcodeGen project spec
ExportOptions.plist            # for a future *signed* export (see CI notes)
.github/workflows/ios-build.yml
```

## Continuous integration

`.github/workflows/ios-build.yml` runs on every push/PR to `main` (and manually
via *Run workflow*). On a `macos-latest` runner it:

1. installs XcodeGen and runs `xcodegen generate`,
2. runs the unit tests on an auto-detected iPhone simulator,
3. archives the app in **Release**, fully unsigned
   (`CODE_SIGNING_ALLOWED=NO`, `CODE_SIGNING_REQUIRED=NO`),
4. hand-packages the `.app` into an **unsigned `.ipa`** (`Payload/` zip — because
   `-exportArchive` always wants a signing identity), and
5. uploads the IPA and the build logs as artifacts.

`ExportOptions.plist` is unused today; keep it for when you add a real signing
certificate and switch the export step to `-exportArchive -exportOptionsPlist`.

## Git & GitHub

The repo is initialized with `main` as the default branch. To push to a GitHub
repo you created manually (no GitHub CLI required):

```bash
git remote add origin https://github.com/<you>/Obsidium.git
git branch -M main
git push -u origin main
```

(Use the SSH URL `git@github.com:<you>/Obsidium.git` instead if you have SSH keys
set up.)

## Verifying

- **Unit tests** (`Cmd-U`, or CI): TOTP output is checked against the official
  RFC 6238 Appendix B vectors for SHA1/256/512; Base32 against RFC 4648 vectors;
  the parser against representative `otpauth://` URIs.
- **End-to-end** (device): tap **+**, scan a real QR code, and compare Obsidium's
  code against another authenticator (e.g. Google Authenticator / 1Password).
- **Persistence**: add a token, force-quit, relaunch — it should still be there.

## Out of scope (by design)

Cloud sync, accounts/login, backend, multi-device sync, analytics, subscriptions,
HOTP, manual secret entry, export/backup, and Face ID lock (deferred).
