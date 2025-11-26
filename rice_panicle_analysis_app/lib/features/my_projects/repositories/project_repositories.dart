import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';

class ProjectRepositories {
  List<Project> getProjects() {
    return [
      Project(
        id: '123',
        projectName: 'Rice Variety A - Spring 2024',
        genotypeName: 'Variety A',
        description: 'A project about rice in Vietnam',
        status: ProjectStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isBookmark: true,
        images: ['image1.jpg', 'image2.jpg', 'image3.jpg', 'image4.jpg', 'image5.jpg'],
        analyses: ['analysis1.json', 'analysis2.json'],
      ),
      Project(
        id: '456',
        projectName: 'Hybrid Rice Study',
        genotypeName: 'Hybrid HX-12',
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
        genotypeName: 'DRT-5',
        description: 'A project about rice in India',
        status: ProjectStatus.cancelled,
        createdAt: DateTime(2024, 03, 01),
        isBookmark: true,
        images: ['image9.jpg', 'image10.jpg', 'image11.jpg', 'image12.jpg'],
        analyses: ['analysis6.json'],
      ),
    ];
  }

  List<Project> getProjectsByStatus(ProjectStatus status) {
    return getProjects().where((project) => project.status == status).toList();
  }
}
