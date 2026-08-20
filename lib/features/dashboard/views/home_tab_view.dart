import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:recruiter_talentbay/features/auth/controllers/auth_controller.dart';
import 'package:recruiter_talentbay/features/candidates/models/candidate_model.dart';
import 'package:recruiter_talentbay/features/candidates/repositories/candidate_repository.dart';
import 'package:recruiter_talentbay/features/candidates/views/candidate_details_screen.dart';
import 'package:recruiter_talentbay/features/candidates/views/candidate_connect_screen.dart';
import 'package:recruiter_talentbay/features/jobs/models/job_application_model.dart';
import 'package:recruiter_talentbay/features/jobs/repositories/job_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recruiter_talentbay/features/jobs/models/job_model.dart';
import 'package:recruiter_talentbay/features/company/models/company_model.dart';
import 'package:recruiter_talentbay/features/company/repositories/company_repository.dart';
import 'package:recruiter_talentbay/features/notifications/views/notification_screen.dart';
import 'package:recruiter_talentbay/features/notifications/providers/notification_provider.dart';

class HomeTabView extends ConsumerWidget {
  const HomeTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.notifier).currentUser;
    final recruiterAsync = ref.watch(recruiterProfileProvider(user?.uid ?? ''));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant Header
          recruiterAsync.when(
            data: (recruiter) {
              if (recruiter == null) return const SizedBox(height: 60);
              return _DashboardHeader(companyId: recruiter.companyId);
            },
            loading: () => const SizedBox(height: 60),
            error: (_, __) => const SizedBox(height: 60),
          ),

          const SizedBox(height: 40),

          // Live Monitoring
          recruiterAsync.when(
            data: (recruiter) {
              if (recruiter == null) return const SizedBox();
              return _LiveMonitoringSection(companyId: recruiter.companyId);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),

          const SizedBox(height: 48),

          // Suitable Candidates
          recruiterAsync.when(
            data: (recruiter) {
              if (recruiter == null) return const SizedBox();
              return _SuitableCandidatesSection(companyId: recruiter.companyId);
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),

          const SizedBox(height: 48),

          // Recent Jobs
          recruiterAsync.when(
            data: (recruiter) {
              if (recruiter == null) return const SizedBox();
              return _RecentJobsSection(companyId: recruiter.companyId);
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),

          const SizedBox(height: 80), // Bottom padding
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// LIVE MONITORING
// -----------------------------------------------------------------------------

class _LiveMonitoringSection extends ConsumerWidget {
  final String companyId;

  const _LiveMonitoringSection({required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobRepo = ref.watch(jobRepositoryProvider);

    return StreamBuilder<List<JobModel>>(
      stream: jobRepo.getJobsStream(companyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final activeJobs = snapshot.data!
            .where((j) => j.status == 'active')
            .take(5)
            .toList();

        if (activeJobs.isEmpty) {
          return _buildStatCard(
            context,
            count: 0,
            label: 'ACTIVE APPLICANTS',
            subLabel: 'No active jobs posted',
          );
        }

        // Aggregate applications for top active jobs
        // We use a FutureBuilder to fetch applications for these jobs
        return FutureBuilder<List<List<JobApplicationModel>>>(
          future: Future.wait(
            activeJobs.map(
              (job) => jobRepo.getApplicationsStream(job.jobId).first,
            ),
          ),
          builder: (context, appSnap) {
            int totalRecentApplications = 0;
            int totalPendingInvitations = 0;

            if (appSnap.hasData) {
              for (var list in appSnap.data!) {
                for (var app in list) {
                  // Count 'applied' (active applicants)
                  if (app.applicationStatus == 'applied') {
                    totalRecentApplications++;
                  }
                  // Count 'invited' (pending invitations)
                  else if (app.applicationStatus == 'invited') {
                    totalPendingInvitations++;
                  }
                }
              }
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.zero, // Sharp
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MAIN STAT: APPLIED
                  Text(
                    totalRecentApplications.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 64,
                      fontWeight: FontWeight.w100,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'APPLIED APPLICANTS',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'ACROSS ${activeJobs.length} ACTIVE JOBS',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withOpacity(0.7),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),

                  // SECONDARY STAT: INVITED (If any)
                  if (totalPendingInvitations > 0) ...[
                    const SizedBox(height: 24),
                    Divider(color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CandidateConnectScreen(
                              companyId: companyId,
                              initialIndex: 1, // 'INVITED' tab
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            totalPendingInvitations.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PENDING INVITATIONS',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'TAP TO VIEW',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.tertiary, // Accent color
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required int count,
    required String label,
    required String subLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.zero, // Sharp
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 64,
              fontWeight: FontWeight.w100, // Thin elegant font
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 14,
            ),
          ),
          Text(
            subLabel,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.6),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SUITABLE CANDIDATES
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// SUITABLE CANDIDATES
// -----------------------------------------------------------------------------
class _SuitableCandidatesSection extends ConsumerWidget {
  final String companyId;

  const _SuitableCandidatesSection({required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobRepo = ref.watch(jobRepositoryProvider);
    final candidateRepo = ref.watch(candidateRepositoryProvider);

    return FutureBuilder<List<CandidateModel>>(
      future: candidateRepo.getAllCandidates(limit: 20),
      builder: (context, candidateSnap) {
        if (!candidateSnap.hasData || candidateSnap.data!.isEmpty) {
          return const SizedBox();
        }

        return StreamBuilder<List<JobModel>>(
          stream: jobRepo.getJobsStream(companyId),
          builder: (context, jobSnap) {
            if (!jobSnap.hasData || jobSnap.data!.isEmpty) {
              return const SizedBox();
            }

            final candidates = candidateSnap.data!;
            final activeJobs = jobSnap.data!
                .where((j) => j.status == 'active')
                .toList();

            if (activeJobs.isEmpty) return const SizedBox();

            // Advanced Filtering: Check existing applications/invitations
            return FutureBuilder<List<JobApplicationModel>>(
              future: jobRepo.getApplicationsByCandidates(
                candidates.map((c) => c.uid).toList(),
              ),
              builder: (context, appSnap) {
                if (appSnap.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator(
                    color: Colors.black,
                    backgroundColor: Colors.transparent,
                  );
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

                  if (bestMatch >= 70 && bestJob != null) {
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

                final displayList = suggestions.take(10).toList();

                if (displayList.isEmpty) return const SizedBox();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SUGGESTED FOR YOU',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CandidateConnectScreen(
                                  companyId: companyId,
                                  initialIndex: 0,
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('VIEW ALL'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 280,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: displayList.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final item = displayList[index];
                          final candidate = item['candidate'] as CandidateModel;
                          final match = item['match'] as int;
                          final job = item['job'] as JobModel;

                          return _CandidateCard(
                            candidate: candidate,
                            matchScore: match,
                            forJob: job,
                            ref: ref,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final CandidateModel candidate;
  final int matchScore;
  final JobModel forJob;
  final WidgetRef ref;

  const _CandidateCard({
    required this.candidate,
    required this.matchScore,
    required this.forJob,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
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
        width: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.zero, // Sharp
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: candidate.photoUrl != null
                    ? Image.network(candidate.photoUrl!, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          candidate.firstName?[0] ?? '',
                          style: TextStyle(
                            fontSize: 40,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${matchScore}% MATCH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    candidate.fullName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'For: ${forJob.roleName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const RoundedRectangleBorder(),
                      ),
                      onPressed: () async {
                        final currentUser = ref
                            .read(authControllerProvider.notifier)
                            .currentUser;
                        if (currentUser == null) return;

                        final jobRepo = ref.read(jobRepositoryProvider);

                        try {
                          await jobRepo.inviteCandidate(
                            jobId: forJob.jobId,
                            candidateId: candidate.uid,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invited')),
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
                      child: const Text(
                        'INVITE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// RECENT & CLOSED JOBS
// -----------------------------------------------------------------------------

class _RecentJobsSection extends ConsumerStatefulWidget {
  final String companyId;
  const _RecentJobsSection({required this.companyId});

  @override
  ConsumerState<_RecentJobsSection> createState() => _RecentJobsSectionState();
}

class _RecentJobsSectionState extends ConsumerState<_RecentJobsSection> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final jobRepo = ref.watch(jobRepositoryProvider);

    return Column(
      children: [
        Row(
          children: [
            _buildTabItem(0, 'ACTIVE JOBS'),
            const SizedBox(width: 24),
            _buildTabItem(1, 'CLOSED POSITIONS'),
          ],
        ),
        const SizedBox(height: 24),
        StreamBuilder<List<JobModel>>(
          stream: jobRepo.getJobsStream(widget.companyId),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            final allJobs = snapshot.data!;
            final activeJobs = allJobs
                .where((j) => j.status == 'active')
                .toList();
            final closedJobs = allJobs
                .where((j) => j.status == 'closed')
                .toList();

            final jobsToShow = _selectedIndex == 0 ? activeJobs : closedJobs;

            return _buildJobList(jobsToShow, isActive: _selectedIndex == 0);
          },
        ),
      ],
    );
  }

  Widget _buildTabItem(int index, String text) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildJobList(List<JobModel> jobs, {required bool isActive}) {
    if (jobs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            isActive ? 'NO ACTIVE JOBS' : 'NO CLOSED POSITIONS',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              letterSpacing: 1,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return InkWell(
          onTap: () {
            context.push('/job/${job.jobId}', extra: job);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.zero, // Sharp
              color: Theme.of(context).cardTheme.color,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.roleName.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'POSTED ${DateFormat.MMMd().format(job.postedAt).toUpperCase()}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isActive)
                  TextButton(
                    onPressed: () async {
                      final vacanciesController = TextEditingController();
                      final shouldRepost = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('REPOST JOB'),
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
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('CANCEL'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                if (vacanciesController.text.isNotEmpty &&
                                    int.tryParse(vacanciesController.text) !=
                                        null) {
                                  Navigator.pop(ctx, true);
                                }
                              },
                              child: const Text('REPOST'),
                            ),
                          ],
                        ),
                      );

                      if (shouldRepost == true) {
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
                            setState(() {
                              _selectedIndex = 0; // Switch to Active Jobs tab
                            });
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      }
                    },
                    child: const Text(
                      'REPOST',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.black,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  final String companyId;

  const _DashboardHeader({required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch company details
    return FutureBuilder<CompanyModel?>(
      future: ref.read(companyRepositoryProvider).fetchCompany(companyId),
      builder: (context, snapshot) {
        String greetingName = '...';

        if (snapshot.hasData && snapshot.data != null) {
          greetingName = snapshot.data!.profile.companyName.toUpperCase();
        }

        final notificationsAsync = ref.watch(notificationsListProvider);
        // ignore: deprecated_member_use
        final unreadCount = notificationsAsync.value?.where((n) => !n.isRead).length ?? 0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WELCOME,',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    greetingName,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'Didot',
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, size: 28),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
