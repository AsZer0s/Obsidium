# Obsidium Real-Device Regression Checklist

Run this on a physical iPhone before a TestFlight or App Store build. The Simulator cannot fully cover camera, Face ID, or real Keychain lifecycle behavior.

## Add tokens

- [ ] Tap **+ → Scan QR Code**, scan a valid `otpauth://totp` QR, and confirm the token appears.
- [ ] Tap **+ → Enter Setup Key**, enter service name, account label, and a Base32 setup key, then save.
- [ ] In manual add, verify **Add** is disabled for an invalid key and enabled for a valid key.
- [ ] If a service provides non-default parameters, set **Algorithm**, **Digits**, and **Period** in Advanced and compare the code with another authenticator.
- [ ] Tap **Choose from Album** in the scanner, select a QR screenshot, and confirm import works.

## Codes and search

- [ ] Pull out a card and verify the code refreshes on the expected period boundary.
- [ ] Tap the pulled-out card and confirm the code is copied and the toast appears.
- [ ] Search by service name.
- [ ] Search by account label/email.
- [ ] Search for a non-matching term and confirm the empty search state appears.
- [ ] Clear search and confirm the full deck returns.

## Management

- [ ] Open **Settings → Manage Tokens**.
- [ ] Edit a token's name, account label, setup key, advanced parameters, and brand mark.
- [ ] Reorder tokens with Edit mode and confirm the deck order persists after relaunch.
- [ ] Delete a token and confirm it is removed.

## Face ID / passcode

- [ ] Enable **Lock with Face ID** and complete the confirmation prompt.
- [ ] Background the app, reopen it, and confirm the lock overlay appears.
- [ ] Unlock successfully with Face ID/passcode fallback.
- [ ] Enable **Face ID for delete & export** and confirm delete requires authentication.
- [ ] Confirm exporting a backup requires authentication when the toggle is enabled.

## Persistence and backup

- [ ] Add at least two tokens, force-quit, relaunch, and confirm tokens remain.
- [ ] Export an encrypted backup with a strong password.
- [ ] Attempt restore with the wrong password and confirm it fails without changing tokens.
- [ ] Restore with the correct password and confirm the prompt explains merge behavior.
- [ ] Confirm restore merges into the current vault: existing tokens remain and new backup tokens are added.
- [ ] Confirm duplicate scans/backups do not create duplicate token entries for the same account.
