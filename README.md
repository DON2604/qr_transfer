# AirTransfer QR

Transfer files between devices using nothing but a camera and a screen — no Wi-Fi, no Bluetooth, no cables, no internet.

AirTransfer QR encodes any file into an animated stream of QR codes and reassembles it on the receiving device after scanning every frame. Because the channel is purely optical, it works across air-gapped networks and in environments where radio communication is restricted or unavailable.

---

## How it works

```
Sender                                   Receiver
──────                                   ────────
Pick file                                Open scanner
   │                                          │
   ▼                                          │
SHA-256 hash                                  │
   │                                          │
   ▼                                          │
Split into N raw byte chunks                  │
   │                                          │
   ▼                                          │
Base64-encode each chunk                      │
   │                                          │
   ▼                                          │
Build metadata frame (META:…)                 │
Build data frames   (DAT:…)                   │
   │                                          │
   ▼                                          │
Animate QR stream  ──────── camera ──────►   Decode each frame
(header + chunks)                            Track received chunks
                                                  │
                                                  ▼
                                             All chunks received?
                                                  │
                                                  ▼
                                             Reassemble bytes
                                                  │
                                                  ▼
                                             Verify SHA-256 hash
                                                  │
                                                  ▼
                                             Save to device
```

Each QR frame carries a self-describing payload:

| Frame type | Prefix | Contents |
|---|---|---|
| Metadata | `META:` | JSON with file name, size, total chunks, chunk size, SHA-256 hash, transfer ID |
| Data chunk | `DAT:` | `transferId:chunkIndex:totalChunks:<base64 bytes>` |

The receiver can capture frames in any order. Once every chunk index is present the file is assembled and integrity-checked automatically.

---

## Features

- **Air-gapped transfer** — works with zero network connectivity
- **Any file type** — images, audio, video, documents, binaries
- **Integrity verification** — SHA-256 hash checked after assembly
- **Adjustable speed** — 2–15 FPS playback, configurable chunk size (200 / 350 / 500 B)
- **Live progress grid** — per-chunk visual feedback on the receiver
- **Transfer history** — received files persist locally with open / share / delete actions
- **Dark theme** — restrained Material 3 palette, Inter typeface

---

## Architecture

```
lib/
├── main.dart                        # App entry point
│
├── models/                          # Pure data classes, no Flutter imports
│   ├── transfer_metadata.dart       # TransferMetadata + DataChunk (QR frame models)
│   └── transfer_file_info.dart      # Persisted record of a received file
│
├── services/                        # Stateless business logic
│   ├── qr_encoder_service.dart      # File → QrStreamPackage (chunking + hashing)
│   ├── qr_decoder_service.dart      # Raw QR payloads → assembled bytes
│   └── file_storage_service.dart    # Disk I/O, history persistence, open/share
│
└── ui/
    ├── theme/
    │   └── app_theme.dart           # AppColors + AppTheme (Material 3 dark)
    ├── widgets/
    │   └── glass_card.dart          # Shared surface card component
    ├── sender/
    │   ├── file_selector_card.dart  # File picker with category buttons
    │   └── qr_stream_player.dart    # Animated QR stream with playback controls
    ├── receiver/
    │   ├── qr_scanner_view.dart     # Camera feed + assembly orchestration
    │   └── chunk_progress_grid.dart # Per-chunk received/pending visualisation
    ├── history/
    │   └── history_screen.dart      # List of received files with actions
    └── home_screen.dart             # Tab host (Send / Receive / History)
```

### Layer responsibilities

**Models** hold raw data only. They know how to serialise/deserialise themselves (JSON, QR string format) but have no side effects.

**Services** are stateless utility classes with static or instance methods. They contain all algorithmic logic — chunking, hashing, base64 encoding, file I/O — keeping it fully testable without a Flutter environment.

**UI** is kept as thin as possible. Widgets call services directly and own only the state that drives their own rendering (selected file, current frame index, loading flags). No widget reaches into another widget's state.

### Data flow — sending

```
FileSelectorCard
  └─ picks file → SelectedFileInfo (name, bytes, category)
       └─ passed to QrStreamPlayer via HomeScreen callback
            └─ QrEncoderService.encodeFile() → QrStreamPackage
                 └─ Timer drives frame index → QrImageView renders payload
```

### Data flow — receiving

```
MobileScanner (camera)
  └─ BarcodeCapture → QrScannerView._onDetect()
       └─ QrDecoderService.processScannedPayload()
            ├─ META frame → stores TransferMetadata
            └─ DAT frame  → stores chunk in Map<int, String>
                 └─ all chunks present → assembleFile()
                      └─ FileStorageService.saveReceivedFile()
                           └─ TransferFileInfo saved to history
```

---

## Dependencies

| Package | Purpose |
|---|---|
| `qr_flutter` | QR code rendering |
| `mobile_scanner` | Camera-based QR decoding |
| `file_picker` | Native file picker dialog |
| `path_provider` | App documents directory |
| `share_plus` | Native share sheet |
| `open_filex` | Open file with device default app |
| `crypto` | SHA-256 hashing |
| `google_fonts` | Inter typeface |
| `permission_handler` | Camera permission |

---

## Getting started

```bash
# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run

# Build release APK
flutter build apk --release
```

Camera permission is required on the Receive tab. The app will prompt for it automatically on first use.

---

## Limitations

- Transfer speed is bounded by QR scanning throughput — large files require patience
- Receiver must maintain line-of-sight with the sender screen for the full transfer
- Maximum reliable payload per QR frame is around 500 bytes (higher error correction reduces this further)
- Currently targets Android; iOS and desktop builds are scaffolded but untested
