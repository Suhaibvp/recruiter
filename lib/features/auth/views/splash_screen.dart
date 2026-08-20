import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Assuming this has AuthProvider or similar
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final user = ref.read(authControllerProvider.notifier).currentUser;
      if (user != null) {
        // Logged in, check profile
        final hasProfile = await ref
            .read(authControllerProvider.notifier)
            .doesProfileExist();
        if (mounted) {
          if (hasProfile) {
            context.go('/dashboard');
          } else {
            context.go('/complete-signup');
          }
        }
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Image.asset(
          'assets/images/recriuter_splash.png',
          fit: BoxFit.contain,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
