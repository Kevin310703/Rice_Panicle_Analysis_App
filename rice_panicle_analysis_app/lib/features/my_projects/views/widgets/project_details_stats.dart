import 'package:flutter/material.dart';

import 'package:rice_panicle_analysis_app/features/my_projects/models/project.dart';

class ProjectDetailsStats extends StatelessWidget {
  final Project project;
  final bool isDark;

  const ProjectDetailsStats({
    super.key,
    required this.project,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.photo_library_rounded,
              value: '${project.images.length}',
              label: 'Images',
              color: const Color(0xFF4CAF50),
            ),
          ),
          _divider(),
          Expanded(
            child: _StatItem(
              icon: Icons.analytics_rounded,
              value: '${project.analyzedImageCount}',
              label: 'Analyses',
              color: const Color(0xFF2196F3),
            ),
          ),
          _divider(),
          Expanded(
            child: _StatItem(
              icon: Icons.grain_rounded,
              value: '${_totalGrainCount()}',
              label: 'Grain',
              color: const Color(0xFFFF9800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: isDark ? Colors.grey[700] : Colors.grey[200],
    );
  }

  int _totalGrainCount() {
    return project.aiResults.fold<int>(0, (sum, result) {
      return sum + result.grains;
    });
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
