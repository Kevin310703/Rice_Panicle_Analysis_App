# GrainCount AI

AI-powered mobile application for counting grains on rice panicles, built with Flutter and Supabase. The app streamlines field data collection, panicle image management, AI inference, and project reporting for agronomy teams.

## Features

- **AI Analysis Pipeline** – Runs YOLO-based panicle detection and grain counting on-device with batching/queueing, caching of TFLite models, and processing-time tracking per image.
- **Project & Hill Management** – Organize photos by hill/region, rename/delete hills, manage project metadata, and monitor per-hill statistics (grains/panicle, grains/hill, panicles/hill, analysis completion).
- **Results Export** – Generate CSV summaries and annotated overlay images directly into device storage/gallery, with permission handling for Android/iOS.
- **Authentication & Supabase Sync** – Supabase Auth for email/password flows, email verification, password reset via deep links, and Supabase storage for user/project/notification data.
- **Notifications** – Fire Supabase-backed in-app notifications whenever critical actions complete (analysis done, export success, etc.).
- **Offline Safety** – Local caching for panicle images and analysis results; queued “analyze all” flow prevents device crashes.

## Architecture

| Layer | Responsibility |
| --- | --- |
| Presentation | Flutter UI + GetX controllers for screens such as ProjectDetails, ProjectStatistics, and ImagePreview. |
| Controllers | Orchestrate view state, invoke services, manage queues (e.g., `ProjectController`, `AuthController`). |
| Services | Encapsulate all external integrations: Supabase (auth, projects, notifications), `PanicleAIService`, `ProjectExportService`, local storage helpers. |
| Data Models | Immutable DTOs (`Project`, `ImagePanicle`, `AnalysisResult`, etc.) synchronizing with Supabase JSON payloads. |
| Infrastructure | Supabase, path_provider, image/image_gallery_saver, permission_handler, ultralytics_yolo plugin. |

## Requirements

- Flutter 3.22+ / Dart 3.3+
- Android Studio or Xcode (for respective platforms)
- Supabase project with configured tables:
  - `projects`, `hills`, `panicle_images`, `analysis_results`, `notifications`
  - Storage buckets for images and AI overlays
- YOLO/TFLite model files located under `assets/models`

## Getting Started

1. **Clone & Install**
   ```bash
   git clone https://github.com/<org>/Rice_Panicle_Analysis_App.git
   cd Rice_Panicle_Analysis_App/rice_panicle_analysis_app
   flutter pub get
   ```

2. **Configure Environment**
   - Copy `.env.example` to `.env` and set Supabase URL, anon key, deep-link scheme, etc.
   - Ensure required TFLite models exist in `assets/models/` (see `pubspec.yaml` for asset list).
   - Android: enable Developer Mode on Windows to allow Flutter symlinks.

3. **Run**
   ```bash
   flutter run -d <device>
   ```
   Use `--release` or `--profile` for benchmarking inference time.

## Key Commands

| Task | Command |
| --- | --- |
| Format code | `flutter format lib` |
| Static analysis | `flutter analyze` |
| Integration tests | `flutter test integration_test` |
| Build Android APK | `flutter build apk --release` |
| Build iOS IPA | `flutter build ipa --release` |

## Project Structure (excerpt)

```
lib/
 ├─ controllers/
 │   ├─ auth_controller.dart
 │   └─ project_controller.dart
 ├─ features/
 │   ├─ my_projects/
 │   │   ├─ views/screens/
 │   │   └─ views/widgets/
 │   └─ notifications/
 ├─ services/
 │   ├─ panicle_ai_service.dart
 │   ├─ project_export_service.dart
 │   └─ notification_supabase_service.dart
 └─ utils/
```

## Environment Variables (`.env`)

| Key | Description |
| --- | --- |
| `SUPABASE_URL` | Supabase project REST URL |
| `SUPABASE_ANON_KEY` | Public anon key for client SDK |
| `DEEP_LINK_SCHEME` | Custom scheme for email verification/password reset |
| `STORAGE_BUCKET_PROJECTS` | Supabase storage bucket for project images |

## Permissions & Storage

- Android Manifest declares camera, storage/READ_MEDIA, and internet permissions.
- At runtime, `ProjectExportService` requests storage/gallery permissions before saving CSV/PNG exports.
- iOS uses `NSPhotoLibraryAddUsageDescription` for saving overlays to Photos.

## Contributing

1. Fork & create feature branch (`git checkout -b feature/my-change`)
2. Follow existing GetX + service pattern, add tests where applicable.
3. Run `flutter analyze` and `flutter test` before submitting PR.

## License

This project is proprietary to the GrainCount AI team. Contact the maintainers for licensing or collaboration inquiries.
