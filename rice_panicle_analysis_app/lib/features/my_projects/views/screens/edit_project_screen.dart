import 'package:flutter/material.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/widgets/project_form.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

class EditProjectScreen extends StatelessWidget {
  final Project project;
  const EditProjectScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Edit Project',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            ProjectForm(initialProject: project),
          ],
        ),
      ),
    );
  }
}
