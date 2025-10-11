enum ProjectStatus { active, inProgress, completed, cancelled }

class Project {
  final String projectNumber;
  final String projectName;
  final String description;
  final ProjectStatus status;
  final DateTime createdAt;
  final bool isBookmark;
  final List<String> images; // Danh sách đường dẫn hoặc ID của ảnh
  final List<String> analyses; // Danh sách đường dẫn hoặc ID của kết quả phân tích
  
  Project({
    required this.projectNumber,
    required this.projectName,
    required this.description,
    required this.status,
    required this.createdAt,
    this.isBookmark = false,
    this.images = const [],
    this.analyses = const [],
  });

  String get statusString => status.name;

  static List<Project> projects = [
    Project(
      projectNumber: '123',
      projectName: 'Rice Variety A - Spring 2024',
      description: 'A project about rice in Vietnam',
      status: ProjectStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isBookmark: true,
      images: ['images/1.jpg', 'images/2.jpg', 'images/3.jpg'],
      analyses: ['analysis1.json', 'analysis2.json'],
    ),
    Project(
      projectNumber: '456',
      projectName: 'Hybrid Rice Study',
      description: 'A project about rice in China',
      status: ProjectStatus.active,
      createdAt: DateTime(2024, 03, 10),
      isBookmark: false,
      images: ['image6.jpg', 'image7.jpg', 'image8.jpg'],
      analyses: ['analysis3.json', 'analysis4.json', 'analysis5.json'],
    ),
    Project(
      projectNumber: '789',
      projectName: 'Drought Resistance Test',
      description: 'A project about rice in India',
      status: ProjectStatus.cancelled,
      createdAt: DateTime(2024, 03, 01),
      isBookmark: true,
      images: ['image9.jpg', 'image10.jpg', 'image11.jpg', 'image12.jpg'],
      analyses: ['analysis6.json'],
    ),
    Project(
      projectNumber: '101',
      projectName: 'Nitrogen Uptake Analysis',
      description: 'Monitoring nitrogen absorption efficiency using drone imagery.',
      status: ProjectStatus.inProgress,
      createdAt: DateTime(2024, 05, 22),
      isBookmark: false,
      images: ['image13.jpg', 'image14.jpg'],
      analyses: ['analysis7.json'],
    ),
  ];
}
