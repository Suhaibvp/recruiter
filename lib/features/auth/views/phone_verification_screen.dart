import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:csc_picker_plus/csc_picker_plus.dart';
import '../../../core/utils/country_codes.dart';
import '../controllers/auth_controller.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  final String? phoneNumber;
  const PhoneVerificationScreen({super.key, this.phoneNumber});

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _codeSent = false;
  String? _verificationId;
  String _countryCode = '+91';

  @override
  void initState() {
    super.initState();
    if (widget.phoneNumber != null) {
      _phoneController.text = widget.phoneNumber!;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
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
    // Basic formatting for India if not provided with country code (Adjust as needed)
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

    final phone = _phoneController.text.trim();
    String formattedPhone = phone;
    if (!phone.startsWith('+')) {
      formattedPhone = '$_countryCode$phone';
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .verifyOTP(_verificationId!, otp, formattedPhone, context);

    if (success && mounted) {
      // Check if profile exists to determine navigation
      final hasProfile = await ref
          .read(authControllerProvider.notifier)
          .doesProfileExist();
      if (mounted) {
        if (hasProfile) {
          if (widget.phoneNumber != null) {
            context.go(
              '/profile',
            ); // Determine where to go - Profile seems best as they came from there
          } else {
            context.go('/dashboard');
          }
        } else {
          context.go(
            '/complete-signup',
            extra: formattedPhone, // Pass the formatted phone
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
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
                    _codeSent ? 'VERIFICATION' : 'GET STARTED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 8,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 48),

                  if (!_codeSent) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MOBILE NUMBER',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
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
                                      // Update country code based on selection
                                      // The value from CSCPicker is the country name
                                      // You might need a map of Country Name -> Country Code
                                      // For now, defaulting to +91 or using a helper
                                      _countryCode =
                                          CountryCodes.countryCodeMap[value] ??
                                          '+91';
                                    });
                                  },
                                  onStateChanged: (value) {},
                                  onCityChanged: (value) {},
                                  flagState: CountryFlag.SHOW_IN_DROP_DOWN_ONLY,
                                  dropdownDecoration: BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                  disabledDropdownDecoration: BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                  selectedItemStyle: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  dropdownHeadingStyle: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  dropdownItemStyle: TextStyle(
                                    color: theme.colorScheme.onSurface,
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
                                color: theme.colorScheme.outline.withOpacity(
                                  0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  cursorColor: theme.colorScheme.primary,
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
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: isLoading ? null : _sendCode,
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
                          : const Text(
                              'CONTINUE',
                              style: TextStyle(
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
                          'ALREADY HAVE AN ACCOUNT? ',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'LOGIN',
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
                  ] else ...[
                    Text(
                      'Enter the 6-digit code sent to\n${_phoneController.text}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Pinput(
                      length: 6,
                      controller: _otpController,
                      autofocus: true,
                      onCompleted: (_) => _verifyOtp(),
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
                              color: theme.colorScheme.outline.withOpacity(0.3),
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isLoading ? null : _verifyOtp,
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
                          : const Text(
                              'VERIFY & CONTINUE',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
