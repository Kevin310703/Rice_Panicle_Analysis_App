import 'package:flutter/material.dart';
import 'package:rice_panicle_analysis_app/features/help_center/views/widgets/question_card.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

class PopularQuestionsSection extends StatelessWidget {
  const PopularQuestionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Questions',
            style: AppTextStyle.withColor(
              AppTextStyle.h3,
              Theme.of(context).textTheme.bodyLarge!.color!,
            ),
          ),
          const SizedBox(height: 16),
          QuestionCard(
            title: 'How to upload images for analysis?',
            icon: Icons.upload_file,
          ),
          const SizedBox(height: 12),
          QuestionCard(
            title: 'How to interpret the analysis results?',
            icon: Icons.analytics,
          ),
          const SizedBox(height: 12),
          QuestionCard(
            title: 'What types of rice panicles can be analyzed?',
            icon: Icons.image,
          ),
          const SizedBox(height: 12),
          QuestionCard(
            title: 'How to update the app to the latest version?',
            icon: Icons.system_update,
          ),
          const SizedBox(height: 12),
          QuestionCard(
            title: 'Where can I find my analysis history?',
            icon: Icons.history,
          ),
        ],
      ),
    );
  }
}
