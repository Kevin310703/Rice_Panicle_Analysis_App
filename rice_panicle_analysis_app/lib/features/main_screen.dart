import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/controllers/navigation_controller.dart';
import 'package:rice_panicle_analysis_app/controllers/theme_controller.dart';
import 'package:rice_panicle_analysis_app/features/account_screen.dart';
import 'package:rice_panicle_analysis_app/features/home_screen.dart';
import 'package:rice_panicle_analysis_app/features/list_project_screen.dart';
import 'package:rice_panicle_analysis_app/features/widgets/custom_bottom_navbar.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.put(NavigationController());

    return GetBuilder<ThemeController>(
      builder: (themeControler) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Obx(
            () => IndexedStack(
              key: ValueKey(navController.currentIndex.value),
              index: navController.currentIndex.value,
              children: const[
                // Add your main screen widgets here
                HomeScreen(),
                ListProjectScreen(),
                // BookmarkScreen(),
                AccountScreen(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavbar(),
      ),
    );
  }
}