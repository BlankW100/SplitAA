# Splitaa

A Flutter mobile app that scans receipts and lets a group split the bill — each person picks their items and the app tallies their share including tax and service fee.

## Features

- **Receipt Scanner** — take a photo or pick from gallery; ML Kit OCR extracts the text
- **Split Calculator** — select items per person, set tax % and service fee %, see live subtotal/total
- **Ledger** — track who owes what and mark debts as settled
- **Settings** — placeholder for QR code / personal profile (in progress)

## Tech Stack

| Layer | Library |
|---|---|
| UI | Flutter + Material 3 |
| State | Provider |
| OCR | google_mlkit_text_recognition |
| Camera / Gallery | image_picker |
| Local DB | sqflite |
| QR Code | qr_flutter (pending) |
| Notifications | flutter_local_notifications (pending) |

## Project Status

| Area | Status |
|---|---|
| OCR service | Done |
| Camera/gallery picker | Done |
| Split calculator logic | Done |
| SQLite ledger CRUD | Done |
| Scanner → item parser | **In progress** |
| Scanner ↔ Calculator wiring | **Pending** |
| Add-entry UI on Ledger screen | **Pending** |
| QR / share / notifications | **Pending** |
| Settings screen | **Pending** |

## Getting Started

```bash
flutter pub get
flutter run
```

Requires Android or iOS device/emulator. Camera and gallery permissions are requested at runtime.
