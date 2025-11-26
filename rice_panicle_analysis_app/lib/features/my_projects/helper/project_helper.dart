import 'dart:typed_data';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';

class ProjectResult {
  final bool success;
  final Project? project;
  final String message;

  ProjectResult({required this.success, this.project, required this.message});
}

class ProjectImageUploadPayload {
  final Uint8List bytes;
  final String extension;
  final String fileName;

  ProjectImageUploadPayload({
    required this.bytes,
    required this.extension,
    required this.fileName,
  });
}
