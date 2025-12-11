import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/widgets/project_form.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

class CreateProjectScreen extends StatelessWidget {
  const CreateProjectScreen({super.key});

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
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Create new project',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: const SingleChildScrollView(
        child: Column(children: [SizedBox(height: 24), ProjectForm()]),
      ),
    );
  }
}
