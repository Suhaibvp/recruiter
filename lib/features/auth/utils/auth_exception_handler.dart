import 'package:firebase_auth/firebase_auth.dart';

class AuthExceptionHandler {
  static String generateErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'The email address is not valid. Please check and try again.';
        case 'user-disabled':
          return 'This user has been disabled. Please contact support.';
        case 'user-not-found':
          return 'No user found with this email. Please sign up first.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'This email is already registered. Please log in instead.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled. Please contact support.';
        case 'weak-password':
          return 'The password is too weak. Please use a stronger password.';
        case 'invalid-verification-code':
          return 'The verification code is invalid. Please check and try again.';
        case 'invalid-verification-id':
          return 'The verification session has expired. Please request a new code.';
        case 'credential-already-in-use':
          return 'This account is already linked to another user.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'invalid-credential':
          return 'Invalid credentials. Please check your details and try again.';
        case 'wrong-role': // Custom error code we saw in controller
          return 'User is invalid in this application.';
        // App Check / Security errors
        case 'invalid-app-credential':
        case 'permission-denied':
        case '403':
          return 'Security check failed. Please ensure you are using the latest app version.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return error.message ?? 'An unknown authentication error occurred.';
      }
    } else if (error is FirebaseException) {
      if (error.code == 'permission-denied' ||
          error.code == '403' ||
          (error.message?.contains('App attestation failed') ?? false)) {
        return 'Security verification failed. Please try again later.';
      }
      return error.message ?? 'A Firebase error occurred.';
    } else {
      return error.toString();
    }
  }
}
