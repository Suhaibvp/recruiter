import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_colors.dart';
import '../models/company_model.dart';
import '../repositories/company_repository.dart';
import 'widgets/company_form_widgets.dart';

class CreateCompanyScreen extends ConsumerStatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  ConsumerState<CreateCompanyScreen> createState() =>
      _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends ConsumerState<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final CompanyRepository _repository;

  @override
  void initState() {
    super.initState();
    // In a production app, we should use ref.read(companyRepositoryProvider)
    // but for now we'll match the existing pattern or initialize it here.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository = ref.read(companyRepositoryProvider);
  }

  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  // Dropdown Values
  String? _selectedIndustry;
  String? _selectedSize;
  String? _selectedCountry = 'India';

  // Logo
  File? _logoFile;
  final _picker = ImagePicker();

  final List<String> _industries = [
    'IT Services',
    'Healthcare',
    'Education',
    'Finance',
    'Retail',
    'Manufacturing',
    'Other',
  ];

  final List<String> _companySizes = [
    '1–10',
    '11–50',
    '51–200',
    '201–500',
    '500+',
  ];

  Future<void> _pickLogo() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (pickedFile != null) {
      if (await pickedFile.length() > 2 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image size must be less than 2MB')),
          );
        }
        return;
      }
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Description validation
    if (_descriptionController.text.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Description must be at least 50 characters'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      String? logoUrl;
      if (_logoFile != null) {
        logoUrl = await _repository.uploadLogo(
          _logoFile!,
          _nameController.text.trim(),
        );
      }

      final company = CompanyModel(
        profile: CompanyProfile(
          companyName: _nameController.text.trim(),
          logoUrl: logoUrl ?? '',
          coverImageUrl: '',
          tagline: '',
          about: _descriptionController.text.trim(),
          industry: _selectedIndustry!,
          companyType: 'Private Limited',
          foundedYear: null,
          companySize: _selectedSize!,
          website: _websiteController.text.trim(),
        ),
        contact: CompanyContact(
          email: user.email ?? '',
          phone: '',
          addressLine: '',
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          country: _selectedCountry!,
          postalCode: '',
        ),
        business: CompanyBusiness(
          registrationNumber: '',
          gstOrTaxId: '',
          ownershipType: 'Private',
          operatingHours: '',
          remoteFriendly: false,
          hiringRegions: ['India'],
        ),
        verification: CompanyVerification(
          isVerified: false,
          verifiedBy: '',
          documents: [],
          status: 'pending',
        ),
        social: CompanySocial(),
        stats: CompanyStats(),
        settings: CompanySettings(),
        meta: CompanyMeta(
          createdBy: user.uid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await _repository.createCompanyProfile(
        company: company,
        recruiterUid: user.uid,
      );

      if (mounted) {
        context.go('/dashboard'); // Redirect to dashboard after success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Company Profile'), elevation: 0),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Tell us about your company',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This information helps candidates know more about who they are applying to.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSubLight,
                        ),
                      ),

                      const SectionHeader(title: 'Logo'),
                      Center(
                        child: GestureDetector(
                          onTap: _pickLogo,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.borderLight),
                              image: _logoFile != null
                                  ? DecorationImage(
                                      image: FileImage(_logoFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _logoFile == null
                                ? const Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: AppColors.textSubLight,
                                  )
                                : null,
                          ),
                        ),
                      ),

                      const SectionHeader(title: 'Basic Info'),
                      CustomTextField(
                        label: 'Company Name',
                        controller: _nameController,
                        validator: (v) => v == null || v.length < 3
                            ? 'Min 3 characters'
                            : null,
                      ),
                      CustomDropdownField<String>(
                        label: 'Industry',
                        value: _selectedIndustry,
                        items: _industries
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedIndustry = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                      CustomDropdownField<String>(
                        label: 'Company Size',
                        value: _selectedSize,
                        items: _companySizes
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedSize = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),

                      const SectionHeader(title: 'Location'),
                      CustomDropdownField<String>(
                        label: 'Country',
                        value: _selectedCountry,
                        items: ['India', 'USA', 'UK', 'Remote']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCountry = v),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'State',
                              controller: _stateController,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              label: 'City',
                              controller: _cityController,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),

                      const SectionHeader(title: 'Presence'),
                      CustomTextField(
                        label: 'Website',
                        controller: _websiteController,
                        hint: 'https://...',
                        keyboardType: TextInputType.url,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          // Simple URL validation
                          if (!v.contains('.')) return 'Invalid URL';
                          return null;
                        },
                      ),
                      CustomTextField(
                        label: 'Description',
                        controller: _descriptionController,
                        maxLines: 4,
                        hint: 'Minimum 50 characters...',
                        validator: (v) =>
                            v != null && v.length < 50 ? 'Min 50 chars' : null,
                      ),

                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Save & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
