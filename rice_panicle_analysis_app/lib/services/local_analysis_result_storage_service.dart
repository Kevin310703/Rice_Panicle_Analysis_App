import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:rice_panicle_analysis_app/features/my_projects/models/analysis_result.dart';

class LocalAnalysisResultStorageService {
  LocalAnalysisResultStorageService._();

  static final LocalAnalysisResultStorageService instance =
      LocalAnalysisResultStorageService._();

  final GetStorage _box = GetStorage();
  static const String _storeKey = 'local_analysis_results_v1';

  Future<String> saveBoundingImage({
    required String projectId,
    required String imageId,
    required Uint8List bytes,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Local bounding images are only supported on mobile/desktop builds.',
      );
    }
    final dir = await _resultDirectory(projectId, imageId);
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final file = File(p.join(dir.path, 'bbox_$timestamp.png'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> saveResult({
    required String projectId,
    required String hillId,
    required AnalysisResult result,
  }) async {
    final records = _readRecords();
    records.removeWhere(
      (record) =>
          record.projectId == projectId &&
          record.result.imageId == result.imageId &&
          record.result.processedAt == result.processedAt,
    );
    records.add(
      _LocalAnalysisRecord(
        projectId: projectId,
        hillId: hillId,
        result: result,
      ),
    );
    await _writeRecords(records);
  }

  Future<void> replaceResult({
    required String projectId,
    required String hillId,
    required AnalysisResult result,
  }) async {
    final records = _readRecords();
    final updated = records.map((record) {
      if (record.projectId == projectId &&
          record.result.imageId == result.imageId &&
          record.result.processedAt == result.processedAt) {
        return _LocalAnalysisRecord(
          projectId: projectId,
          hillId: hillId,
          result: result,
        );
      }
      return record;
    }).toList();
    await _writeRecords(updated);
  }

  Future<List<AnalysisResult>> getResultsForProject(String projectId) async {
    final records = _readRecords()
        .where((record) => record.projectId == projectId)
        .map((record) => record.result)
        .toList();
    return records;
  }

  Future<void> deleteProject(String projectId) async {
    final remaining =
        _readRecords().where((record) => record.projectId != projectId).toList();
    await _writeRecords(remaining);

    if (kIsWeb) return;
    final dir = await _baseDirectory();
    final projectDir = Directory(p.join(dir.path, projectId));
    if (await projectDir.exists()) {
      await projectDir.delete(recursive: true);
    }
  }

  Future<Directory> _resultDirectory(
    String projectId,
    String imageId,
  ) async {
    final base = await _baseDirectory();
    final dir = Directory(p.join(base.path, projectId, imageId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _baseDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'analysis_results'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  List<_LocalAnalysisRecord> _readRecords() {
    final data = _box.read<List<dynamic>>(_storeKey);
    if (data == null) return <_LocalAnalysisRecord>[];
    return data
        .whereType<Map>()
        .map(
          (raw) => _LocalAnalysisRecord.fromMap(
            Map<String, dynamic>.from(raw as Map),
          ),
        )
        .toList();
  }

  Future<void> _writeRecords(List<_LocalAnalysisRecord> records) async {
    final payload = records.map((record) => record.toMap()).toList();
    await _box.write(_storeKey, payload);
  }
}

class _LocalAnalysisRecord {
  const _LocalAnalysisRecord({
    required this.projectId,
    required this.hillId,
    required this.result,
  });

  final String projectId;
  final String hillId;
  final AnalysisResult result;

  Map<String, dynamic> toMap() => result.toLocalMap(
        projectId: projectId,
        hillId: hillId,
      );

  factory _LocalAnalysisRecord.fromMap(Map<String, dynamic> map) {
    final result = AnalysisResult.fromLocalMap(map);
    return _LocalAnalysisRecord(
      projectId: map['project_id']?.toString() ?? '',
      hillId: map['hill_id']?.toString() ?? '',
      result: result,
    );
  }
}
