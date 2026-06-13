# Splitaa

A Flutter mobile app that scans receipts and lets a group split the bill — snap a
photo, crop it, the app reads the items, choose how to split, and it generates
per-person e-receipts you can save or share.

## Features

- **Receipt Scanner** — take a photo or pick from gallery; native crop UI lets you
  trim the image before OCR. ML Kit reads the receipt using **bounding-box geometry**
  to pair item names with their prices (even in separate columns), detects
  **quantities** (`2× Coke`, `Coke x2`), and ignores totals/tax/discount footers.
- **Split modes** (chosen right after scanning)
  - **Split evenly** — one shared bill; set tax / service charge / discount with a
    live total, then generate one receipt.
  - **Split by item** — name each person and tap the items they had. Assigning a
    unit decrements its quantity and removes it from the pool once used up, so the
    list shrinks for the next person. View the receipt photo anytime. At checkout,
    apply tax/discount; fixed RM amounts are divided equally across the whole party
    (splitters + you), while percentages apply to each person's own subtotal.
- **Receipt generator** — renders a clean receipt image (items, quantities, fees,
  total) with the payer's name banner and your **payment QR** embedded. Recipients
  can pay by scanning the QR inside the image with any banking app — no app needed.
- **Share & Save** — share the receipt image via any app, or save it directly to
  the device gallery.
- **Ledger** — every generated bill is saved; tap an entry to see the full itemized
  breakdown, set a **due-date reminder**, and mark it paid/unpaid. Overdue entries
  are highlighted in red.
- **Settings**
  - Upload your DuitNow/bank/e-wallet **payment QR** with crop + live scan
    validation (confirms the QR will be scannable on printed receipts).
  - Enable **notifications** for due-date reminders.
  - Pick a display currency and refresh exchange rates.
  - Export/import a signed backup.

## Tech Stack

| Layer | Library |
|---|---|
| UI | Flutter + Material 3 |
| State | Provider |
| OCR | google_mlkit_text_recognition |
| Barcode / QR scan | google_mlkit_barcode_scanning |
| Camera / Gallery | image_picker |
| Image crop | image_cropper |
| Gallery save | gal |
| Local DB | sqflite |
| Receipt image | screenshot |
| Sharing | share_plus |
| Notifications | flutter_local_notifications |
| Prefs / files | shared_preferences, path_provider |

## Flow

```
Scan ─▶ Crop ─▶ Split mode ─┬─ Even split ─▶ Fees ─▶ Receipt ─▶ Share / Save / Ledger
                            └─ By item ─▶ Assign per person ─▶ Checkout (fees) ─▶ Per-person receipts
```

## Project Status

| Area | Status |
|---|---|
| OCR scan + geometry parser + quantity detection | Done |
| Receipt crop before OCR | Done |
| Split mode chooser (even vs. by-item) | Done |
| Even split + fee calculator | Done |
| Per-person split + checkout + multi-receipt | Done |
| Fee division logic (fixed RM across party, % per person) | Done |
| Receipt image + embedded payment QR | Done |
| Share receipt + save to gallery | Done |
| Payment QR upload with crop + scan validation | Done |
| Ledger save + tappable detail + settle | Done |
| Due-date reminders (notifications) | Done |
| Settings: notifications / payment QR / currency / backup | Done |

## Getting Started

```bash
flutter pub get
flutter run
```

Requires an Android or iOS device/emulator. Camera, gallery, and notification
permissions are requested at runtime.
