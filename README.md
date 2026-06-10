# Splitaa

A Flutter mobile app that scans receipts and lets a group split the bill — snap a
photo, the app reads the items, choose how to split, and it generates per-person
e-receipts with payment QRs.

## Features

- **Receipt Scanner** — take a photo or pick from gallery; ML Kit OCR reads the
  receipt. The parser uses text **bounding-box geometry** to pair item names with
  their prices (even when they sit in separate columns), detects **quantities**
  (`2× Coke`, `Coke x2`), and ignores the totals/tax/discount footer so summary
  lines aren't scanned as products.
- **Split modes** (chosen right after scanning)
  - **Split evenly** — one shared bill; set tax / service charge / discount with a
    live total, then generate one receipt.
  - **Split by item** — name each person and tap the items they had. Assigning a
    unit decrements its quantity and removes it from the pool once used up, so the
    list shrinks for the next person. View the receipt photo anytime. At checkout,
    apply tax/discount; fixed RM amounts are divided equally across the whole party
    (splitters + you), while percentages apply to each person's own subtotal. Then
    generate one receipt per person.
- **Receipt generator** — renders a clean receipt image (items, quantities, fees,
  total) with the payer's name banner and your **payment QR** embedded.
- **Share & QR** — share the receipt image, or show a QR encoding the bill data.
- **Ledger** — every generated bill can be saved; tap an entry to see the full
  itemized breakdown and mark it paid/unpaid.
- **Settings** — upload your DuitNow/bank/e-wallet **payment QR** (printed on every
  receipt), pick a display currency, refresh exchange rates, and export/import a
  signed backup.

## Tech Stack

| Layer | Library |
|---|---|
| UI | Flutter + Material 3 |
| State | Provider |
| OCR | google_mlkit_text_recognition |
| Camera / Gallery | image_picker |
| Local DB | sqflite |
| Receipt image | screenshot |
| QR code | qr_flutter |
| Sharing | share_plus |
| Prefs / files | shared_preferences, path_provider |

## Flow

```
Scan ─▶ Split mode ─┬─ Even split ─▶ Fees ─▶ Receipt ─▶ Share / QR / Ledger
                   └─ By item ─▶ Assign per person ─▶ Checkout (fees) ─▶ Per-person receipts
```

## Project Status

| Area | Status |
|---|---|
| OCR scan + geometry parser + quantity detection | Done |
| Split mode chooser (even vs. by-item) | Done |
| Even split + fee calculator | Done |
| Per-person split + checkout + multi-receipt | Done |
| Fee division logic (fixed RM across party, % per person) | Done |
| Receipt image + embedded payment QR | Done |
| Ledger save + tappable detail + settle | Done |
| Settings: payment QR / currency / backup | Done |
| Peer-import QR scanner (receive a shared bill) | Pending |
| Due-date reminders (notifications) | Pending |

## Getting Started

```bash
flutter pub get
flutter run
```

Requires an Android or iOS device/emulator. Camera and gallery permissions are
requested at runtime.
