import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OptionsMenu {
  static void show({
    required BuildContext context,
    required bool isDark,
    required VoidCallback onProjectInfo,
    required VoidCallback onShare,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Menu options
            _MenuOption(
              icon: Icons.info_outline_rounded,
              title: 'Project Info',
              color: const Color(0xFF2196F3),
              onTap: () {
                Get.back();
                onProjectInfo();
              },
            ),
            _MenuOption(
              icon: Icons.share_rounded,
              title: 'Share Project',
              color: const Color(0xFF4CAF50),
              onTap: () {
                Get.back();
                onShare();
              },
            ),
            _MenuOption(
              icon: Icons.edit_rounded,
              title: 'Edit Project',
              color: const Color(0xFFFF9800),
              onTap: () {
                Get.back();
                onEdit();
              },
            ),
            _MenuOption(
              icon: Icons.delete_outline_rounded,
              title: 'Delete Project',
              color: Colors.red,
              onTap: () {
                Get.back();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}