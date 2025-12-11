import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/views/screens/project_details_screen.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  const ProjectCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => Get.to(() => ProjectDetailsScreen(project: project)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.projectName,
                        style: AppTextStyle.withColor(
                          AppTextStyle.h3,
                          Theme.of(context).textTheme.bodyLarge!.color!,
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Row(
                      children: [
                        Icon(
                          _getStatusIcon(project.status),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${project.statusString[0].toUpperCase()}${project.statusString.substring(1).toLowerCase()}', // Sử dụng getter statusString
                          style: AppTextStyle.withColor(
                            AppTextStyle.bodySmall,
                            Colors.white,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: _getStatusColor(project.status, isDark),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    project.createdAt.toString().split(' ')[0], // Chỉ lấy ngày
                    style: AppTextStyle.withColor(
                      AppTextStyle.bodySmall,
                      isDark ? Colors.grey[400]! : Colors.grey[600]!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.image_outlined,
                        color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${project.images.length} images',
                        style: AppTextStyle.withColor(
                          AppTextStyle.bodySmall,
                          isDark ? Colors.grey[400]! : Colors.grey[600]!,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${project.analyzedImageCount} analyses',
                        style: AppTextStyle.withColor(
                          AppTextStyle.bodySmall,
                          isDark ? Colors.grey[400]! : Colors.grey[600]!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status, bool isDark) {
    switch (status) {
      case ProjectStatus.active:
        return isDark ? Colors.blue[300]! : Colors.blueAccent;
      case ProjectStatus.inProgress:
        return isDark ? Colors.amber[300]! : Colors.orangeAccent;
      case ProjectStatus.completed:
        return isDark ? Colors.green[300]! : Colors.green;
      case ProjectStatus.cancelled:
        return isDark ? Colors.red[300]! : Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return Icons.play_circle_fill;
      case ProjectStatus.inProgress:
        return Icons.autorenew_rounded;
      case ProjectStatus.completed:
        return Icons.task_alt;
      case ProjectStatus.cancelled:
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline;
    }
  }
}
