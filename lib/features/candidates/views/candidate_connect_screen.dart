import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:recruiter_talentbay/features/auth/controllers/auth_controller.dart';
import 'package:recruiter_talentbay/features/candidates/models/candidate_model.dart';
import 'package:recruiter_talentbay/features/candidates/repositories/candidate_repository.dart';
import 'package:recruiter_talentbay/features/candidates/views/candidate_details_screen.dart';

import 'package:recruiter_talentbay/features/jobs/models/job_application_model.dart';
import 'package:recruiter_talentbay/features/jobs/models/job_model.dart';
import 'package:recruiter_talentbay/features/jobs/repositories/job_repository.dart';
import 'package:recruiter_talentbay/features/subscription/views/subscription_screen.dart';
import 'package:recruiter_talentbay/theme/app_colors.dart';

class CandidateConnectScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  // We might need companyId. If we don't pass it, we can fetch it again.
  // Ideally pass it.
  final String? companyId;

  const CandidateConnectScreen({
    super.key,
    this.initialIndex = 0,
    this.companyId,
  });

  @override
  ConsumerState<CandidateConnectScreen> createState() =>
      _CandidateConnectScreenState();
}

class _CandidateConnectScreenState extends ConsumerState<CandidateConnectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If companyId is not passed, we tried to get it from auth.
    // Ideally the caller passes it. If null, we show loading or user logic.
    // final user = ref.watch(authControllerProvider.notifier).currentUser;

    final companyId = widget.companyId;

    if (companyId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Aesthetic: Minimalist H&M style
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'CANDIDATE NETWORK',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab, // Full width indicator
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1,
            fontFamily: 'Outfit', // Ensure font consistency
          ),
          tabs: const [
            Tab(text: 'SUGGESTIONS'),
            Tab(text: 'INVITED'),
            Tab(text: 'ACCEPTED'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SuggestionsTab(companyId: companyId),
          _StatusTab(companyId: companyId, status: 'invited'),
          _StatusTab(companyId: companyId, status: 'accepted'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: SUGGESTIONS (Full List)
// -----------------------------------------------------------------------------

class _SuggestionsTab extends ConsumerWidget {
  final String companyId;

  const _SuggestionsTab({required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobRepo = ref.watch(jobRepositoryProvider);
    final candidateRepo = ref.watch(candidateRepositoryProvider);

    return FutureBuilder<List<CandidateModel>>(
      // Fetch more candidates for the full view
      future: candidateRepo.getAllCandidates(limit: 50),
      builder: (context, candidateSnap) {
        if (!candidateSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (candidateSnap.data!.isEmpty) {
          return const Center(child: Text('No candidates available.'));
        }

        return StreamBuilder<List<JobModel>>(
          stream: jobRepo.getJobsStream(companyId),
          builder: (context, jobSnap) {
            if (!jobSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final candidates = candidateSnap.data!;
            final activeJobs = jobSnap.data!
                .where((j) => j.status == 'active')
                .toList();

            if (activeJobs.isEmpty) {
              return const Center(
                child: Text('No active jobs to match against.'),
              );
            }

            // Check existing applications
            return FutureBuilder<List<JobApplicationModel>>(
              future: jobRepo.getApplicationsByCandidates(
                candidates.map((c) => c.uid).toList(),
              ),
              builder: (context, appSnap) {
                if (appSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Map of CandidateID -> List of JobIDs they applied/invited to
                final existingApplications = <String, Set<String>>{};
                if (appSnap.hasData) {
                  for (var app in appSnap.data!) {
                    existingApplications
                        .putIfAbsent(app.candidateId, () => {})
                        .add(app.jobId);
                  }
                }

                // Matching Logic
                final suggestions = <Map<String, dynamic>>[];

                for (var candidate in candidates) {
                  int bestMatch = 0;
                  JobModel? bestJob;

                  for (var job in activeJobs) {
                    // Check if already applied/invited
                    if (existingApplications[candidate.uid]?.contains(
                          job.jobId,
                        ) ??
                        false) {
                      continue;
                    }

                    if (job.skillsRequired.isEmpty) continue;

                    final cSkills = candidate.skills
                        .map((s) => s.toLowerCase())
                        .toSet();
                    final jSkills = job.skillsRequired
                        .map((s) => s.toLowerCase())
                        .toSet();
                    final common = jSkills.intersection(cSkills);

                    int match = 0;
                    if (jSkills.isNotEmpty) {
                      match = (common.length / jSkills.length * 100).round();
                    }

                    if (match > bestMatch) {
                      bestMatch = match;
                      bestJob = job;
                    }
                  }

                  if (bestMatch >= 40 && bestJob != null) {
                    suggestions.add({
                      'candidate': candidate,
                      'match': bestMatch,
                      'job': bestJob,
                    });
                  }
                }

                // Sort by Match Score
                suggestions.sort(
                  (a, b) => (b['match'] as int).compareTo(a['match'] as int),
                );

                if (suggestions.isEmpty) {
                  return const Center(
                    child: Text('No new suitable candidates found.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = suggestions[index];
                    return _CandidateListItem(
                      candidate: item['candidate'],
                      matchScore: item['match'],
                      job: item['job'],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2 & 3: INVITED / ACCEPTED
// -----------------------------------------------------------------------------

class _StatusTab extends ConsumerWidget {
  final String companyId;
  final String status; // 'invited' or 'accepted'

  const _StatusTab({required this.companyId, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobRepo = ref.watch(jobRepositoryProvider);
    final candidateRepo = ref.watch(candidateRepositoryProvider);

    return StreamBuilder<List<JobModel>>(
      stream: jobRepo.getJobsStream(companyId),
      builder: (context, jobSnap) {
        if (!jobSnap.hasData)
          return const Center(child: CircularProgressIndicator());

        final allJobs = jobSnap.data!;
        if (allJobs.isEmpty) return const Center(child: Text('No jobs found.'));

        // Fetch applications for ALL jobs (Parallel)
        return FutureBuilder<List<List<JobApplicationModel>>>(
          future: Future.wait(
            allJobs.map((j) => jobRepo.getApplicationsStream(j.jobId).first),
          ),
          builder: (context, appSnap) {
            if (!appSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Flatten and Filter
            final allApps = appSnap.data!.expand((x) => x).toList();

            // Filter by status
            // Note: 'accepted' status might need to match exactly what backend sets.
            // If backend uses 'applied' for accepted invite, request user clarification or assume 'accepted'.
            // Using loose match for now or list of statuses.
            final filteredApps = allApps.where((app) {
              if (status == 'accepted') {
                // Candidates who accepted the invite have status 'applied' and source 'recruiter_invite'
                // Or explicitly 'accepted' if that status is used elsewhere.
                final isAcceptedInvite =
                    app.applicationStatus.toLowerCase() == 'applied' &&
                    app.source == 'recruiter_invite';

                return isAcceptedInvite ||
                    app.applicationStatus.toLowerCase() == 'accepted';
              }
              return app.applicationStatus.toLowerCase() ==
                  status.toLowerCase();
            }).toList();

            if (filteredApps.isEmpty) {
              return Center(
                child: Text(
                  status == 'invited'
                      ? 'No pending invitations.'
                      : 'No accepted invitations.',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredApps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final app = filteredApps[index];
                final job = allJobs.firstWhere((j) => j.jobId == app.jobId);

                return FutureBuilder<CandidateModel?>(
                  future: candidateRepo.getCandidate(app.candidateId),
                  builder: (context, candSnap) {
                    if (!candSnap.hasData) return const SizedBox();
                    final candidate = candSnap.data!;

                    // If we are in the accepted tab and it's an applied invite, show as ACCEPTED
                    String displayStatus = app.applicationStatus;
                    if (status == 'accepted' &&
                        app.applicationStatus.toLowerCase() == 'applied') {
                      displayStatus = 'accepted';
                    }

                    return _CandidateListItem(
                      candidate: candidate,
                      matchScore:
                          null, // Don't strictly need recalculation here
                      job: job,
                      status: displayStatus,
                      appliedAt: app.appliedAt,
                      showInviteAction: false,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// LIST ITEM WIDGET
// -----------------------------------------------------------------------------

class _CandidateListItem extends ConsumerWidget {
  final CandidateModel candidate;
  final int? matchScore;
  final JobModel job;
  final String? status;
  final DateTime? appliedAt;
  final bool showInviteAction;

  const _CandidateListItem({
    required this.candidate,
    required this.job,
    this.matchScore,
    this.status,
    this.appliedAt,
    this.showInviteAction = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CandidateDetailsScreen(
              candidateId: candidate.uid,
              candidate: candidate,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: theme.dividerColor),
          // Flat design - No shadow
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceVariant,
                border: Border.all(color: theme.dividerColor),
                image: candidate.photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(candidate.photoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: candidate.photoUrl == null
                  ? Center(
                      child: Text(
                        candidate.firstName?[0] ?? '',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.fullName.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'For: ${job.roleName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (status != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      status!.toLowerCase() == 'invited'
                          ? 'PENDING'
                          : status!.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: status!.toLowerCase() == 'accepted'
                            ? AppColors.success
                            : (status!.toLowerCase() == 'invited'
                                  ? AppColors.warning
                                  : colorScheme.onSurfaceVariant),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action / Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (matchScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.zero, // Sharp
                    ),
                    child: Text(
                      '$matchScore% MATCH',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (showInviteAction)
                  SizedBox(
                    height: 30,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        side: BorderSide(color: colorScheme.primary),
                        foregroundColor: colorScheme.primary,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // Sharp
                        ),
                      ),
                      onPressed: () async {
                        final currentUser = ref
                            .read(authControllerProvider.notifier)
                            .currentUser;
                        if (currentUser == null) return;

                        final recruiter = ref.read(recruiterProfileProvider(currentUser.uid)).value;
                        final isSubscribed = recruiter?.isSubscribed == true &&
                            (recruiter?.subscriptionExpiry == null || !recruiter!.subscriptionExpiry!.isBefore(DateTime.now()));
                        if (!isSubscribed) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen()));
                          return;
                        }

                        final jobRepo = ref.read(jobRepositoryProvider);
                        try {
                          await jobRepo.inviteCandidate(
                            jobId: job.jobId,
                            candidateId: candidate.uid,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invited successfully'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: Text(
                        'INVITE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else if (appliedAt != null)
                  Text(
                    DateFormat.MMMd().format(appliedAt!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
