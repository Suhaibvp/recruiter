import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:csc_picker_plus/csc_picker_plus.dart';
import '../../../../core/utils/country_codes.dart';
import '../controllers/auth_controller.dart';

enum LoginMethod { email, phone }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Email Controls
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Phone Controls
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _codeSent = false;
  String? _verificationId;
  String _countryCode = '+91';

  LoginMethod _loginMethod = LoginMethod.email;

  // Login Logic
  Future<void> _login() async {
    if (_loginMethod == LoginMethod.email) {
      if (_formKey.currentState!.validate()) {
        await ref
            .read(authControllerProvider.notifier)
            .login(
              _emailController.text.trim(),
              _passwordController.text.trim(),
              context,
            );
      }
    } else {
      // Phone Login Logic
      if (_codeSent) {
        _verifyOtp();
      } else {
        _sendCode();
      }
    }
  }

  void _sendCode() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    String formattedPhone = phone;
    if (!phone.startsWith('+')) {
      formattedPhone = '$_countryCode$phone';
    }

    ref
        .read(authControllerProvider.notifier)
        .verifyPhoneNumber(
          formattedPhone,
          context,
          codeSent: (verificationId, resendToken) {
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
            });
          },
        );
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;
    if (_verificationId == null) return;

    // For login, we call signInWithPhone (which we need in controller) or
    // reuse verifyOTP if it handles sign-in.
    // Based on previous step, verifyOTP handles signIn if user is null.

    // However, verifyOTP logic in controller:
    // if currentUser == null -> signInWithCredential
    // else -> linkCredential

    // So for Login Screen, verifyOTP is safe to use for Sign-In.

    final phone = _phoneController.text.trim();
    String formattedPhone = phone;
    if (!phone.startsWith('+')) {
      formattedPhone = '$_countryCode$phone';
    }

    await ref
        .read(authControllerProvider.notifier)
        .verifyOTP(_verificationId!, otp, formattedPhone, context);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Image
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/recriuter_splash.png',
                  fit: BoxFit.cover,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Titles
                    Text(
                      'TALENT BAY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PORTAL LOGIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 8,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Login Method Toggle
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _loginMethod = LoginMethod.email,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                color: _loginMethod == LoginMethod.email
                                    ? theme.colorScheme.onSurface
                                    : Colors.transparent,
                                child: Text(
                                  'EMAIL',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: _loginMethod == LoginMethod.email
                                        ? theme.colorScheme.surface
                                        : theme.colorScheme.onSurface
                                              .withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _loginMethod = LoginMethod.phone,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                color: _loginMethod == LoginMethod.phone
                                    ? theme.colorScheme.onSurface
                                    : Colors.transparent,
                                child: Text(
                                  'PHONE',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: _loginMethod == LoginMethod.phone
                                        ? theme.colorScheme.surface
                                        : theme.colorScheme.onSurface
                                              .withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_loginMethod == LoginMethod.email) ...[
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              cursorColor: theme.colorScheme.primary,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: 'EMAIL ADDRESS',
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                hintText: 'name@company.com',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              cursorColor: theme.colorScheme.primary,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: 'PASSWORD',
                                labelStyle: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: _showForgotPasswordDialog,
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            if (!_codeSent) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'MOBILE NUMBER',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          child: CSCPickerPlus(
                                            onCountryChanged: (value) {
                                              setState(() {
                                                _countryCode =
                                                    CountryCodes
                                                        .countryCodeMap[value] ??
                                                    '+91';
                                              });
                                            },
                                            onStateChanged: (value) {},
                                            onCityChanged: (value) {},
                                            flagState: CountryFlag
                                                .SHOW_IN_DROP_DOWN_ONLY,
                                            dropdownDecoration: BoxDecoration(
                                              color: Colors.transparent,
                                            ),
                                            disabledDropdownDecoration:
                                                BoxDecoration(
                                                  color: Colors.transparent,
                                                ),
                                            selectedItemStyle: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            dropdownHeadingStyle: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            dropdownItemStyle: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
                                              fontSize: 14,
                                            ),
                                            searchBarRadius: 0,
                                            defaultCountry: CscCountry.India,
                                            showStates: false,
                                            showCities: false,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 1,
                                          height: 24,
                                          color: theme.colorScheme.outline
                                              .withOpacity(0.3),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _phoneController,
                                            keyboardType: TextInputType.phone,
                                            cursorColor:
                                                theme.colorScheme.primary,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                              hintText: '9876543210',
                                              prefixText: '$_countryCode ',
                                              prefixStyle: TextStyle(
                                                color:
                                                    theme.colorScheme.onSurface,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter phone number';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Enter the 6-digit code sent to\n${_phoneController.text}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Pinput(
                                length: 6,
                                controller: _otpController,
                                autofocus: true,
                                onCompleted: (_) => _login(),
                                defaultPinTheme: PinTheme(
                                  width: 50,
                                  height: 50,
                                  textStyle: TextStyle(
                                    fontSize: 20,
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: theme.colorScheme.outline
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                focusedPinTheme: PinTheme(
                                  width: 50,
                                  height: 50,
                                  textStyle: TextStyle(
                                    fontSize: 20,
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _codeSent = false;
                                    _otpController.clear();
                                  });
                                },
                                child: Text(
                                  'CHANGE NUMBER',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              (_loginMethod == LoginMethod.phone && _codeSent)
                                  ? 'VERIFY & SIGN IN'
                                  : 'LOGIN',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'NEW TO TALENT BAY? ',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/signup'),
                          child: Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final theme = Theme.of(context);
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        title: Text(
          'RESET PASSWORD',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your email address to receive a password reset link.',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: emailController,
              cursorColor: theme.colorScheme.primary,
              decoration: InputDecoration(
                labelText: 'EMAIL',
                labelStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(color: theme.colorScheme.onSurface),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (emailController.text.isNotEmpty) {
                ref
                    .read(authControllerProvider.notifier)
                    .forgotPassword(emailController.text.trim(), context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              elevation: 0,
            ),
            child: const Text(
              'SEND',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
