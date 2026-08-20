import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:recruiter_talentbay/features/auth/controllers/auth_controller.dart';
import 'package:recruiter_talentbay/features/jobs/models/job_model.dart';
import 'package:recruiter_talentbay/features/jobs/repositories/job_repository.dart';
import '../../../theme/app_colors.dart';

class ClosedJobsScreen extends ConsumerWidget {
  const ClosedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider.notifier).currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view jobs')),
      );
    }

    final recruiterAsync = ref.watch(recruiterProfileProvider(user.uid));

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'CLOSED POSITIONS',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: recruiterAsync.when(
        data: (recruiter) {
          if (recruiter == null) {
            return const Center(child: Text('Recruiter profile not found'));
          }
          final companyId = recruiter.companyId;
          return _ClosedJobsContent(companyId: companyId);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ClosedJobsContent extends ConsumerStatefulWidget {
  final String companyId;

  const _ClosedJobsContent({required this.companyId});

  @override
  ConsumerState<_ClosedJobsContent> createState() => _ClosedJobsContentState();
}

class _ClosedJobsContentState extends ConsumerState<_ClosedJobsContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobRepo = ref.watch(jobRepositoryProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search closed jobs...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: const BorderSide(color: Colors.black),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<JobModel>>(
            stream: jobRepo.getJobsStream(widget.companyId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading jobs: ${snapshot.error}'),
                );
              }

              final allJobs = snapshot.data ?? [];
              final closedJobs = allJobs
                  .where((job) => job.status == 'closed')
                  .toList();

              // Filter
              final filteredJobs = closedJobs.where((job) {
                return job.roleName.toLowerCase().contains(_searchQuery);
              }).toList();

              // Sort by expiresAt (Closed Date) descending
              filteredJobs.sort((a, b) => b.expiresAt.compareTo(a.expiresAt));

              if (filteredJobs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 48,
                        color: AppColors.textSubLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'NO CLOSED POSITIONS'
                            : 'NO MATCHING JOBS',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.textSubLight,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: filteredJobs.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (context, index) {
                  final job = filteredJobs[index];
                  return InkWell(
                    onTap: () {
                      context.push('/job/${job.jobId}', extra: job);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
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
                                    color: Colors.grey, // Greyed out for closed
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${job.designationName} • ${job.jobLocation.city}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textMainLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Closed on ${DateFormat.yMMMd().format(job.expiresAt)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSubLight,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textSubLight,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
