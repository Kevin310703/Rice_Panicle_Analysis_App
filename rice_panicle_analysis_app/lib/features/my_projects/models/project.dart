import 'package:cloud_firestore/cloud_firestore.dart';

enum ProjectStatus { active, inProgress, completed, cancelled }

class Project {
  final String id;
  final String projectName;
  final String description;
  final ProjectStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isBookmark;
  final List<String> images;
  final List<String> analyses;

  Project({
    required this.id,
    required this.projectName,
    required this.description,
    this.status = ProjectStatus.active,
    this.createdAt,
    this.updatedAt,
    this.isBookmark = false,
    this.images = const [],
    this.analyses = const [],
  });

  String get statusString => status.name;
  
  // Create project from Firestore document
  factory Project.fromFirestore(Map<String, dynamic> data, String id) {
    return Project(
      id: id,
      projectName: data['projectName'] ?? '',
      description: data['description'] ?? '',
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? ''),
        orElse: () => ProjectStatus.active,
      ),
      images: List<String>.from(data['images'] ?? []),
      analyses: List<String>.from(data['analyses'] ?? []),
      isBookmark: data['isBookmark'] ?? false,
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  // Convert project to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'projectName': projectName,
      'description': description,
      'status': status.toString(),
      'images': images,
      'analyses': analyses,
      'isBookmark': isBookmark,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static List<Project> projects = [
    Project(
      id: '123',
      projectName: 'Rice Variety A - Spring 2024',
      description: 'A project about rice in Vietnam',
      status: ProjectStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isBookmark: true,
      images: ['images/1.jpg', 'images/2.jpg', 'images/3.jpg'],
      analyses: ['analysis1.json', 'analysis2.json'],
    ),
    Project(
      id: '456',
      projectName: 'Hybrid Rice Study',
      description: 'A project about rice in China',
      status: ProjectStatus.active,
      createdAt: DateTime(2024, 03, 10),
      isBookmark: false,
      images: ['image6.jpg', 'image7.jpg', 'image8.jpg'],
      analyses: ['analysis3.json', 'analysis4.json', 'analysis5.json'],
    ),
    Project(
      id: '789',
      projectName: 'Drought Resistance Test',
      description: 'A project about rice in India',
      status: ProjectStatus.cancelled,
      createdAt: DateTime(2024, 03, 01),
      isBookmark: true,
      images: ['image9.jpg', 'image10.jpg', 'image11.jpg', 'image12.jpg'],
      analyses: ['analysis6.json'],
    ),
    Project(
      id: '101',
      projectName: 'Nitrogen Uptake Analysis',
      description:
          'Monitoring nitrogen absorption efficiency using drone imagery.',
      status: ProjectStatus.inProgress,
      createdAt: DateTime(2024, 05, 22),
      isBookmark: false,
      images: ['image13.jpg', 'image14.jpg'],
      analyses: ['analysis7.json'],
    ),
  ];
}
