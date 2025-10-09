import 'package:flutter/material.dart';
import 'package:rice_panicle_analysis_app/features/help_center/views/widgets/category_card.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

class HelpCategoriesSection extends StatelessWidget {
  const HelpCategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final catefories = [
      {'icon': Icons.upload_file, 'title': 'Upload images'},
      {'icon': Icons.analytics_outlined, 'title': 'Analysis'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Help Categories',
            style: AppTextStyle.withColor(
              AppTextStyle.h3,
              Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: catefories.length,
            itemBuilder: (context, index) {
              return CategoryCard(
                title: catefories[index]['title'] as String,
                icon: catefories[index]['icon'] as IconData,
              );
            },
          ),
        ],
      ),
    );
  }
}
