import 'package:flutter/material.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
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
            child: ListView.builder(
              itemBuilder: (context, index) {
                return ProjectCard(project: projects[index]);
              },
              padding: const EdgeInsets.all(12),
              itemCount: projects.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Thêm logic để tạo mới dự án (ví dụ: chuyển đến màn hình tạo dự án)
          print('Create new project');
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: IconButton(
          icon: const Icon(Icons.add),
          color: isDark ? Colors.white : Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
