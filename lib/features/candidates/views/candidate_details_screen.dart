import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:recruiter_talentbay/features/candidates/models/candidate_model.dart';
import 'package:recruiter_talentbay/features/candidates/repositories/candidate_repository.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:recruiter_talentbay/core/services/ai_service.dart';
import 'package:recruiter_talentbay/features/jobs/models/job_application_model.dart';
import 'package:recruiter_talentbay/features/jobs/models/job_model.dart';
import 'package:recruiter_talentbay/features/jobs/repositories/job_repository.dart';
import 'package:recruiter_talentbay/features/chat/repositories/chat_repository.dart';
import 'package:recruiter_talentbay/features/chat/views/chat_screen.dart';
import 'package:recruiter_talentbay/features/auth/controllers/auth_controller.dart';
import 'package:recruiter_talentbay/features/subscription/views/subscription_screen.dart';
import '../../../theme/app_colors.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class CandidateDetailsScreen extends ConsumerWidget {
  final String candidateId;
  final CandidateModel? candidate; // Pass if already available
  final JobModel? job; // Context for AI recommendation
  final JobApplicationModel? application; // Context for status update

  const CandidateDetailsScreen({
    super.key,
    required this.candidateId,
    this.candidate,
    this.job,
    this.application,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (candidate != null) {
      return _buildContent(context, ref, candidate!);
    }

    return FutureBuilder<CandidateModel?>(
      future: ref.read(candidateRepositoryProvider).getCandidate(candidateId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.background,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.background,
            ),
            body: Center(
              child: Text(
                snapshot.hasError
                    ? 'Error: ${snapshot.error}'
                    : 'Candidate not found',
              ),
            ),
          );
        }

        return _buildContent(context, ref, snapshot.data!);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    CandidateModel candidate,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'CANDIDATE PROFILE',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: colorScheme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderLight, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (job != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: _buildAiRecommendation(context, ref, candidate, job!),
              ),

            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surface,
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: candidate.photoUrl != null
                        ? Image.network(
                            candidate.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, _, __) => Center(
                              child: Text(
                                candidate.fullName.isNotEmpty
                                    ? candidate.fullName[0].toUpperCase()
                                    : 'C',
                                style: theme.textTheme.displayMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              candidate.fullName.isNotEmpty
                                  ? candidate.fullName[0].toUpperCase()
                                  : 'C',
                              style: theme.textTheme.displayMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    candidate.fullName.toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (candidate.bio != null && candidate.bio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      candidate.bio!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSubLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Location & Contact
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (candidate.currentLocation != null) ...[
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.textSubLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${candidate.currentLocation!.city}, ${candidate.currentLocation!.country}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSubLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (candidate.email.isNotEmpty ||
                      candidate.phoneNumber != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (candidate.email.isNotEmpty)
                          InkWell(
                            onTap: () =>
                                _launchURL('mailto:${candidate.email}'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 14,
                                  color: AppColors.tealPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  candidate.email,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSubLight,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (candidate.phoneNumber != null &&
                            candidate.phoneNumber!.isNotEmpty)
                          InkWell(
                            onTap: () =>
                                _launchURL('tel:${candidate.phoneNumber}'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  size: 14,
                                  color: AppColors.tealPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  candidate.phoneNumber!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSubLight,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            if (application != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                child: _buildActionButtons(
                  context,
                  ref,
                  application!,
                  candidate,
                ),
              ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About Me
                  if (candidate.aboutMe != null &&
                      candidate.aboutMe!.isNotEmpty) ...[
                    _buildSectionTitle(context, 'ABOUT'),
                    const SizedBox(height: 16),
                    Text(
                      candidate.aboutMe!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                  ],

                  // Skills
                  if (candidate.skills.isNotEmpty) ...[
                    _buildSectionTitle(context, 'SKILLS'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: candidate.skills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderLight),
                            borderRadius: BorderRadius.zero, // Sharp
                          ),
                          child: Text(
                            skill,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                  ],

                  // Experience
                  if (candidate.workExperience.isNotEmpty) ...[
                    _buildSectionTitle(context, 'EXPERIENCE'),
                    const SizedBox(height: 16),
                    ...candidate.workExperience.map(
                      (exp) => _buildExperienceItem(context, exp),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 24),
                  ],

                  // Education
                  if (candidate.education.isNotEmpty) ...[
                    _buildSectionTitle(context, 'EDUCATION'),
                    const SizedBox(height: 16),
                    ...candidate.education.map(
                      (edu) => _buildEducationItem(context, edu),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 24),
                  ],

                  // Projects
                  if (candidate.projects.isNotEmpty) ...[
                    _buildSectionTitle(context, 'PROJECTS'),
                    const SizedBox(height: 16),
                    ...candidate.projects.map(
                      (proj) => _buildProjectItem(context, proj),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 24),
                  ],

                  // Contact Information
                  _buildSectionTitle(context, 'CONTACT INFORMATION'),
                  const SizedBox(height: 16),
                  if (candidate.email.isNotEmpty)
                    _buildLinkItem(
                      context,
                      candidate.email,
                      'mailto:${candidate.email}',
                      Icons.email_outlined,
                    ),
                  if (candidate.phoneNumber != null &&
                      candidate.phoneNumber!.isNotEmpty)
                    _buildLinkItem(
                      context,
                      candidate.phoneNumber!,
                      'tel:${candidate.phoneNumber}',
                      Icons.phone_outlined,
                    ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Links / Resume
                  _buildSectionTitle(context, 'LINKS & DOCUMENTS'),
                  const SizedBox(height: 16),
                  if (candidate.resumeUrl != null &&
                      candidate.resumeUrl!.isNotEmpty)
                    _buildResumeLinkItem(
                      context,
                      'Resume',
                      candidate.resumeUrl!,
                      Icons.description_outlined,
                    ),
                  if (candidate.linkedinProfile != null &&
                      candidate.linkedinProfile!.isNotEmpty)
                    _buildLinkItem(
                      context,
                      'LinkedIn Profile',
                      candidate.linkedinProfile!,
                      Icons.link,
                    ),
                  if (candidate.githubProfile != null &&
                      candidate.githubProfile!.isNotEmpty)
                    _buildLinkItem(
                      context,
                      'GitHub Profile',
                      candidate.githubProfile!,
                      Icons.code,
                    ),
                  if (candidate.portfolioUrl != null &&
                      candidate.portfolioUrl!.isNotEmpty)
                    _buildLinkItem(
                      context,
                      'Portfolio',
                      candidate.portfolioUrl!,
                      Icons.web,
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildLinkItem(
    BuildContext context,
    String title,
    String url,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _launchURL(url),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSubLight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Icon(Icons.arrow_outward, size: 16, color: AppColors.textSubLight),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceItem(BuildContext context, WorkExperience exp) {
    final dateRange =
        '${DateFormat.yMMMd().format(exp.startDate)} - ${exp.isCurrent ? 'Present' : (exp.endDate != null ? DateFormat.yMMMd().format(exp.endDate!) : '')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.jobTitle.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exp.companyName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  dateRange,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSubLight,
                  ),
                ),
                if (exp.description != null && exp.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    exp.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSubLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationItem(BuildContext context, Education edu) {
    final dateRange =
        '${DateFormat.yMMM().format(edu.startDate)} - ${edu.endDate != null ? DateFormat.yMMM().format(edu.endDate!) : 'Present'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edu.school.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${edu.degree}, ${edu.fieldOfStudy}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            dateRange,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSubLight),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectItem(BuildContext context, Project proj) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                proj.title.toUpperCase(),
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (proj.link != null)
                IconButton(
                  icon: const Icon(Icons.arrow_outward, size: 16),
                  onPressed: () => _launchURL(proj.link!),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(proj.description, style: Theme.of(context).textTheme.bodyMedium),
          if (proj.technologies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: proj.technologies
                  .map(
                    (t) => Text(
                      '#$t',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiRecommendation(
    BuildContext context,
    WidgetRef ref,
    CandidateModel candidate,
    JobModel job,
  ) {
    // If we have a saved recommendation in the application, use it (optional optimization)
    // For now, let's recalculate or use saved if available to show "AI Analyzed"
    // Since we don't pass application to this specific widget but we have it in the class...
    // Let's just run the heuristic live for immediate feedback.

    final recommendation = AIService.evaluate(candidate, job);
    final colorScheme = Theme.of(context).colorScheme;

    Color scoreColor = Colors.red;
    if (recommendation.score >= 70)
      scoreColor = Colors.green;
    else if (recommendation.score >= 40)
      scoreColor = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.zero, // Sharp
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI MATCH',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                '${recommendation.score.round()}%',
                style: TextStyle(
                  color: scoreColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.reason,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: recommendation.score / 100,
            backgroundColor: AppColors.borderLight,
            color: scoreColor,
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    JobApplicationModel application,
    CandidateModel candidate,
  ) {
    final status = application.applicationStatus.toLowerCase();

    // If already rejected or hired, show status banner only
    if (['rejected', 'hired', 'accepted'].contains(status)) {
      bool isHired = status == 'hired' || status == 'accepted';
      Color statusColor = isHired ? Colors.green : Colors.red;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.05),
          border: Border.all(color: statusColor.withOpacity(0.2)),
        ),
        child: Text(
          'CANDIDATE ${status.toUpperCase()}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: statusColor,
            letterSpacing: 1.0,
          ),
        ),
      );
    }

    // If shortlisted, show Reject, Hire/Accept and Message
    if (status == 'shortlisted') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _updateStatus(context, ref, 'rejected', candidate),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text('REJECT'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      _updateStatus(context, ref, 'hired', candidate),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text('HIRE / ACCEPT'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openChat(context, ref, candidate),
              icon: const Icon(Icons.message_outlined, size: 18),
              label: const Text('MESSAGE CANDIDATE'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tealPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Default (Applied / Pending): Show Reject and Shortlist
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _updateStatus(context, ref, 'rejected', candidate),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text('REJECT'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton(
            onPressed: () =>
                _updateStatus(context, ref, 'shortlisted', candidate),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: const Text('SHORTLIST'),
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String status,
    CandidateModel candidate,
  ) async {
    final user = ref.read(authControllerProvider.notifier).currentUser;
    if (user != null) {
      final recruiter = ref.read(recruiterProfileProvider(user.uid)).value;
      final isSubscribed = recruiter?.isSubscribed == true &&
          (recruiter?.subscriptionExpiry == null || !recruiter!.subscriptionExpiry!.isBefore(DateTime.now()));
      if (!isSubscribed) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen()));
        return;
      }
    }

    if (application == null) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final repo = ref.read(jobRepositoryProvider);
      final chatRepo = ref.read(chatRepositoryProvider);

      // Update status
      await repo.updateApplicationStatus(application!.applicationId, status);

      // Handle Chat Deletion for Rejected or Hired
      if (['rejected', 'hired', 'accepted'].contains(status)) {
        // Try to find chat and delete it
        try {
          if (job != null) {
            // We need recruiter ID. Assuming current user is recruiter or we can get it from job.
            // JobModel has recruiterId.
            final chatId = await chatRepo.getOrCreateChat(
              jobId: job!.jobId,
              candidateId: candidate.uid,
              recruiterId: job!.recruiterId,
            );
            await chatRepo.deleteChat(chatId);
          }
        } catch (e) {
          print('Error deleting chat: $e');
          // Non-critical, continue
        }
      }

      // Also save AI score if available and not saved
      if (job != null && application!.aiMatchScore == null) {
        final rec = AIService.evaluate(candidate, job!);
        await repo.saveAiRecommendation(
          application!.applicationId,
          rec.score,
          rec.reason,
        );
      }

      if (context.mounted) {
        Navigator.pop(context); // Hide loading
        Navigator.pop(context); // Go back to list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Candidate marked as ${status.toUpperCase()}'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _openChat(
    BuildContext context,
    WidgetRef ref,
    CandidateModel candidate,
  ) async {
    final user = ref.read(authControllerProvider.notifier).currentUser;
    if (user != null) {
      final recruiter = ref.read(recruiterProfileProvider(user.uid)).value;
      final isSubscribed = recruiter?.isSubscribed == true &&
          (recruiter?.subscriptionExpiry == null || !recruiter!.subscriptionExpiry!.isBefore(DateTime.now()));
      if (!isSubscribed) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen()));
        return;
      }
    }

    if (job == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final chatRepo = ref.read(chatRepositoryProvider);
      final chatId = await chatRepo.getOrCreateChat(
        jobId: job!.jobId,
        candidateId: candidate.uid,
        recruiterId: job!.recruiterId,
      );

      if (context.mounted) {
        Navigator.pop(context); // Hide loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserId: candidate.uid,
              candidateName: candidate.fullName,
              jobTitle: job!.roleName,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening chat: $e')));
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Widget _buildResumeLinkItem(
    BuildContext context,
    String title,
    String url,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _downloadAndOpenResume(context, url),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSubLight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Icon(Icons.download, size: 16, color: AppColors.textSubLight),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAndOpenResume(BuildContext context, String url) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'resume_${DateTime.now().millisecondsSinceEpoch}.${url.split('.').last.split('?').first}';
      final file = '${dir.path}/$fileName';

      await Dio().download(url, file);

      if (context.mounted) {
        Navigator.pop(context); // Hide loading
        final result = await OpenFilex.open(file);
        if (result.type != ResultType.done) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open file: ${result.message}')),
            );
            // Fallback to launch URL if opening fails
            _launchURL(url);
          }
        }
      }
    } catch (e) {
      debugPrint('Error downloading resume: $e');
      if (context.mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading resume. Opening in browser...'),
          ),
        );
        _launchURL(url);
      }
    }
  }
}
