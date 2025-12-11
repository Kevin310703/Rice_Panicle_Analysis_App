import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:rice_panicle_analysis_app/features/my_projects/helper/project_helper.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/image_panicle.dart';

class LocalPanicleStorageService {
  LocalPanicleStorageService._();

  static final LocalPanicleStorageService instance =
      LocalPanicleStorageService._();

  final GetStorage _box = GetStorage();
  static const String _storeKey = 'local_panicle_images_v1';

  Future<List<ImagePanicle>> saveHillImages({
    required String projectId,
    required String hillId,
    required List<ProjectImageUploadPayload> files,
  }) async {
    if (files.isEmpty) return const [];
    if (kIsWeb) {
      throw UnsupportedError(
        'Local panicle storage is only available on mobile/desktop builds.',
      );
    }

    final directory = await _ensureHillDirectory(projectId, hillId);
    final now = DateTime.now();
    final records = <_LocalPanicleRecord>[];

    for (var i = 0; i < files.length; i++) {
      final payload = files[i];
      final ext = payload.extension.isEmpty
          ? 'jpg'
          : payload.extension.toLowerCase();
      final fileName =
          'panicle_${now.millisecondsSinceEpoch}_$i.$ext';
      final file = File(p.join(directory.path, fileName));
      await file.writeAsBytes(payload.bytes, flush: true);

      final panicle = ImagePanicle(
        id: _generateLocalId(now, i),
        hillId: hillId,
        imagePath: file.path,
        capturedAt: DateTime.now(),
        isAnalyzed: false,
        flag: false,
        qualityScore: null,
      );
      records.add(
        _LocalPanicleRecord(projectId: projectId, panicle: panicle),
      );
    }

    final existing = _readRecords();
    existing.addAll(records);
    await _writeRecords(existing);
    return records.map((e) => e.panicle).toList();
  }

  Future<List<ImagePanicle>> getImagesForProject(String projectId) async {
    final records = _readRecords();
    return records
        .where((record) => record.projectId == projectId)
        .map((record) => record.panicle)
        .toList();
  }

  Future<List<ImagePanicle>> getImagesForHill(
    String projectId,
    String hillId,
  ) async {
    final records = _readRecords();
    return records
        .where(
          (record) =>
              record.projectId == projectId && record.panicle.hillId == hillId,
        )
        .map((record) => record.panicle)
        .toList();
  }

  Future<void> deleteProject(String projectId) async {
    final records = _readRecords()
        .where((record) => record.projectId != projectId)
        .toList();
    await _writeRecords(records);

    if (kIsWeb) return;
    final baseDir = await _baseDirectory();
    final projectFolder = Directory(p.join(baseDir.path, projectId));
    if (await projectFolder.exists()) {
      await projectFolder.delete(recursive: true);
    }
  }

  Future<Directory> _ensureHillDirectory(
    String projectId,
    String hillId,
  ) async {
    final baseDir = await _baseDirectory();
    final directory = Directory(p.join(baseDir.path, projectId, hillId));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<Directory> _baseDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'panicle_images'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> deleteImage({
    required String projectId,
    required ImagePanicle image,
  }) async {
    final records = _readRecords()
        .where((record) =>
            !(record.projectId == projectId &&
              record.panicle.id == image.id))
        .toList();
    await _writeRecords(records);

    if (kIsWeb) return;
    final path = _normalizeLocalPath(image.imagePath);
    if (path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  List<_LocalPanicleRecord> _readRecords() {
    final data = _box.read<List<dynamic>>(_storeKey);
    if (data == null) return <_LocalPanicleRecord>[];
    return data
        .whereType<Map>()
        .map(
          (raw) => _LocalPanicleRecord.fromMap(
            Map<String, dynamic>.from(raw),
          ),
        )
        .toList();
  }

  Future<void> _writeRecords(List<_LocalPanicleRecord> records) async {
    final payload = records.map((record) => record.toMap()).toList();
    await _box.write(_storeKey, payload);
  }

  String _generateLocalId(DateTime timestamp, int index) {
    return 'local_${timestamp.microsecondsSinceEpoch}_$index';
  }

  String _normalizeLocalPath(String value) {
    if (value.isEmpty) return '';
    if (value.startsWith('file://')) {
      return Uri.parse(value).toFilePath();
    }
    return value;
  }
}

class _LocalPanicleRecord {
  const _LocalPanicleRecord({
    required this.projectId,
    required this.panicle,
  });

  final String projectId;
  final ImagePanicle panicle;

  factory _LocalPanicleRecord.fromMap(Map<String, dynamic> map) {
    return _LocalPanicleRecord(
      projectId: map['project_id']?.toString() ?? '',
      panicle: ImagePanicle.fromMap(map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'project_id': projectId,
      'id': panicle.id,
      'hill_id': panicle.hillId,
      'image_path': panicle.imagePath,
      'captured_at': panicle.capturedAt.toIso8601String(),
      'is_analyzed': panicle.isAnalyzed,
      'flag': panicle.flag,
      'quality_score': panicle.qualityScore,
    };
  }
}
