import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'ABOUT',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onBackground),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Splash Image
            Center(
              child: Image.asset(
                'assets/images/new_splash.png',
                height: 200, // Adjust height as needed
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),

            // App Name & Version
            Text(
              'TALENT BAY',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSubLight,
              ),
            ),

            const SizedBox(height: 40),

            // Description
            Text(
              'Talent Bay is the premier platform connecting top-tier recruiters with exceptional talent. Our mission is to streamline the hiring process with advanced AI tools and a seamless user experience.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 60),

            // Footer / Developer Info
            Text(
              'Developed & Maintained by',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSubLight,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Image.asset(
              'assets/images/WaqtixLLP.png',
              height: 70, // Adjust height based on logo aspect ratio
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              '© ${DateTime.now().year} Waqtix LLP. All rights reserved.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSubLight,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
