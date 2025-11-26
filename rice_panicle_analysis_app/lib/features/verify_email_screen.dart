import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/controllers/auth_controller.dart';
import 'package:rice_panicle_analysis_app/features/sign_in_screen.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isResending = false;
  bool _canResend = true;
  int _cooldownSeconds = 0;

  Future<void> _resendEmail() async {
    if (!_canResend || _isResending) return;

    setState(() {
      _isResending = true;
    });

    final authController = Get.find<AuthController>();
    final result = await authController.resendVerification(widget.email);

    setState(() {
      _isResending = false;
    });

    if (result.success) {
      Get.snackbar(
        'Email Sent',
        result.message,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      
      _startCooldown();
    } else {
      Get.snackbar(
        'Error',
        result.message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _startCooldown() {
    setState(() {
      _canResend = false;
      _cooldownSeconds = 60;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return false;
      
      setState(() {
        _cooldownSeconds--;
      });

      if (_cooldownSeconds <= 0) {
        setState(() {
          _canResend = true;
        });
        return false;
      }
      
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Xác nhận email',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            Theme.of(context).textTheme.bodyLarge!.color!,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            
            // Email icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Icon(
                Icons.email_outlined,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Hãy kiểm tra hộp thư của bạn',
              textAlign: TextAlign.center,
              style: AppTextStyle.withColor(
                AppTextStyle.h2,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              'Chúng tôi đã gửi liên kết xác nhận đến:',
              textAlign: TextAlign.center,
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Email address
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: AppTextStyle.withColor(
                AppTextStyle.bodyLarge,
                Theme.of(context).primaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Text(
              'Vui lòng nhấp vào liên kết trong email để kích hoạt tài khoản. Sau khi xác nhận, bạn có thể quay lại màn hình đăng nhập.',
              textAlign: TextAlign.center,
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Resend button
            if (_isResending)
              const CircularProgressIndicator()
            else if (!_canResend)
              Text(
                'Gửi lại sau $_cooldownSeconds giây',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  Colors.grey,
                ),
              )
            else
              TextButton.icon(
                onPressed: _resendEmail,
                icon: const Icon(Icons.refresh),
                label: const Text('Gửi lại email xác nhận'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            
            const Spacer(),
            
            // Main button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.offAll(() => const SigninScreen()),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Tôi đã xác nhận',
                  style: AppTextStyle.withColor(
                    AppTextStyle.buttonMedium,
                    Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Back to sign in
            TextButton(
              onPressed: () => Get.offAll(() => const SigninScreen()),
              child: Text(
                'Quay về đăng nhập',
                style: AppTextStyle.withColor(
                  AppTextStyle.buttonMedium,
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}