import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/image_panicle.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/analysis_result.dart';

class ExportHillMetrics {
  final String hillId;
  final String name;
  final int totalGrains;
  final int totalPanicles;
  final int analyzedPanicles;

  const ExportHillMetrics({
    required this.hillId,
    required this.name,
    required this.totalGrains,
    required this.totalPanicles,
    required this.analyzedPanicles,
  });

  double get grainsPerPanicle =>
      analyzedPanicles == 0 ? 0 : totalGrains / analyzedPanicles;
  double get grainsPerHill => totalGrains.toDouble();
  double get paniclesPerHill => totalPanicles.toDouble();
}

class ExportResult {
  final String directoryPath;
  final List<String> files;

  const ExportResult({required this.directoryPath, required this.files});
}

class ProjectExportService {
  ProjectExportService._();

  static final ProjectExportService instance = ProjectExportService._();

  Future<ExportResult> exportProjectResults({
    required Project project,
    required List<ExportHillMetrics> metrics,
  }) async {
    final baseDir = await _resolveExportBaseDirectory();
    final safeName = _sanitize(project.projectName);
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final exportDir = Directory(
      p.join(baseDir.path, 'project_exports', '${safeName}_$timestamp'),
    );
    await exportDir.create(recursive: true);

    final exportedFiles = <String>[];
    exportedFiles.add(await _writeCsv(exportDir, project, metrics));
    exportedFiles.addAll(
      await _exportOverlayImages(exportDir, project, metrics),
    );

    return ExportResult(
      directoryPath: exportDir.path,
      files: exportedFiles,
    );
  }

  Future<String> _writeCsv(
    Directory exportDir,
    Project project,
    List<ExportHillMetrics> metrics,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'Hill,Total Grains,Panicles,Analyzed Panicles,Grains per Panicle,Grains per Hill,Panicles per Hill',
    );
    for (final metric in metrics) {
      buffer.writeln(
        '${metric.name},'
        '${metric.totalGrains},'
        '${metric.totalPanicles},'
        '${metric.analyzedPanicles},'
        '${metric.grainsPerPanicle.toStringAsFixed(2)},'
        '${metric.grainsPerHill.toStringAsFixed(2)},'
        '${metric.paniclesPerHill.toStringAsFixed(2)}',
      );
    }
    final totalGrains =
        metrics.fold<int>(0, (sum, metric) => sum + metric.totalGrains);
    final totalPanicles =
        metrics.fold<int>(0, (sum, metric) => sum + metric.totalPanicles);
    final totalAnalyzed =
        metrics.fold<int>(0, (sum, metric) => sum + metric.analyzedPanicles);
    if (metrics.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Summary,,,,,,');
      buffer.writeln(
        'Total,'
        '$totalGrains,'
        '$totalPanicles,'
        '$totalAnalyzed,'
        '${(totalAnalyzed == 0 ? 0 : totalGrains / totalAnalyzed).toStringAsFixed(2)},'
        '${totalGrains.toStringAsFixed(2)},'
        '${(metrics.isEmpty ? 0 : totalPanicles / metrics.length).toStringAsFixed(2)}',
      );
    }
    final file = File(p.join(exportDir.path, 'statistics.csv'));
    await file.writeAsString(buffer.toString());
    return file.path;
  }

  Future<List<String>> _exportOverlayImages(
    Directory exportDir,
    Project project,
    List<ExportHillMetrics> metrics,
  ) async {
    final selectedHillIds = metrics.map((m) => m.hillId).toSet();
    final imageMap = <String, ImagePanicle>{};
    for (final image in project.panicleImages) {
      if (image.hillId.isEmpty) continue;
      if (selectedHillIds.contains(image.hillId)) {
        imageMap[image.id] = image;
      }
    }
    final exportedPaths = <String>[];
    for (final result in project.aiResults) {
      final panicle = imageMap[result.imageId];
      if (panicle == null) continue;
      final bytes = await _loadBoundingImageBytes(result);
      if (bytes == null) continue;
      final overlay = img.decodeImage(bytes);
      if (overlay == null) continue;
      _annotateOverlay(overlay, result);
      final fileName =
          'hill_${panicle.hillId}_${result.imageId}.png'.replaceAll(
        RegExp(r'[\\/]+'),
        '_',
      );
      final file = File(p.join(exportDir.path, fileName));
      await file.writeAsBytes(img.encodePng(overlay));
      await _saveImageToGallery(file);
      exportedPaths.add(file.path);
    }
    return exportedPaths;
  }

  Future<Uint8List?> _loadBoundingImageBytes(AnalysisResult result) async {
    final local = result.localBoundingImagePath;
    if (local != null && local.isNotEmpty) {
      final file = File(local);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }
    final remote = result.boundingImageUrl;
    if (remote != null && remote.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(remote));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } catch (_) {}
    }
    return null;
  }

  void _annotateOverlay(img.Image image, AnalysisResult result) {
    final font = img.arial24;
    final lineHeight = font.lineHeight == 0 ? 24 : font.lineHeight;
    final lines = [
      'Seeds: ${result.grains}',
      'Branches: ${result.primaryBranch}',
    ];
    var y = 12;
    for (final line in lines) {
      img.drawString(
        image,
        line,
        font: font,
        x: 12,
        y: y,
        color: img.ColorRgb8(255, 255, 255),
      );
      y += lineHeight + 6;
    }
  }

  String _sanitize(String value) {
    final sanitized = value.trim().isEmpty ? 'project' : value;
    return sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
  }

  Future<void> _saveImageToGallery(File file) async {
    try {
      await ImageGallerySaver.saveFile(
        file.path,
        name: p.basenameWithoutExtension(file.path),
      );
    } catch (_) {}
  }

  Future<Directory> _resolveExportBaseDirectory() async {
    try {
      if (Platform.isAndroid) {
        final downloadsDirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (downloadsDirs != null && downloadsDirs.isNotEmpty) {
          return downloadsDirs.first;
        }
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return externalDir;
        }
      } else if (Platform.isIOS) {
        return await getApplicationDocumentsDirectory();
      }
    } catch (_) {}
    return await getApplicationDocumentsDirectory();
  }
}
