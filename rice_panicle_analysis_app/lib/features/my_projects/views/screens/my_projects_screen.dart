import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/controllers/project_controller.dart';
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

    return GetBuilder<ProjectController>(
      builder: (projectController) {
        if (projectController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (projectController.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  projectController.errorMessage,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => projectController.refreshProjects(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final displayProjects = projectController.getDisplayProjects();

        if (displayProjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_off_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No projects availabel',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => projectController.refreshProjects(),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: displayProjects.length,
          itemBuilder: (context, index) =>
              ProjectCard(project: displayProjects[index]),
        );
      },
    );
  }
}
