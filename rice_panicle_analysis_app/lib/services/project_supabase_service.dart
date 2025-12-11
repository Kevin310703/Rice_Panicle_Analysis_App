import 'dart:typed_data';

import 'package:rice_panicle_analysis_app/features/my_projects/helper/project_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:rice_panicle_analysis_app/features/my_projects/models/analysis_log.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/analysis_result.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/hill.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';

class ProjectSupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  static const String _projectsTable = 'projects';
  static const String _hillsTable = 'hills';
  static const String _imagesTable = 'image_panicles';
  static const String _analysisLogsTable = 'analysis_log';
  static const String _analysisResultsTable = 'ai_results';
  static const String _projectImagesBucket = 'images';
  static const String _projectImagesFolder = 'project_panicles';
  static const String _analysisResultsFolder = 'analysis_results';

  static Future<List<Project>> getAllProjects({String? createdBy}) async {
    var query = _client.from(_projectsTable).select(_projectSelectClause);

    if (createdBy != null) {
      query = query.eq('created_by', createdBy);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => Project.fromSupabase(row as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Project>> searchProjects({
    String? createdBy,
    required String searchTerm,
  }) async {
    if (searchTerm.trim().isEmpty) {
      return getAllProjects(createdBy: createdBy);
    }

    final term = '%${searchTerm.toLowerCase()}%';
    var query = _client.from(_projectsTable).select(_projectSelectClause);

    if (createdBy != null) {
      query = query.eq('created_by', createdBy);
    }
    final data = await query
        .or('project_name.ilike.$term,description.ilike.$term')
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((row) => Project.fromSupabase(row as Map<String, dynamic>))
        .toList();
  }

  static Future<Project?> getProjectById({
    String? createdBy, required String projectId,
  }) async {
    final query = _client
        .from(_projectsTable)
        .select(_projectSelectClause)
        .eq('id', projectId);
    if (createdBy != null) {
      query.eq('created_by', createdBy);
    }
    final data = await query.maybeSingle();

    if (data == null) return null;
    return Project.fromSupabase(data);
  }

  static Future<List<Project>> getProjectsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final data = await _client
        .from(_projectsTable)
        .select(_projectSelectClause)
        .gte('created_at', startDate.toIso8601String())
        .lte('created_at', endDate.toIso8601String())
        .order('created_at');

    return (data as List<dynamic>)
        .map((row) => Project.fromSupabase(row as Map<String, dynamic>))
        .toList();
  }

  static Future<ProjectResult> createProject(Project project) async {
    try {
      final payload = project.toSupabaseMap();
      final data = await _client
          .from(_projectsTable)
          .insert(payload)
          .select()
          .single();

      final createdProject = Project.fromSupabase(data);
      return ProjectResult(
        success: true,
        project: createdProject,
        message: 'Create new project successfully',
      );
    } on PostgrestException catch (e) {
      return ProjectResult(success: false, message: e.message);
    } catch (e) {
      return ProjectResult(
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  static Future<ProjectResult> updateProject(Project project) async {
    try {
      final payload = project
          .copyWith(updatedAt: DateTime.now())
          .toSupabaseMap();
      final data = await _client
          .from(_projectsTable)
          .update(payload)
          .eq('id', project.id)
          .select()
          .single();

      final updatedProject = Project.fromSupabase(data);
      return ProjectResult(
        success: true,
        project: updatedProject,
        message: 'Update project successfully',
      );
    } on PostgrestException catch (e) {
      return ProjectResult(success: false, message: e.message);
    } catch (e) {
      return ProjectResult(
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  static Future<ProjectResult> deleteProject(String projectId) async {
    try {
      await _client.from(_projectsTable).delete().eq('id', projectId);
      return ProjectResult(
        success: true,
        message: 'Delete project successfully',
      );
    } on PostgrestException catch (e) {
      return ProjectResult(success: false, message: e.message);
    } catch (e) {
      return ProjectResult(
        success: false,
        message: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  static Future<ProjectResult> updateProjectImages({
    required String projectId,
    required List<String> newImageUrls,
  }) async {
    if (newImageUrls.isEmpty) {
      return ProjectResult(success: false, message: 'No images to update.');
    }

    try {
      final hill = await _ensureHill(projectId);
      final now = DateTime.now().toIso8601String();

      final rows = newImageUrls.map((url) {
        return {'hill_id': hill.id, 'image_path': url, 'captured_at': now};
      }).toList();

      await _client.from(_imagesTable).upsert(rows, onConflict: 'image_path');

      final updatedProject = await getProjectById(projectId: projectId);
      return ProjectResult(
        success: true,
        project: updatedProject,
        message: 'Project images updated successfully',
      );
    } catch (e) {
      return ProjectResult(
        success: false,
        message: 'Error updating project images: $e',
      );
    }
  }

  static Future<ProjectResult> createHill({
    required String projectId,
    required String hillLabel,
    String? notes,
  }) async {
    try {
      final cleanedNotes = (notes == null || notes.trim().isEmpty)
          ? null
          : notes.trim();
      final payload = {
        'project_id': projectId,
        'hill_label': hillLabel,
        if (cleanedNotes != null) 'notes': cleanedNotes,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _client.from(_hillsTable).insert(payload);
      final updatedProject = await getProjectById(projectId: projectId);
      return ProjectResult(
        success: true,
        project: updatedProject,
        message: 'Đã tạo khóm mới.',
      );
    } on PostgrestException catch (e) {
      return ProjectResult(success: false, message: e.message);
    } catch (e) {
      return ProjectResult(
        success: false,
        message: 'Không thể tạo khóm mới. Vui lòng thử lại.',
      );
    }
  }

  static Future<ProjectResult> updateHill({
    required String projectId,
    required String hillId,
    required String hillLabel,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'hill_label': hillLabel,
        'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }..removeWhere((key, value) => value == null);

      await _client
          .from(_hillsTable)
          .update(payload)
          .eq('id', hillId);

      final updatedProject = await getProjectById(projectId: projectId);
      return ProjectResult(
        success: true,
        project: updatedProject,
        message: 'Hill updated successfully',
      );
    } on PostgrestException catch (e) {
      return ProjectResult(success: false, message: e.message);
    } catch (e) {
      return ProjectResult(
        success: false,
        message: 'Failed to update hill. Please try again.',
      );
    }
  }

  static Future<ProjectResult> deleteHill({
    required String projectId,
    required String hillId,
  }) async {
    try {
      await _client.from(_hillsTable).delete().eq('id', hillId);
      final updatedProject = await getProjectById(projectId: projectId);
      return ProjectResult(
        success: true,
        project: updatedProject,
        message: 'Hill deleted successfully',
      );
    } on PostgrestException catch (e) {
      return ProjectResult(success: false, message: e.message);
    } catch (e) {
      return ProjectResult(
        success: false,
        message: 'Failed to delete hill. Please try again.',
      );
    }
  }

  static Future<ProjectResult> uploadHillImages({
    required String projectId,
    required String hillId,
    required List<ProjectImageUploadPayload> files,
  }) async {
    if (files.isEmpty) {
      return ProjectResult(success: false, message: 'Không có ảnh để tải lên.');
    }

    try {
      final urls = await _uploadProjectImages(
        projectId: projectId,
        hillId: hillId,
        files: files,
      );

      if (urls.isEmpty) {
        return ProjectResult(
          success: false,
          message: 'Không thể tải ảnh lên. Vui lòng thử lại.',
        );
      }

      final now = DateTime.now().toIso8601String();
      final rows = urls
          .map(
            (url) => {
              'hill_id': hillId,
              'project_id': projectId,
              'image_path': url,
              'captured_at': now,
            },
          )
          .toList();

      await _client.from(_imagesTable).insert(rows);

      final updatedProject = await getProjectById(projectId: projectId);
      return ProjectResult(
        success: true,
        project: updatedProject,
        message: 'Đã tải ảnh lên thành công.',
      );
    } on StorageException catch (e) {
      return ProjectResult(success: false, message: e.message);
    } on PostgrestException catch (e) {
      return ProjectResult(success: false, message: e.message);
    } catch (e) {
      return ProjectResult(
        success: false,
        message: 'Không thể tải ảnh lên. Vui lòng thử lại.',
      );
    }
  }

  static Future<List<String>> _uploadProjectImages({
    required String projectId,
    required String hillId,
    required List<ProjectImageUploadPayload> files,
  }) async {
    final bucket = _client.storage.from(_projectImagesBucket);
    final urls = <String>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < files.length; i++) {
      final payload = files[i];
      final ext = payload.extension.toLowerCase();
      final storagePath =
          '$_projectImagesFolder/$projectId/$hillId/${timestamp}_$i.$ext';

      await bucket.uploadBinary(
        storagePath,
        payload.bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: _contentTypeForExtension(ext),
        ),
      );
      urls.add(bucket.getPublicUrl(storagePath));
    }

    return urls;
  }

  static Future<void> deleteImage({
    required String imageId,
    String? imagePath,
  }) async {
    try {
      await _client
          .from(_analysisResultsTable)
          .delete()
          .eq('image_id', imageId);
      await _client
          .from(_analysisLogsTable)
          .delete()
          .eq('analysis_type', 'bbox_image:$imageId');
      await _client.from(_imagesTable).delete().eq('id', imageId);

      final storagePath = _storagePathFromUrl(imagePath);
      if (storagePath != null) {
        await _client.storage
            .from(_projectImagesBucket)
            .remove([storagePath]);
      }
    } catch (e) {
      // swallow errors, controller will surface generic message
      // ignore: avoid_print
      print('Failed to delete remote image: $e');
    }
  }

  static Future<String?> uploadAnalysisBoundingImage({
    required String projectId,
    required String imageId,
    required Uint8List bytes,
  }) async {
    final bucket = _client.storage.from(_projectImagesBucket);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath =
        '$_analysisResultsFolder/$projectId/$imageId/${timestamp}_bbox.png';
    await bucket.uploadBinary(
      storagePath,
      bytes,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'image/png',
      ),
    );
    return bucket.getPublicUrl(storagePath);
  }

  static Future<AnalysisResult?> insertAnalysisResult({
    required String imageId,
    required int grains,
    required int primaryBranch,
    required int totalSpikelets,
    required double filledRatio,
    required double confidence,
    required String modelVersion,
    required DateTime processedAt,
  }) async {
    final payload = {
      'image_id': imageId,
      'grains': grains,
      'primary_branch': primaryBranch,
      'total_spikelets': totalSpikelets,
      'filled_ratio': filledRatio,
      'confidence': confidence,
      'model_version': modelVersion,
      'processed_at': processedAt.toIso8601String(),
    };

    final data = await _client
        .from(_analysisResultsTable)
        .insert(payload)
        .select()
        .maybeSingle();
    if (data == null) return null;
    return AnalysisResult.fromMap(Map<String, dynamic>.from(data));
  }

  static Future<AnalysisLog?> createAnalysisLog({
    required String projectId,
    required String analysisType,
    String? filePath,
  }) async {
    final payload = {
      'project_id': projectId,
      'analysis_type': analysisType,
      'file_path': filePath,
      'generated_at': DateTime.now().toIso8601String(),
    };
    final data = await _client
        .from(_analysisLogsTable)
        .insert(payload)
        .select()
        .maybeSingle();
    if (data == null) return null;
    return AnalysisLog.fromMap(Map<String, dynamic>.from(data));
  }

  static String _contentTypeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'csv':
        return 'text/csv';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<Hill> _ensureHill(String projectId) async {
    final existing = await _client
        .from(_hillsTable)
        .select()
        .eq('project_id', projectId)
        .maybeSingle();

    if (existing != null) {
      return Hill.fromMap(existing);
    }

    final payload = {
      'project_id': projectId,
      'hill_label': 'Project $projectId - Hill A',
      'created_at': DateTime.now().toIso8601String(),
    };

    final inserted = await _client
        .from(_hillsTable)
        .insert(payload)
        .select()
        .single();
    return Hill.fromMap(inserted);
  }


  static const String _projectSelectClause = '''
    *,
    analysis_log(*),
    hills(
      *,
      image_panicles(
        *,
        ai_results(*)
      )
    )
  ''';

  static String? _storagePathFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final index = uri.pathSegments.indexOf(_projectImagesBucket);
    if (index == -1 || index + 1 >= uri.pathSegments.length) return null;
    final segments = uri.pathSegments.sublist(index + 1);
    if (segments.isEmpty) return null;
    return segments.join('/');
  }
}
