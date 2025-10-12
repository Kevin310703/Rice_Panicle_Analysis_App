import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';

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
  static Future<void> createProject(Project project) async {
    try {
      final docRef = await _firestore
          .collection(_projectsCollection)
          .add(project.toFirestore());
      final projectId = docRef.id;

      // Cập nhật project với projectNumber là ID
      await docRef.update({'id': projectId});
    } catch (e) {
      print('Error creating project: $e');
      rethrow;
    }
  }

  // Delete a project by ID
  static Future<void> deleteProject(String projectId) async {
    try {
      await _firestore.collection(_projectsCollection).doc(projectId).delete();
    } catch (e) {
      print('Error deleting project: $e');
      rethrow;
    }
  }
}
