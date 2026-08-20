import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/job_repository.dart';
import '../models/job_model.dart';
import '../../../../core/services/local_ai_service.dart';

final jobControllerProvider = NotifierProvider<JobController, bool>(
  JobController.new,
);

class JobController extends Notifier<bool> {
  late final JobRepository _jobRepository;

  @override
  bool build() {
    _jobRepository = ref.watch(jobRepositoryProvider);
    return false;
  }

  Future<void> createJob({
    required JobModel job,
    required BuildContext context,
  }) async {
    state = true;
    try {
      await _jobRepository.createJob(job);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post job: $e')));
        print(e);
      }
    } finally {
      state = false;
    }
  }

  // AI Description Generation
  // AI Description Generation
  Future<GeneratedJobContent> generateJobDescription(
    String role,
    List<String> skills,
  ) async {
    state = true; // Show loading if needed, or let UI handle it
    try {
      final content = await ref
          .read(localAiServiceProvider)
          .generateJobContent(role, skills);
      return content;
    } finally {
      state = false;
    }
  }
}
