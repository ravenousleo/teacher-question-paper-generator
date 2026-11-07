# Testing report

## Automated tests included

- `PaperEngine.totalMarks` calculates accumulated marks.
- Random selection follows requested per-mark counts.
- A generated paper contains no duplicate question IDs.
- Excluded IDs are not selected; insufficient remaining questions produce an error.
- Requests larger than the available category count produce an error.
- DOCX parser tests cover numbered paragraphs, continuation paragraphs and a 500-question import.

## Execution status in the build environment

| Check | Status | Notes |
|---|---|---|
| Flutter compilation | Not run | Flutter SDK is not installed in the build environment. |
| `flutter analyze` | Not run | Requires Flutter SDK and dependency resolution. |
| `flutter test` | Not run | Test suite is included but not executed here. |
| Chrome runtime | Not run | Requires Flutter web toolchain and Chrome runtime. |
| Android runtime | Not run | Requires Android SDK / emulator or physical device. |
| DOCX import fidelity | Partial by design | XML text extraction; see README limitations. |
| DOCX export | Source implemented | Must be opened in Word/LibreOffice for validation on target machine. |
| PDF export | Source implemented | Must be checked for glyph/font fidelity on target machine. |

## Required acceptance checks on the target computer

1. Run `flutter pub get`, `flutter analyze` and `flutter test`.
2. Upload the supplied sample files and compare all extracted questions against their source documents.
3. Test with a real 500-question DOCX from the school.
4. Check equations, tables, Tamil or other non-Latin text, symbols and page breaks.
5. Export both formats and open the DOCX in Microsoft Word / LibreOffice; print the PDF to A4.
6. Close and reopen the app to verify IndexedDB / Android local database persistence.
7. Test random generation twice with the used-question option both enabled and disabled.
