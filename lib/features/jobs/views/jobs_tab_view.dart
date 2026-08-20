import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:recruiter_talentbay/features/auth/controllers/auth_controller.dart';
import 'package:recruiter_talentbay/features/subscription/views/subscription_screen.dart';
import 'package:recruiter_talentbay/features/jobs/models/job_model.dart';
import 'package:recruiter_talentbay/features/jobs/repositories/job_repository.dart';
import '../../../theme/app_colors.dart';

class JobsTabView extends ConsumerWidget {
  const JobsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.notifier).currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (user == null) {
      return Center(
        child: Text(
          'Please log in to view jobs',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    final recruiterAsync = ref.watch(recruiterProfileProvider(user.uid));

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: recruiterAsync.when(
        data: (recruiter) {
          if (recruiter == null) {
            return Center(
              child: Text(
                'Recruiter profile not found',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }
          final companyId = recruiter.companyId;

          return _JobsList(companyId: companyId);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final recruiter = recruiterAsync.value;
          final isSubscribed = recruiter?.isSubscribed == true && 
              (recruiter?.subscriptionExpiry == null || !recruiter!.subscriptionExpiry!.isBefore(DateTime.now()));
          if (!isSubscribed) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen()));
            return;
          }
          context.push('/create-job');
        },
        backgroundColor: colorScheme.primary, // Pantone 320C
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ), // Sharp
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _JobsList extends ConsumerWidget {
  final String companyId;

  const _JobsList({required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobRepo = ref.watch(jobRepositoryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<List<JobModel>>(
      stream: jobRepo.getJobsStream(companyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading jobs: ${snapshot.error}'));
        }

        final allJobs = snapshot.data ?? [];
        final jobs = allJobs.where((job) => job.status == 'active').toList();

        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.work_outline,
                  size: 48,
                  color: AppColors.textSubLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'NO JOBS POSTED',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.textSubLight,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
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
                    context.push('/create-job');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    'POST A JOB',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final job = jobs[index];
            return InkWell(
              onTap: () {
                context.push('/job/${job.jobId}', extra: job);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: theme.dividerColor),
                  // Sharp corners implicit by default container or Explicit
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.roleName.toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${job.designationName} • ${job.jobLocation.city}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Posted ${DateFormat.yMMMd().format(job.postedAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSubLight,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            title: Text(
                              'DELETE JOB',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: const Text(
                              'Are you sure you want to delete this job posting?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(
                                  'CANCEL',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                  ),
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
                                child: const Text('DELETE'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await jobRepo.deleteJob(job.jobId, job.recruiterId);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
