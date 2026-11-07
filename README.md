# Teacher Question Paper Generator

Offline-first Flutter source project for Android and Chrome. The project is designed for teachers who want to import DOCX question banks, prepare papers automatically or manually, and export the result.

## What is included

- Examination setup (standard, board, subject, exam name and date).
- Import up to five `.docx` question-bank files in one preparation session.
- Assign marks to each uploaded file, including custom mark values.
- Local question parsing from Word paragraph XML, including numbered/list paragraphs and multi-line continuation paragraphs.
- Review/edit detected questions and review flags for ambiguous boundaries / Office Math content.
- Automatic random selection by mark category, with within-paper duplicate prevention.
- Optional exclusion of previously used questions for the saved question bank.
- Manual search, category filtering and question selection.
- Local persistence: IndexedDB in Chrome; a local application database file on Android.
- A4-style preview, PDF sharing/printing, and DOCX export.
- Saved question-bank reuse and generated-paper history.
- Unit tests for marks calculation, random selection, exclusion and unavailable combinations.
- Sample DOCX banks in `sample_question_banks/`.

## Important limitations (read before using with important exams)

1. **DOCX import is paragraph-text extraction, not a full Microsoft Word renderer.** It reads text from Word document XML locally. It does not retain the original paragraph styling, images, floating objects, table layout, embedded objects, or complete equation structure. Table paragraphs are encountered in document order, but complex table layout is not reconstructed.
2. **Office Math (OMML) and special formatting:** text inside math runs is extracted where available and flagged for review. Superscripts, fractions, matrices, equation layout and some symbols may not survive as visually equivalent content. Review these questions against the original Word document before using them.
3. **Question-boundary detection is heuristic.** Explicit question numbering and Word numbered/bulleted paragraphs are used as boundaries. Sub-question bullets may be interpreted as separate questions. Unnumbered or uncertain items are flagged. Always review the imported list.
4. **DOCX export creates a new clean document from the selected question text.** It does not embed original source formatting or equation objects. The PDF exporter uses the PDF package's built-in fonts; complex scripts and uncommon glyphs may require font embedding to render correctly.
5. The ZIP was assembled in an environment without the Flutter SDK, so **Flutter compilation, Android execution, Chrome execution and package resolution could not be run here**. Run the setup and test commands below on a machine with Flutter installed before production use. No Android/Chrome compatibility claim is made without that verification.
6. The current UI offers basic manual selection and editing. Advanced section-specific configuration, drag-reordering of selected questions in the final preview, image/table fidelity and comprehensive document styling are not implemented to the same depth as a full Word editor.

## Requirements

- Flutter SDK (stable; Flutter 3.22 or later recommended).
- Dart SDK supplied with Flutter.
- VS Code with the Flutter and Dart extensions.
- Chrome for web execution; Android Studio / Android SDK for Android builds.

## First-time setup in VS Code (Windows)

1. Extract the ZIP to a normal folder, for example `C:\FlutterProjects\teacher_question_paper_generator`.
2. Open that folder in VS Code (`File > Open Folder`). Make sure you open the folder containing `pubspec.yaml`, not the `lib` folder.
3. Open **Terminal > New Terminal** and run:

   ```powershell
   flutter create . --platforms=android,web
   flutter pub get
   flutter analyze
   flutter test
   ```

   `flutter create .` generates the standard Android and web runner folders for the Flutter SDK installed on your computer. It does not overwrite the Dart source files in `lib/`.

4. If VS Code asks to trust the folder, choose **Trust**.

## Run in Chrome

```powershell
flutter run -d chrome
```

## Run on Android phone over USB

1. Enable Developer Options and USB debugging on the Android phone.
2. Connect the phone with a data-capable USB cable and approve the debugging prompt.
3. Confirm detection:

   ```powershell
   flutter devices
   ```

4. Run:

   ```powershell
   flutter run -d <device-id>
   ```

   Replace `<device-id>` with the Android device ID shown by `flutter devices`.

## Build release outputs

```powershell
flutter build web
flutter build apk --release
```

Web output is written to `build/web/`; Android APK is written under `build/app/outputs/flutter-apk/`.

## Run tests

```powershell
flutter test
flutter analyze
```

The included unit tests cover the selection engine and marks calculation. They do not constitute end-to-end testing of DOCX fidelity, Android storage, Chrome IndexedDB or export rendering.

## Data privacy and storage

- DOCX bytes are parsed in the app process; there is no upload endpoint, external AI service or mandatory API key.
- Chrome persistence uses IndexedDB through Sembast Web.
- Android persistence uses a database file in the app documents directory.
- Browser data can be cleared by clearing site data. Android data is removed if the app's data is cleared or the app is uninstalled. Keep separate backups of important question banks.

## Sample question banks

Open the `.docx` files in `sample_question_banks/` and upload each one separately, assigning the indicated mark value during import.
