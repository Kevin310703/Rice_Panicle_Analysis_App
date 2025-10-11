import 'package:flutter/material.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/repositories/project_repositories.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/widgets/project_card.dart';

class MyProjectsScreen extends StatelessWidget {
  final ProjectRepositories _repositories = ProjectRepositories();
  MyProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        _buildProjectList(context, ProjectStatus.active),
        _buildProjectList(context, ProjectStatus.completed),
        _buildProjectList(context, ProjectStatus.cancelled),
      ],
    );
  }

  Widget _buildProjectList(BuildContext context, ProjectStatus status) {
    final projects = _repositories.getProjectsByStatus(status);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) => ProjectCard(project: projects[index],),
    );
  }
}
