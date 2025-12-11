import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rice_panicle_analysis_app/controllers/auth_controller.dart';
import 'package:rice_panicle_analysis_app/controllers/navigation_controller.dart';
import 'package:rice_panicle_analysis_app/controllers/project_controller.dart';
import 'package:rice_panicle_analysis_app/controllers/theme_controller.dart';
import 'package:rice_panicle_analysis_app/features/reset_password_screen.dart';
import 'package:rice_panicle_analysis_app/utils/app_themes.dart';
import 'package:rice_panicle_analysis_app/features/splash_screen.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rice_panicle_analysis_app/services/panicle_ai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  usePathUrlStrategy();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  await GetStorage.init();
  Get.put(ThemeController());
  Get.put(AuthController());
  Get.put(NavigationController());
  Get.put(ProjectController());

  // Warm up TFLite runtime so the first analysis is faster.
  final panicleService = PanicleAiService.instance;
  unawaited(panicleService.warmUp());

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  /// Listen to auth state changes (including email verification)
  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      debugPrint('🔵 Auth event: $event');

      if (event == AuthChangeEvent.signedIn) {
        debugPrint('✅ User signed in: ${session?.user.email}');
        // Note: Navigation will be handled by your screens
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('👋 User signed out');
        // Note: Navigation will be handled by your screens
      } else if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('Password recovery event received');
        Get.offAll(() => const ResetPasswordScreen());
      } else if (event == AuthChangeEvent.userUpdated) {
        debugPrint('🔄 User updated');
        final user = session?.user;
        final emailConfirmed = user?.emailConfirmedAt;
        final metadata = user?.userMetadata ?? {};
        final bool isEmailVerification =
            (metadata['invited'] == true) ||
            (metadata['emailVerified'] == true) ||
            (metadata['email_confirmed'] == true);

        if (emailConfirmed != null && isEmailVerification) {
          debugPrint('✅ Email verified!');
          Get.snackbar(
            'Success',
            'Email verified successfully! You can now sign in.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          debugPrint('User updated due to another action; snackbar skipped.');
        }
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        debugPrint('🔄 Token refreshed');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return GetMaterialApp(
      title: 'GrainCount AI',
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: themeController.theme,
      defaultTransition: Transition.fade,
      home: SplashScreen(),
    );
  }
}
