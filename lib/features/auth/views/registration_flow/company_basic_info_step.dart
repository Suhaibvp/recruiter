import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recruiter_talentbay/theme/app_colors.dart';
import '../../controllers/auth_controller.dart';

class CompanyBasicInfoStepScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> previousData;

  const CompanyBasicInfoStepScreen({super.key, required this.previousData});

  @override
  ConsumerState<CompanyBasicInfoStepScreen> createState() =>
      _CompanyBasicInfoStepScreenState();
}

class _CompanyBasicInfoStepScreenState
    extends ConsumerState<CompanyBasicInfoStepScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _foundedYearController = TextEditingController();

  String? _selectedIndustry;
  String? _selectedCompanySize;

  final List<String> _industries = [
    'Information Technology',
    'Healthcare',
    'Education',
    'Finance',
    'Manufacturing',
    'Retail',
    'Other',
  ];

  final List<String> _companySizes = [
    '1-10',
    '11-50',
    '51-200',
    '201-500',
    '500+',
  ];

  @override
  void dispose() {
    _companyNameController.dispose();
    _foundedYearController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updatedData = Map<String, dynamic>.from(widget.previousData);
      updatedData['companyName'] = _companyNameController.text.trim();
      updatedData['industry'] = _selectedIndustry;
      updatedData['companySize'] = _selectedCompanySize;
      updatedData['foundedYear'] = _foundedYearController.text.trim();

      context.push('/registration/recruiter-admin-info', extra: updatedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: 0.2, // Step 1 of ~6
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
                const SizedBox(height: 32),

                // Header Image
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/recriuter_splash.png',
                    fit: BoxFit.contain,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'Tell us about your company',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'We need this for verification purposes.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Company Name
                TextFormField(
                  controller: _companyNameController,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Company Name',
                    hintText: 'Acme Corp',
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter company name'
                      : null,
                ),
                const SizedBox(height: 24),

                // Industry
                DropdownButtonFormField<String>(
                  value: _selectedIndustry,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurface,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Industry',
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                  items: _industries.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedIndustry = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select an industry' : null,
                  dropdownColor: theme.cardColor,
                ),
                const SizedBox(height: 24),

                // Company Size
                DropdownButtonFormField<String>(
                  value: _selectedCompanySize,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurface,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Company Size',
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                  items: _companySizes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCompanySize = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select company size' : null,
                  dropdownColor: theme.cardColor,
                ),
                const SizedBox(height: 24),

                // Founded Year
                TextFormField(
                  controller: _foundedYearController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Founded Year',
                    hintText: '2021',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter year';
                    final year = int.tryParse(value);
                    if (year == null ||
                        year < 1800 ||
                        year > DateTime.now().year) {
                      return 'Invalid year';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 48),

                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
