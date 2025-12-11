import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/controllers/auth_controller.dart';
import 'package:rice_panicle_analysis_app/features/sign_in_screen.dart';
import 'package:rice_panicle_analysis_app/services/supabase_auth_service.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isResending = false;
  bool _isLinkActive = true;
  bool _canResend = false;
  int _cooldownSeconds = 60;
  bool _isChecking = false;
  late DateTime _expiryTime;
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    _expiryTime = DateTime.now().add(const Duration(seconds: 60));
    _startLinkTimer();
  }

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

      _startLinkTimer();
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

  void _startLinkTimer() {
    _expiryTimer?.cancel();
    _expiryTime = DateTime.now().add(const Duration(seconds: 60));

    setState(() {
      _isLinkActive = true;
      _canResend = false;
      _cooldownSeconds = 60;
    });

    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final remaining = _expiryTime.difference(DateTime.now()).inSeconds;
      setState(() {
        _cooldownSeconds = remaining.clamp(0, 60);
      });

      if (remaining <= 0) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          _isLinkActive = false;
          _canResend = true;
        });
      }
    });
  }

  Future<void> _checkVerification() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final verified = await SupabaseAuthService.isEmailVerified();

    if (!mounted) return;
    setState(() => _isChecking = false);

    if (verified) {
      Get.snackbar(
        'Verified',
        'Your email has been successfully verified',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAll(() => const SigninScreen());
    } else if (!_isLinkActive) {
      Get.snackbar(
        'Link expired',
        'Verification link is only valid for 60 seconds. Please resend the email to confirm.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Not Verified Yet',
        'Please click the link in the email and try again',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Verify email',
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
              'Check your inbox',
              textAlign: TextAlign.center,
              style: AppTextStyle.withColor(
                AppTextStyle.h2,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'We have sent a verification link to:',
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
              'Please click the link in the email to activate your account. After verification, you can return to the sign-in screen.',
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
            else if (_isLinkActive)
              Text(
                'Link expires in $_cooldownSeconds seconds',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  Colors.grey,
                ),
              )
            else
              TextButton.icon(
                onPressed: _canResend ? _resendEmail : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Resend verification email'),
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
                onPressed: _isChecking ? null : _checkVerification,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isChecking ? 'Checking...' : 'I have verified',
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
                'Back to Sign In',
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
