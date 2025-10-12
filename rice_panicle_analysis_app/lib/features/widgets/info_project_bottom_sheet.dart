import 'package:flutter/material.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

class InfoProjectBottomSheet {
  static void show(BuildContext context, Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Project Information',
                  style: AppTextStyle.withColor(
                    AppTextStyle.h3,
                    Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: isDark ? Colors.white : Colors.black,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoItem(context, 'Project Number', project.id),
            _buildInfoItem(context, 'Project Name', project.projectName),
            _buildInfoItem(context, 'Description', project.description),
            _buildInfoItem(
              context,
              'Status',
              '${project.statusString[0].toUpperCase()}${project.statusString.substring(1).toLowerCase()}',
            ),
            _buildInfoItem(
              context,
              'Created At',
              project.createdAt.toString().split(' ')[0],
            ),
            _buildInfoItem(
              context,
              'Images Count',
              '${project.images.length} images',
            ),
            _buildInfoItem(
              context,
              'Analyses Count',
              '${project.analyses.length} analyses',
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildInfoItem(
    BuildContext context,
    String title,
    String value,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: AppTextStyle.withColor(
                AppTextStyle.bodyLarge,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
