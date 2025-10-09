import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/features/privacy_policy/views/widgets/info_section.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          'Privacy Policy',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(screenSize.width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoSection(
                title: 'Introduction',
                content:
                    'Welcome to the Rice Panicle Analysis App ("the App"). This Privacy Policy explains how we collect, use, disclose, and protect your information when you use our App. We are committed to safeguarding your privacy and ensuring that your personal information is handled responsibly.',
              ),
              InfoSection(
                title: 'Information We Collect',
                content:
                    'The App may collect the following types of information:\n\n'
                    '- Personal Information: When you register or interact with the App, we may collect your name, email address, and other contact details.\n'
                    '- Usage Data: We collect data on how you use the App, such as analysis history, settings preferences, and interactions with features.\n'
                    '- Images and Analysis Data: The App processes images of rice panicles for analysis. These images may be uploaded by you and stored temporarily for processing.\n'
                    '- Device Information: We may collect information about your device, such as the model, operating system, and unique device identifiers.',
              ),
              InfoSection(
                title: 'How We Use Your Information',
                content:
                    'We use the collected information to:\n\n'
                    '- Provide and improve the App’s functionality, including rice panicle analysis and result generation.\n'
                    '- Personalize your experience based on your preferences and usage.\n'
                    '- Communicate with you, including sending updates or responding to inquiries.\n'
                    '- Analyze usage trends to enhance the App’s performance and user experience.\n'
                    '- Ensure the security and integrity of the App.',
              ),
              InfoSection(
                title: 'Data Storage and Security',
                content:
                    'We store your data securely using industry-standard encryption and security measures. Images uploaded for analysis are stored temporarily and deleted after processing unless you explicitly choose to save them. We do not retain personal information longer than necessary to fulfill the purposes outlined in this policy.',
              ),
              InfoSection(
                title: 'Sharing Your Information',
                content:
                    'We do not sell, trade, or rent your personal information to third parties. We may share your data only in the following cases:\n\n'
                    '- With your consent.\n'
                    '- To comply with legal obligations or protect our rights.\n'
                    '- With service providers who assist in operating the App (e.g., cloud storage providers), under strict confidentiality agreements.',
              ),
              InfoSection(
                title: 'Your Rights',
                content:
                    'You have the right to:\n\n'
                    '- Access, update, or delete your personal information stored by the App.\n'
                    '- Opt out of receiving non-essential communications.\n'
                    '- Request information about how your data is used.\n'
                    'To exercise these rights, please contact us at support@ricepanicleapp.com.',
              ),
              InfoSection(
                title: 'Third-Party Services',
                content:
                    'The App may integrate third-party services (e.g., cloud storage or analytics tools). These services have their own privacy policies, and we encourage you to review them. We are not responsible for the practices of third-party services.',
              ),
              InfoSection(
                title: 'Changes to This Privacy Policy',
                content:
                    'We may update this Privacy Policy from time to time to reflect changes in our practices or legal requirements. We will notify you of any significant changes via the App or email. Your continued use of the App after such updates constitutes acceptance of the revised policy.',
              ),
              InfoSection(
                title: 'Contact Us',
                content:
                    'If you have any questions or concerns about this Privacy Policy or our data practices, please contact us at:\n\n'
                    'Email: support@ricepanicleapp.com\n'
                    'Address: Rice Panicle Analysis Team, 123 Agriculture Lane, Tech City, Country',
              ),
              const SizedBox(height: 24),
              Text(
                'Last updated: October 2025',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  isDark ? Colors.grey[400]! : Colors.grey[600]!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
