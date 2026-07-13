# ARObjectTranslator (SwiftUI + ARKit)

A standalone iOS SwiftUI app that scans only a user-selected area, auto-detects source language, translates to a user-selected target language, and places translated text as an AR overlay near the selected object area.

## Features

- AR camera view powered by `ARKit` + `RealityKit`
- Drag-and-resize selection region; only this region is OCR-processed
- OCR via `Vision` (`VNRecognizeTextRequest`)
- Source language autodetection via `NaturalLanguage` (`NLLanguageRecognizer`)
- Target language picker before scanning
- AR translation overlay anchored using raycasting at selected screen location
- Soft UI style optimized for quick one-handed use

## Requirements

- Xcode 16+
- iOS 17.0+ (camera + AR)
- Internet connection for translation requests (OCR and language detection are on-device)
