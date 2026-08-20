import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csc_picker_plus/csc_picker_plus.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/storage_service.dart';
import '../models/company_model.dart';
import '../repositories/company_repository.dart';
import 'company_details_screen.dart'; // For companyProvider refresh
import '../../../theme/app_colors.dart';

class EditCompanyScreen extends ConsumerStatefulWidget {
  final CompanyModel company;

  const EditCompanyScreen({super.key, required this.company});

  @override
  ConsumerState<EditCompanyScreen> createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends ConsumerState<EditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  late CompanyModel _company;
  bool _isLoading = false;
  File? _selectedLogo;
  final ImagePicker _picker = ImagePicker();

  final List<String> _industries = [
    'Technology',
    'Finance',
    'Healthcare',
    'Education',
    'Retail',
    'Manufacturing',
    'Construction',
    'Real Estate',
    'Marketing',
    'Consulting',
    'Design',
    'Media',
    'Others',
  ];

  final List<String> _companySizes = [
    '1-10',
    '11-50',
    '51-200',
    '201-500',
    '501-1000',
    '1000+',
  ];

  String? _selectedIndustry;
  String? _selectedSize;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _taglineController;
  late TextEditingController _descriptionController;
  late TextEditingController _websiteController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _postalCodeController;
  late TextEditingController _foundedYearController;

  // Business
  late TextEditingController _gstController;
  late TextEditingController _regNumberController;

  // Social
  late TextEditingController _linkedinController;
  late TextEditingController _twitterController;

  @override
  void initState() {
    super.initState();
    _company = widget.company;
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: _company.profile.companyName);
    _taglineController = TextEditingController(text: _company.profile.tagline);
    _descriptionController = TextEditingController(
      text: _company.profile.about,
    );
    _websiteController = TextEditingController(text: _company.profile.website);

    if (_company.profile.industry.isNotEmpty) {
      if (_industries.contains(_company.profile.industry)) {
        _selectedIndustry = _company.profile.industry;
      } else {
        _selectedIndustry = 'Others';
      }
    }

    if (_company.profile.companySize.isNotEmpty &&
        _companySizes.contains(_company.profile.companySize)) {
      _selectedSize = _company.profile.companySize;
    }

    _emailController = TextEditingController(text: _company.contact.email);
    _phoneController = TextEditingController(text: _company.contact.phone);
    _addressController = TextEditingController(
      text: _company.contact.addressLine,
    );
    _cityController = TextEditingController(text: _company.contact.city);
    _stateController = TextEditingController(text: _company.contact.state);
    _countryController = TextEditingController(text: _company.contact.country);
    _postalCodeController = TextEditingController(
      text: _company.contact.postalCode,
    );
    _foundedYearController = TextEditingController(
      text: _company.profile.foundedYear?.toString() ?? '',
    );

    _gstController = TextEditingController(text: _company.business.gstOrTaxId);
    _regNumberController = TextEditingController(
      text: _company.business.registrationNumber,
    );

    _linkedinController = TextEditingController(text: _company.social.linkedin);
    _twitterController = TextEditingController(text: _company.social.twitter);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    _foundedYearController.dispose();
    _gstController.dispose();
    _regNumberController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    super.dispose();
  }

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String logoUrl = _company.profile.logoUrl;

      if (_selectedLogo != null) {
        final storageService = ref.read(storageServiceProvider);
        logoUrl = await storageService.uploadImage(
          _selectedLogo!,
          'company_logos/${_company.id}',
        );
      }

      final updatedCompany = _company.copyWith(
        profile: _company.profile.copyWith(
          companyName: _nameController.text.trim(),
          tagline: _taglineController.text.trim(),
          about: _descriptionController.text.trim(),
          website: _websiteController.text.trim(),
          industry: _selectedIndustry ?? '',
          companySize: _selectedSize ?? '',
          foundedYear: int.tryParse(_foundedYearController.text.trim()),
          logoUrl: logoUrl,
        ),
        contact: _company.contact.copyWith(
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          addressLine: _addressController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          country: _countryController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
        ),
        business: _company.business.copyWith(
          gstOrTaxId: _gstController.text.trim(),
          registrationNumber: _regNumberController.text.trim(),
        ),
        social: _company.social.copyWith(
          linkedin: _linkedinController.text.trim(),
          twitter: _twitterController.text.trim(),
        ),
      );

      await ref
          .read(companyRepositoryProvider)
          .updateCompanyProfile(updatedCompany);

      // Refresh the provider
      ref.invalidate(companyDetailsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company details updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating details: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedLogo = File(pickedFile.path);
      });
    }
  }

  void _addOffice() {
    showDialog(
      context: context,
      builder: (ctx) {
        final streetCtrl = TextEditingController();
        final cityCtrl = TextEditingController();
        final stateCtrl = TextEditingController();
        final countryCtrl = TextEditingController();
        final zipCtrl = TextEditingController();

        return AlertDialog(
          title: const Text('Add Office Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: streetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Street Address',
                  ),
                ),
                TextField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                TextField(
                  controller: stateCtrl,
                  decoration: const InputDecoration(labelText: 'State'),
                ),
                TextField(
                  controller: countryCtrl,
                  decoration: const InputDecoration(labelText: 'Country'),
                ),
                TextField(
                  controller: zipCtrl,
                  decoration: const InputDecoration(labelText: 'Postal Code'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newOffice = CompanyAddress(
                  street: streetCtrl.text.trim(),
                  city: cityCtrl.text.trim(),
                  state: stateCtrl.text.trim(),
                  country: countryCtrl.text.trim(),
                  pincode: zipCtrl.text.trim(),
                );

                setState(() {
                  _company = _company.copyWith(
                    contact: _company.contact.copyWith(
                      additionalOffices: [
                        ..._company.contact.additionalOffices,
                        newOffice,
                      ],
                    ),
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeOffice(int index) {
    setState(() {
      final offices = List<CompanyAddress>.from(
        _company.contact.additionalOffices,
      );
      offices.removeAt(index);
      _company = _company.copyWith(
        contact: _company.contact.copyWith(additionalOffices: offices),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'EDIT PROFILE',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: colorScheme.background,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCompany,
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : Text(
                    'SAVE',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.surface,
                          border: Border.all(color: AppColors.borderLight),
                          image: _selectedLogo != null
                              ? DecorationImage(
                                  image: FileImage(_selectedLogo!),
                                  fit: BoxFit.cover,
                                )
                              : (_company.profile.logoUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          _company.profile.logoUrl,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                        ),
                        child:
                            (_selectedLogo == null &&
                                _company.profile.logoUrl.isEmpty)
                            ? Icon(
                                Icons.add_a_photo_outlined,
                                color: AppColors.textSubLight,
                                size: 30,
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CHANGE LOGO',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              _buildSectionHeader('BASIC INFO', theme),
              _buildTextField(
                'Company Name',
                _nameController,
                theme,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              _buildTextField('Tagline', _taglineController, theme),
              _buildDropdownField(
                'Industry',
                _selectedIndustry,
                _industries,
                theme,
                (val) => setState(() => _selectedIndustry = val),
              ),
              _buildDropdownField(
                'Company Size',
                _selectedSize,
                _companySizes,
                theme,
                (val) => setState(() => _selectedSize = val),
              ),

              _buildTextField(
                'Founded Year',
                _foundedYearController,
                theme,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final year = int.tryParse(v);
                    if (year == null ||
                        year < 1000 ||
                        year > DateTime.now().year) {
                      return 'Invalid year';
                    }
                  }
                  return null;
                },
              ),
              _buildTextField(
                'About',
                _descriptionController,
                theme,
                maxLines: 5,
              ),
              _buildTextField('Website', _websiteController, theme),

              const SizedBox(height: 40),
              _buildSectionHeader('CONTACT INFO', theme),
              _buildTextField('Email', _emailController, theme),
              _buildTextField('Phone', _phoneController, theme),
              _buildTextField('Address', _addressController, theme),
              const SizedBox(height: 16),
              CSCPickerPlus(
                showStates: true,
                showCities: true,
                flagState: CountryFlag.DISABLE,
                dropdownDecoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderLight, width: 1),
                  ),
                ),
                disabledDropdownDecoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderLight, width: 1),
                  ),
                ),
                countrySearchPlaceholder: "Country",
                stateSearchPlaceholder: "State",
                citySearchPlaceholder: "City",
                countryDropdownLabel: _countryController.text.isNotEmpty
                    ? _countryController.text
                    : "Country",
                stateDropdownLabel: _stateController.text.isNotEmpty
                    ? _stateController.text
                    : "State",
                cityDropdownLabel: _cityController.text.isNotEmpty
                    ? _cityController.text
                    : "City",
                currentCountry: _countryController.text.isNotEmpty
                    ? _countryController.text
                    : null,
                currentState: _stateController.text.isNotEmpty
                    ? _stateController.text
                    : null,
                currentCity: _cityController.text.isNotEmpty
                    ? _cityController.text
                    : null,
                onCountryChanged: (value) {
                  setState(() {
                    _countryController.text = value;
                  });
                },
                onStateChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _stateController.text = value;
                    });
                  }
                },
                onCityChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _cityController.text = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildTextField('Zip Code', _postalCodeController, theme),

              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('OFFICE LOCATIONS', theme),
                  TextButton(
                    onPressed: _addOffice,
                    child: Text(
                      '+ ADD',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (_company.contact.additionalOffices.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No additional offices.',
                    style: theme.textTheme.bodySmall,
                  ),
                )
              else
                ..._company.contact.additionalOffices.asMap().entries.map((
                  entry,
                ) {
                  final index = entry.key;
                  final office = entry.value;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${office.city}, ${office.country}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (office.street.isNotEmpty)
                              Text(
                                office.street,
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: AppColors.textSubLight,
                            size: 18,
                          ),
                          onPressed: () => _removeOffice(index),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 40),
              _buildSectionHeader('BUSINESS DETAILS', theme),
              _buildTextField('GST / Tax ID', _gstController, theme),
              _buildTextField(
                'Registration Number',
                _regNumberController,
                theme,
              ),

              const SizedBox(height: 40),
              _buildSectionHeader('SOCIAL LINKS', theme),
              _buildTextField('LinkedIn', _linkedinController, theme),
              _buildTextField('Twitter', _twitterController, theme),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    ThemeData theme, {
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        cursorColor: theme.colorScheme.primary,
        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.bodySmall,
          floatingLabelStyle: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          isDense: true,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    ThemeData theme,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.bodySmall,
          floatingLabelStyle: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          isDense: true,
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: theme.colorScheme.onSurface,
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item, style: theme.textTheme.bodyMedium),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
