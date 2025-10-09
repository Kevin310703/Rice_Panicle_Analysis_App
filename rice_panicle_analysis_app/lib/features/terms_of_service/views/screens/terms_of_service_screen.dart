import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/features/privacy_policy/views/widgets/info_section.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
                    'Welcome to the Rice Panicle Analysis App ("the App"). These Terms of Service ("Terms") govern your use of the App and its services. By accessing or using the App, you agree to be bound by these Terms. If you do not agree, please refrain from using the App.',
              ),
              InfoSection(
                title: 'Acceptance of Terms',
                content:
                    'By installing, accessing, or using the App, you confirm that you are at least 13 years old and agree to these Terms, our Privacy Policy, and any additional guidelines or rules applicable to specific features. We may update these Terms periodically, and your continued use constitutes acceptance of the revised Terms.',
              ),
              InfoSection(
                title: 'License and Usage',
                content:
                    'We grant you a limited, non-exclusive, non-transferable license to use the App for personal, non-commercial purposes. You may not modify, distribute, or reverse-engineer the App. Any unauthorized use may result in termination of your access and legal action.',
              ),
              InfoSection(
                title: 'User Responsibilities',
                content:
                    'You are responsible for maintaining the confidentiality of your account and for all activities under your account. You agree not to upload illegal, harmful, or misleading content, including images that violate intellectual property rights or privacy laws.',
              ),
              InfoSection(
                title: 'Payment and Subscriptions',
                content:
                    'Certain features may require payment or a subscription. All fees are non-refundable unless required by law. Details of pricing and subscription terms are available in the App or on our website. We reserve the right to change pricing with prior notice.',
              ),
              InfoSection(
                title: 'Termination',
                content:
                    'We may terminate or suspend your access to the App at our discretion if you violate these Terms. Upon termination, your right to use the App ceases, and any saved data may be deleted unless otherwise required by law.',
              ),
              InfoSection(
                title: 'Limitation of Liability',
                content:
                    'The App is provided "as is" without warranties of any kind. We are not liable for any indirect, incidental, or consequential damages arising from your use of the App, including but not limited to data loss or inaccurate analysis results.',
              ),
              InfoSection(
                title: 'Governing Law',
                content:
                    'These Terms are governed by the laws of the country where the Rice Panicle Analysis Team is based. Any disputes will be resolved through arbitration or in the courts of Tech City, Country.',
              ),
              InfoSection(
                title: 'Contact Us',
                content:
                    'If you have any questions or concerns about these Terms of Service, please contact us at:\n\n'
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
