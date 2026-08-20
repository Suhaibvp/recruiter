import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:recruiter_talentbay/features/auth/models/recruiter_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../repositories/company_repository.dart';
import '../models/company_model.dart';
import 'edit_company_screen.dart';
import '../../../theme/app_colors.dart';

// Provider to fetch both Recruiter and Company data
final companyDetailsProvider =
    FutureProvider.autoDispose<
      ({RecruiterModel? recruiter, CompanyModel? company})
    >((ref) async {
      final user = ref.watch(authControllerProvider.notifier).currentUser;
      if (user == null) return (recruiter: null, company: null);

      try {
        // Wait for the recruiter profile to be loaded
        final recruiter = await ref.watch(
          recruiterProfileProvider(user.uid).future,
        );

        if (recruiter == null) return (recruiter: null, company: null);

        CompanyModel? company;
        if (recruiter.companyId.isNotEmpty) {
          company = await ref
              .read(companyRepositoryProvider)
              .fetchCompany(recruiter.companyId);
        }

        return (recruiter: recruiter, company: company);
      } catch (e) {
        // If recruiter profile fails/errors
        return (recruiter: null, company: null);
      }
    });

class CompanyDetailsScreen extends ConsumerStatefulWidget {
  const CompanyDetailsScreen({super.key});

  @override
  ConsumerState<CompanyDetailsScreen> createState() =>
      _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends ConsumerState<CompanyDetailsScreen> {
  // Controllers for Company
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _foundedYearController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    _sizeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _foundedYearController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();

    super.dispose();
  }

  void _populateControllers(CompanyModel? company) {
    if (company != null) {
      _nameController.text = company.profile.companyName;
      _industryController.text = company.profile.industry;
      _sizeController.text = company.profile.companySize;
      _emailController.text = company.contact.email;
      _phoneController.text = company.contact.phone;
      _websiteController.text = company.profile.website;
      _foundedYearController.text =
          company.profile.foundedYear?.toString() ?? '';
      _addressController.text = company.contact.addressLine;
      _cityController.text = company.contact.city;
      _stateController.text = company.contact.state;
      _countryController.text = company.contact.country;
      _postalCodeController.text = company.contact.postalCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(companyDetailsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'COMPANY PROFILE',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: colorScheme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          detailsAsync.maybeWhen(
            data: (data) => data.company != null
                ? IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: colorScheme.onSurface,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditCompanyScreen(company: data.company!),
                        ),
                      );
                    },
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailsAsync.when(
        data: (data) {
          final company = data.company;
          final recruiter = data.recruiter;

          if (recruiter == null) {
            return Center(child: Text('No admin profile found.'));
          }

          _populateControllers(company);

          if (company == null) {
            return Center(child: Text('No company details available.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Logo + Name)
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          border: Border.all(color: AppColors.borderLight),
                          borderRadius: BorderRadius.zero,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: company.profile.logoUrl.isNotEmpty
                            ? Image.network(
                                company.profile.logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, _, __) => Center(
                                  child: Text(
                                    company.profile.companyName.isNotEmpty
                                        ? company.profile.companyName[0]
                                              .toUpperCase()
                                        : 'C',
                                    style: theme.textTheme.displayMedium,
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  company.profile.companyName.isNotEmpty
                                      ? company.profile.companyName[0]
                                            .toUpperCase()
                                      : 'C',
                                  style: theme.textTheme.displayMedium,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        company.profile.companyName.toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (company.profile.tagline.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          company.profile.tagline,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSubLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 24),

                // ABOUT
                _buildSectionTitle('ABOUT', theme),
                const SizedBox(height: 12),
                Text(
                  company.profile.about.isNotEmpty
                      ? company.profile.about
                      : 'No description added.',
                  style: theme.textTheme.bodyMedium,
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // DETAILS
                _buildSectionTitle('DETAILS', theme),
                const SizedBox(height: 16),
                _buildDetailRow('Industry', _industryController.text, theme),
                _buildDetailRow('Size', _sizeController.text, theme),
                _buildDetailRow('Founded', _foundedYearController.text, theme),
                _buildDetailRow('Website', _websiteController.text, theme),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // CONTACT
                _buildSectionTitle('CONTACT', theme),
                const SizedBox(height: 16),
                _buildDetailRow('Email', _emailController.text, theme),
                _buildDetailRow('Phone', _phoneController.text, theme),
                _buildDetailRow('Address', _addressController.text, theme),
                _buildDetailRow(
                  'Location',
                  '${_cityController.text}, ${_countryController.text}',
                  theme,
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSubLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
