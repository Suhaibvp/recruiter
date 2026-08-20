import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:recruiter_talentbay/features/candidates/repositories/candidate_repository.dart';
import 'package:recruiter_talentbay/features/candidates/views/candidate_details_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recruiter_talentbay/features/jobs/models/job_application_model.dart';
import 'package:recruiter_talentbay/features/jobs/models/job_model.dart';
import 'package:recruiter_talentbay/features/jobs/repositories/job_repository.dart';
import '../../../theme/app_colors.dart';
import '../../subscription/views/subscription_screen.dart';
import 'package:recruiter_talentbay/features/auth/controllers/auth_controller.dart';
import 'package:recruiter_talentbay/core/services/ai_service.dart';
import 'package:recruiter_talentbay/features/candidates/models/candidate_model.dart';

class ApplicationWithMatch {
  final JobApplicationModel application;
  final CandidateModel candidate;
  final double matchScore;
  final String matchReason;

  ApplicationWithMatch({
    required this.application,
    required this.candidate,
    required this.matchScore,
    required this.matchReason,
  });
}

final sortedApplicationsProvider = StreamProvider.family<List<ApplicationWithMatch>, JobModel>((ref, job) async* {
  final jobRepo = ref.watch(jobRepositoryProvider);
  final candidateRepo = ref.watch(candidateRepositoryProvider);

  await for (final applications in jobRepo.getApplicationsStream(job.jobId)) {
    if (applications.isEmpty) {
      yield [];
      continue;
    }

    final candidateIds = applications.map((a) => a.candidateId).toList();
    final candidates = await candidateRepo.getCandidates(candidateIds);
    final candidateMap = {for (var c in candidates) c.uid: c};

    List<ApplicationWithMatch> result = [];
    for (var app in applications) {
      final candidate = candidateMap[app.candidateId];
      if (candidate != null) {
        final recommendation = AIService.evaluate(candidate, job);
        result.add(
          ApplicationWithMatch(
            application: app,
            candidate: candidate,
            matchScore: recommendation.score,
            matchReason: recommendation.reason,
          ),
        );
      }
    }

    result.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    yield result;
  }
});

class JobDetailsScreen extends ConsumerStatefulWidget {
  final String jobId;
  final JobModel? job;

  const JobDetailsScreen({super.key, required this.jobId, this.job});

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  late Future<JobModel?> _jobFuture;

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      _jobFuture = Future.value(widget.job);
    } else {
      _jobFuture = ref.read(jobRepositoryProvider).getJob(widget.jobId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.job != null) {
      return _buildJobContent(context, ref, widget.job!);
    }

    return FutureBuilder<JobModel?>(
      future: _jobFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.background,
              elevation: 0,
              iconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            body: Center(
              child: Text(
                snapshot.hasError
                    ? 'Error: ${snapshot.error}'
                    : 'Job not found',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        return _buildJobContent(context, ref, snapshot.data!);
      },
    );
  }

  Widget _buildJobContent(BuildContext context, WidgetRef ref, JobModel job) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authControllerProvider.notifier).currentUser;
    final recruiterAsync = ref.watch(recruiterProfileProvider(user?.uid ?? ''));

    final isSubscribed = recruiterAsync.when(
      data: (data) => data?.isSubscribed ?? false,
      error: (_, __) => false,
      loading: () => false,
    );

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          job.roleName.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
        actions: [
          if (job.status == 'active')
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    title: Text(
                      'CLOSE POSITION',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: const Text(
                      'Are you sure you want to close this job position? \n\nWARNING: This will permanently DELETE all applications and chat history associated with this job. This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('CLOSE JOB'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  // GATING: Check Subscription for Close Action (if desired, or leave open)
                  // Requirement says "based way, and i neeed to unlock features , for post a new job, showing this applyed candidate, and message and shortlist and acccept reject for this application for candiddate if you need to unlock uisng this feture"
                  // It also says "and also clos this job repost , based like that"
                  // Implies Repost needs gating. Close might usually be free, but let's check requirement.
                  // "clos this job repost" -> ambiguous. Likely means "Close" AND "Repost".
                  // Let's gate Close for consistency if user implied full control gating.
                  // But normally closing should be allowed? User said "clos this job repost". I will gate Repost definitely.
                  // I will NOT gate Close for now unless explicitly needed, as closing is usually a basic right.
                  // Wait, "clos this job repost" might mean "Closed Jobs Repost".
                  // I will stick to Repost gating.

                  try {
                    await ref
                        .read(jobRepositoryProvider)
                        .closeJob(job.jobId, job.recruiterId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Job closed and data cleaned up'),
                        ),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              },
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          if (job.status == 'closed')
            TextButton(
              onPressed: () async {
                final vacanciesController = TextEditingController();
                final shouldRepost = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    title: Text(
                      'REPOST JOB',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Enter the number of vacancies for this position:',
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: vacanciesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Vacancies',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: () {
                          if (vacanciesController.text.isNotEmpty &&
                              int.tryParse(vacanciesController.text) != null) {
                            Navigator.pop(ctx, true);
                          }
                        },
                        child: const Text('REPOST'),
                      ),
                    ],
                  ),
                );

                if (shouldRepost == true) {
                  // GATING: Repost
                  if (!isSubscribed) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    );
                    return;
                  }

                  try {
                    final vacancies = int.parse(vacanciesController.text);
                    final jobRepo = ref.read(jobRepositoryProvider);

                    // Create new job ID
                    final newJobId = FirebaseFirestore.instance
                        .collection('jobs')
                        .doc()
                        .id;

                    final newJob = JobModel(
                      jobId: newJobId,
                      companyId: job.companyId,
                      recruiterId: job.recruiterId,
                      roleId: job.roleId,
                      roleName: job.roleName,
                      designationId: job.designationId,
                      designationName: job.designationName,
                      experienceLevel: job.experienceLevel,
                      employmentType: job.employmentType,
                      workMode: job.workMode,
                      jobLocation: job.jobLocation,
                      vacancies: vacancies,
                      officeCount: job.officeCount,
                      experienceRequired: job.experienceRequired,
                      salary: job.salary,
                      skillsRequired: job.skillsRequired,
                      mustHaveSkills: job.mustHaveSkills,
                      niceToHaveSkills: job.niceToHaveSkills,
                      jobDescription: job.jobDescription,
                      responsibilities: job.responsibilities,
                      requirements: job.requirements,
                      interviewProcess: job.interviewProcess,
                      extraQuestions: job.extraQuestions,
                      status: 'active', // Set to active
                      visibility: 'public',
                      postedAt: DateTime.now(), // New post date
                      expiresAt: DateTime.now().add(
                        const Duration(days: 30),
                      ), // New expiry
                      companyName: job.companyName,
                      companyLogoUrl: job.companyLogoUrl,
                    );

                    await jobRepo.createJob(newJob);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Job reposted successfully'),
                        ),
                      );
                      // Go to home/active jobs
                      context.go('/');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              },
              child: Text(
                'REPOST',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Divider
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderLight,
            ),

            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          border: Border.all(color: theme.dividerColor),
                          shape: BoxShape.circle,
                        ),
                        child:
                            job.companyLogoUrl != null &&
                                job.companyLogoUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  job.companyLogoUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.business,
                                color: colorScheme.onSurface,
                                size: 30,
                              ),
                      ),
                      const SizedBox(width: 20),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.companyName?.toUpperCase() ??
                                  'UNKNOWN COMPANY',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              job.roleName.toUpperCase(),
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Location & Date
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${job.jobLocation.city}, ${job.jobLocation.country}'
                                        .toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '•',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'POSTED ${_formatDate(job.postedAt)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Meta Info Row (Work Mode, Employment Type, etc.)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetaItem('WORK MODE', job.workMode.toUpperCase()),
                        _buildMetaItem(
                          'TYPE',
                          job.employmentType.toUpperCase(),
                        ),
                        if (job.experienceLevel.isNotEmpty)
                          _buildMetaItem(
                            'LEVEL',
                            job.experienceLevel.toUpperCase(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Key Info Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('OVERVIEW'),
                  const SizedBox(height: 20),
                  _buildMinimalInfoGrid(context, job),
                  const SizedBox(height: 48),

                  // Description
                  _buildSectionTitle('ABOUT THE ROLE'),
                  const SizedBox(height: 16),
                  Text(
                    job.jobDescription,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Responsibilities
                  if (job.responsibilities.isNotEmpty) ...[
                    _buildSectionTitle('KEY RESPONSIBILITIES'),
                    const SizedBox(height: 16),
                    ...job.responsibilities.map(
                      (resp) => _buildBulletPoint(resp),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Requirements
                  if (job.requirements.isNotEmpty) ...[
                    _buildSectionTitle('REQUIREMENTS'),
                    const SizedBox(height: 16),
                    ...job.requirements.map((req) => _buildBulletPoint(req)),
                    const SizedBox(height: 32),
                  ],

                  // Skills
                  if (job.skillsRequired.isNotEmpty) ...[
                    _buildSectionTitle('SKILLS REQUIRED'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: job.skillsRequired
                          .map((skill) => _buildMinimalSkillChip(skill))
                          .toList(),
                    ),
                    const SizedBox(height: 48),
                  ],

                  // Applications Section
                  const Divider(thickness: 1, color: AppColors.borderLight),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('APPLICATIONS'),
                      // Could add a count badge here if available synchronously
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildApplicationsList(ref, job.jobId, job),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSubLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Theme.of(context).colorScheme.onSurface),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMinimalInfoGrid(BuildContext context, JobModel job) {
    final currency = job.salary.currency;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildMinimalInfoItem(
            'SALARY',
            '$currency ${_formatNumber(job.salary.min)} - ${_formatNumber(job.salary.max)}',
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildMinimalInfoItem(
            'EXPERIENCE',
            '${job.experienceRequired.minYears}-${job.experienceRequired.maxYears} YEARS',
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildMinimalInfoItem('VACANCIES', '${job.vacancies} OPEN'),
        ),
      ],
    );
  }

  Widget _buildMinimalInfoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSubLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList(WidgetRef ref, String jobId, JobModel job) {
    final user = ref.watch(authControllerProvider.notifier).currentUser;
    final recruiterAsync = ref.watch(recruiterProfileProvider(user?.uid ?? ''));

    final isSubscribed = recruiterAsync.when(
      data: (data) => data?.isSubscribed ?? false,
      error: (_, __) => false,
      loading: () => false,
    );

    if (!isSubscribed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.lock_outline, size: 48, color: AppColors.textSubLight),
            const SizedBox(height: 16),
            Text(
              'UNLOCK CANDIDATES',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to view applications and contact candidates directly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSubLight),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              child: const Text('UPGRADE NOW'),
            ),
          ],
        ),
      );
    }

    final sortedAppsAsync = ref.watch(sortedApplicationsProvider(job));

    return sortedAppsAsync.when(
      data: (applications) {
        if (applications.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No applications yet.',
                    style: TextStyle(
                      color: AppColors.textSubLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: applications.length,
          separatorBuilder: (context, index) =>
              const Divider(color: AppColors.borderLight),
          itemBuilder: (context, index) {
            final appMatch = applications[index];
            return _ApplicationListTile(appMatch: appMatch, job: job);
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Colors.black),
        ),
      ),
      error: (e, st) => Text('Error loading applications: $e'),
    );
  }

  String _formatNumber(double number) {
    if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(0)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toStringAsFixed(0);
  }

  String _formatDate(DateTime date) {
    // Keeping simple format as requested
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ApplicationListTile extends ConsumerWidget {
  final ApplicationWithMatch appMatch;
  final JobModel? job;

  const _ApplicationListTile({required this.appMatch, this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final candidate = appMatch.candidate;
    final application = appMatch.application;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        backgroundImage: candidate.photoUrl != null && candidate.photoUrl!.isNotEmpty
            ? NetworkImage(candidate.photoUrl!)
            : null,
        child: candidate.photoUrl == null || candidate.photoUrl!.isEmpty
            ? Text(
                candidate.firstName != null &&
                        candidate.firstName!.isNotEmpty
                    ? candidate.firstName![0].toUpperCase()
                    : 'C',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        candidate.fullName.isNotEmpty ? candidate.fullName : 'Unknown Candidate',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (candidate.bio != null)
            Text(
              candidate.bio!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: application.applicationStatus == 'pending'
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: application.applicationStatus == 'pending'
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  application.applicationStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: application.applicationStatus == 'pending'
                        ? Colors.orange
                        : Colors.green,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat.yMMMd()
                    .format(application.appliedAt)
                    .toUpperCase(),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Text(
              '${appMatch.matchScore.toStringAsFixed(0)}% MATCH',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.black),
        ],
      ),
      onTap: () {
        // Navigate to full candidate detail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CandidateDetailsScreen(
              candidateId: application.candidateId,
              candidate: candidate,
              job: job,
              application: application,
            ),
          ),
        );
      },
    );
  }
}
