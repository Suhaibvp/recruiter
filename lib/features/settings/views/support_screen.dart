import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'SUPPORT',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onBackground),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // 1. Header Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(
                  Icons.support_agent_outlined,
                  size: 64,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 32),

              // 2. Title
              Text(
                "WE'RE HERE TO HELP",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 3. Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Have questions or need assistance?\nReach out to our support team.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: AppColors.textSubLight,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 48),

              // 4. Contact Options
              _buildContactItem(
                context,
                icon: Icons.email_outlined,
                label: 'EMAIL US',
                value: 'support@talentbay.com',
              ),
              const SizedBox(height: 24),
              _buildContactItem(
                context,
                icon: Icons.phone_outlined,
                label: 'CALL US',
                value: '+1 (555) 123-4567',
              ),
              const SizedBox(height: 24),
              _buildContactItem(
                context,
                icon: Icons.language_outlined,
                label: 'VISIT WEBSITE',
                value: 'www.talentbay.com',
              ),

              const Spacer(flex: 3),

              // Bottom padding
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.textSubLight),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: AppColors.textSubLight,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onBackground,
          ),
        ),
      ],
    );
  }
}
