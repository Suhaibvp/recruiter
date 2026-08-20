import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isChecking = false;

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    // Reload user to get latest status
    await ref.read(authControllerProvider.notifier).reloadUser();
    // The router is listening to the auth stream (userChanges), so if the status changed,
    // it *should* automatically redirect. However, userChanges might not fire just on reload
    // without a token refresh.
    // We can manually trigger a refresh or just wait.

    // Determine if verified
    final user = ref.read(authControllerProvider.notifier).currentUser;
    if (user != null && user.emailVerified) {
      if (mounted) context.go('/dashboard');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email not verified yet.')),
        );
      }
    }

    setState(() => _isChecking = false);
  }

  Future<void> _resendEmail() async {
    await ref
        .read(authControllerProvider.notifier)
        .sendEmailVerification(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider.notifier).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_unread, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'Verify your email address',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We have sent a verification email to:\n${user?.email ?? ""}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please click on the link in the email to verify your account. Then come back here and click "I have verified".',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isChecking ? null : _checkVerification,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isChecking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('I have verified'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _resendEmail,
              child: const Text('Resend Verification Email'),
            ),
          ],
        ),
      ),
    );
  }
}
