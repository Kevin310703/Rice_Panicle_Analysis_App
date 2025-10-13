import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:share_plus/share_plus.dart';

class ProjectFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _projectsCollection = 'projects';

  // Get all projects
  static Future<List<Project>> getAllProjects() async {
    try {
      final querySnapshot = await _firestore
          .collection(_projectsCollection)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs.map((doc) {
        return Project.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching projects: $e');
      return [];
    }
  }

  // Search project
  static Future<List<Project>> searchProjects(String searchTerm) async {
    try {
      final querySnapshot = await _firestore
          .collection(_projectsCollection)
          .where('searchKeywords', arrayContains: searchTerm.toLowerCase())
          .get();

      return querySnapshot.docs.map((doc) {
        return Project.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching projects: $e');
      return [];
    }
  }

  // Get project by ID
  static Future<Project?> getProjectById(String projectId) async {
    try {
      final doc = await _firestore
          .collection(_projectsCollection)
          .doc(projectId)
          .get();

      if (doc.exists) {
        return Project.fromFirestore(doc.data()!, doc.id);
      }

      return null;
    } catch (e) {
      print('Error fetching projects: $e');
      return null;
    }
  }

  // Get projects stream for real-time updates
  static Stream<List<Project>> getProjectsStream() {
    return _firestore
        .collection(_projectsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Project.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get projects by date range
  static Future<List<Project>> getProjectsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_projectsCollection)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .orderBy('createdAt')
          .get();

      return querySnapshot.docs.map((doc) {
        return Project.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('$e');
      return [];
    }
  }

  // Create a new project
  static Future<ProjectResult> createProject(Project project) async {
    try {
      final docRef = await _firestore
          .collection(_projectsCollection)
          .add(project.toFirestore());
      final projectId = docRef.id;

      // Update project with auto ID
      await docRef.update({'id': projectId});

      return ProjectResult(
        success: true,
        message: 'Creat new project successfully',
      );
    } catch (e) {
      print('Error creating project: $e');
      return ProjectResult(
        success: false,
        message: 'An unexpected error occured. PLease try again.',
      );
    }
  }

  // Delete a project by ID
  static Future<ProjectResult> deleteProject(String projectId) async {
    try {
      await _firestore.collection(_projectsCollection).doc(projectId).delete();
      return ProjectResult(
        success: true,
        message: 'Delete project successfully',
      );
    } catch (e) {
      print('Error deleting project: $e');
      return ProjectResult(
        success: false,
        message: 'An unexpected error occured. PLease try again.',
      );
    }
  }

  // Upload file for project on Firestore
  static Future<ProjectResult> uploadFileForProject({
    required XFile file,
    required String type,
    required String uid,
  }) async {
    try {
      // 1) Đường dẫn lưu Storage
      final String ext = _extOf(file.name);
      final String folder = (type == 'image') ? 'images' : 'analyses';
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final String destination = 'projects/$uid/$folder/$fileName';

      final ref = FirebaseStorage.instance.ref(destination);
      final metadata = SettableMetadata(contentType: _contentTypeForExt(ext));

      // 2) Upload: Web dùng bytes (putData), Mobile/Desktop dùng File (putFile)
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await ref.putData(bytes, metadata);
      } else {
        await ref.putFile(File(file.path), metadata);
      }

      // 3) Lấy URL và cập nhật Firestore (push vào mảng)
      final downloadURL = await ref.getDownloadURL();
      final docRef = _firestore.collection(_projectsCollection).doc(uid);
      final fieldName = (type == 'image') ? 'images' : 'analyses';

      await docRef.update({
        fieldName: FieldValue.arrayUnion([downloadURL]),
      });

      // 4) Trả về project đã cập nhật
      final snap = await docRef.get();
      final updatedProject = snap.exists
          ? Project.fromFirestore(snap.data()!, snap.id)
          : null;

      return ProjectResult(
        success: true,
        project: updatedProject,
        message: (type == 'image')
            ? 'Image uploaded successfully!'
            : 'File uploaded successfully!',
      );
    } catch (e) {
      return ProjectResult(success: false, message: 'Error uploading file: $e');
    }
  }

  // ===== helpers =====
  static String _extOf(String name) {
    final i = name.lastIndexOf('.');
    if (i < 0) return '';
    return name.substring(i + 1).toLowerCase();
  }

  static String _contentTypeForExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'csv':
        return 'text/csv';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}

class ProjectResult {
  final bool success;
  final Project? project;
  final String message;

  ProjectResult({required this.success, this.project, required this.message});
}
