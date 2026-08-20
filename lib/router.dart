import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recruiter_talentbay/features/dashboard/views/dashboard_screen.dart';
import 'package:recruiter_talentbay/features/chat/views/chat_list_screen.dart';
import 'package:recruiter_talentbay/features/chat/views/chat_screen.dart';
import 'features/auth/models/recruiter_model.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/phone_verification_screen.dart';
import 'features/auth/views/sign_up_screen.dart';
import 'features/auth/views/email_verification_screen.dart';
import 'features/auth/views/splash_screen.dart';
import 'features/auth/views/registration_flow/email_password_step.dart';
import 'features/auth/views/registration_flow/company_basic_info_step.dart';
import 'features/auth/views/registration_flow/recruiter_admin_info_step.dart';
import 'features/company/views/company_setup_screen.dart';
import 'features/company/views/company_details_screen.dart';
import 'features/profile/views/profile_screen.dart';
import 'features/settings/views/settings_screen.dart';
import 'features/subscription/views/subscription_screen.dart';
import 'features/subscription/views/premium_subscription_screen.dart';

import 'features/jobs/views/create_job_screen.dart';
import 'features/jobs/models/job_model.dart';
import 'package:recruiter_talentbay/features/jobs/views/job_details_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Remove ref.watch here to prevent rebuilding GoRouter on every auth change.
  // The refreshListenable will trigger the redirect check.

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      ref.read(authControllerProvider.notifier).authStateChanges,
    ),
    redirect: (context, state) async {
      // Use ref.read to get the current values without establishing a dependency for the provider itself
      final authController = ref.read(authControllerProvider.notifier);
      final user = authController.currentUser;
      final isLoggedIn = user != null;

      final path = state.uri.toString();

      print('ROUTER DEBUG: Path: $path, LoggedIn: $isLoggedIn');

      final isScanning = path == '/splash';
      final isLoggingIn = path == '/login';
      final isRegistering =
          path.startsWith('/verify-phone') ||
          path.startsWith('/registration') ||
          path == '/complete-signup' ||
          path == '/signup';

      if (isScanning) {
        return null; // Let Splash screen handle its own logic/timer
      }

      if (!isLoggedIn) {
        // Allow access to login and registration flow
        if (isLoggingIn || isRegistering) return null;
        return '/login';
      }

      // User is logged in

      // Check if profile exists and is complete
      RecruiterModel? profile;
      try {
        profile = await authController.getRecruiterProfile(user.uid);
      } catch (e) {
        print('ROUTER DEBUG: Exception fetching profile during redirect: $e');
        // If Firestore is unavailable (transient issue), just allow the user to stay where they are or proceed
        // If it's a critical error, they might see loading states in the app.
        if (isScanning || isLoggingIn || isRegistering) return null;
        
        // Otherwise, allow them to proceed to their intended destination (like /dashboard) 
        // assuming they are already logged in from a previous session. It's better than crashing.
        return null; 
      }

      final hasProfile = profile != null;
      final isProfileComplete = hasProfile && profile.companyId.isNotEmpty;

      print(
        'ROUTER DEBUG: HasProfile: $hasProfile, ProfileComplete: $isProfileComplete',
      );

      if (!hasProfile) {
        // If generic login or scanning, force to signup completion
        if (isLoggingIn || isScanning)
          return '/complete-signup'; // or /verify-phone/signup depending on flow preference

        // Allow them to stay in registration flow
        if (isRegistering) {
          print('ROUTER DEBUG: Allowing stay in registration (No Profile)');
          return null;
        }

        // If trying to access dashboard/other protected routes without profile, redirect to signup
        return '/complete-signup';
      }

      // Profile exists but might be incomplete (Company Setup not done)
      if (!isProfileComplete) {
        // Allow access to registration flow pages
        if (isRegistering) return null;

        // Otherwise redirect to where they left off - usually company basic info
        // We'll default to company basic info if they try to go entirely elsewhere
        return '/registration/company-basic-info';
      }

      // Profile exists and is complete
      if (isLoggingIn || isScanning || isRegistering) {
        // Redirect to dashboard if trying to access auth pages while logged in and profile set
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        redirect: (_, __) =>
            '/verify-phone', // Redirect signup to start of flow
      ),
      GoRoute(
        path: '/verify-phone',
        builder: (context, state) {
          final phone = state.extra as String?;
          return PhoneVerificationScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/update-phone-verification',
        builder: (context, state) {
          final phone = state.extra as String?;
          return PhoneVerificationScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/complete-signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/email-verify',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/registration/email-password',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return EmailPasswordStepScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/registration/company-basic-info',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return CompanyBasicInfoStepScreen(previousData: data);
        },
      ),
      GoRoute(
        path: '/registration/recruiter-admin-info',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return RecruiterAdminInfoStepScreen(previousData: data);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/premium-subscription',
        builder: (context, state) => const PremiumSubscriptionScreen(),
      ),
      // Keep existing routes just in case, or remove if unused
      GoRoute(
        path: '/company-setup',
        builder: (context, state) => const CompanySetupScreen(),
      ),
      GoRoute(
        path: '/company-details',
        builder: (context, state) => const CompanyDetailsScreen(),
      ),

      GoRoute(
        path: '/create-job',
        builder: (context, state) => const CreateJobScreen(),
      ),
      GoRoute(
        path: '/job/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final job = state.extra is JobModel ? state.extra as JobModel : null;
          return JobDetailsScreen(jobId: id, job: job);
        },
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extras = state.extra as Map<String, dynamic>? ?? {};
          return ChatScreen(
            chatId: id,
            otherUserId: extras['otherUserId'] ?? '',
            candidateName: extras['candidateName'] ?? 'Candidate',
            jobTitle: extras['jobTitle'] ?? '',
          );
        },
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
