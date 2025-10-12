import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/controllers/project_controller.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/screens/create_project_screen.dart';
import 'package:rice_panicle_analysis_app/features/widgets/category_chips.dart';
import 'package:rice_panicle_analysis_app/features/widgets/filter_bottom_sheet.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

import 'my_projects/views/widgets/project_card.dart';

class ListProjectScreen extends StatelessWidget {
  const ListProjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = Project.projects;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Project',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {},
          ),

          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => FilterBottomSheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(padding: EdgeInsets.only(top: 16), child: CategoryChips()),
          Expanded(
            child: GetBuilder<ProjectController>(
              builder: (projectController) {
                if (projectController.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (projectController.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          projectController.errorMessage,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
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
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
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
                  itemBuilder: (context, index) {
                    return ProjectCard(project: displayProjects[index]);
                  },
                  padding: const EdgeInsets.all(12),
                  itemCount: displayProjects.length,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => CreateProjectScreen()),
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(
          Icons.add,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
