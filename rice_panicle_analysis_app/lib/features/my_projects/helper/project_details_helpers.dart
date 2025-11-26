import 'package:flutter/material.dart';
import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';

class ProjectDetailsHelpers {
  /// Format date to relative time or absolute date
  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return 'Just now';
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      }
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Get status color based on project status
  static Color getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.completed:
        return Colors.green;
      case ProjectStatus.active:
        return Colors.blue;
      case ProjectStatus.inProgress:
        return Colors.orange;
      case ProjectStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get status icon based on project status
  static IconData getStatusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.completed:
        return Icons.check_circle_rounded;
      case ProjectStatus.active:
        return Icons.play_circle_filled_rounded;
      case ProjectStatus.inProgress:
        return Icons.pending_rounded;
      case ProjectStatus.cancelled:
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  /// Extract file extension from filename
  static String getFileExtension(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot < 0 ? '' : filename.substring(dot + 1).toLowerCase();
  }

  /// Validate file extension against allowed extensions
  static bool isValidExtension(String filename, Set<String> allowedExtensions) {
    final ext = getFileExtension(filename);
    return allowedExtensions.contains(ext);
  }

  /// Calculate grain count from quality score
  static int calculateGrainCount(List<int>? qualityScore) {
    if (qualityScore == null || qualityScore.isEmpty) return 0;
    return qualityScore.reduce((value, element) => value + element);
  }

  /// Show success snackbar
  static void showSuccessSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF4CAF50),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.red,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Format number with thousand separator
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  /// Calculate percentage
  static double calculatePercentage(int part, int total) {
    if (total == 0) return 0;
    return (part / total) * 100;
  }

  /// Get progress color based on percentage
  static Color getProgressColor(double percentage) {
    if (percentage >= 70) return Colors.green;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }
}