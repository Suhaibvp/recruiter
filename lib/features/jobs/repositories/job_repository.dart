import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../models/job_application_model.dart';

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(FirebaseFirestore.instance);
});

class JobRepository {
  final FirebaseFirestore _firestore;

  JobRepository(this._firestore);

  Future<void> createJob(JobModel job) async {
    await _firestore.collection('jobs').doc(job.jobId).set(job.toMap());
  }

  Stream<List<JobModel>> getJobsStream(String companyId) {
    return _firestore
        .collection('jobs')
        .where('companyId', isEqualTo: companyId)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JobModel.fromMap(doc.data()))
              .toList();
        });
  }

  Future<void> deleteJob(String jobId, String recruiterId) async {
    // 1. Delete all Job Applications for this job
    final applicationsQuery = await _firestore
        .collection('job_applications')
        .where('jobId', isEqualTo: jobId)
        .get();

    for (var doc in applicationsQuery.docs) {
      await doc.reference.delete();
    }

    // 2. Delete all Chats and their Messages for this job
    final chatsQuery = await _firestore
        .collection('chats')
        .where('jobId', isEqualTo: jobId)
        .where('recruiterId', isEqualTo: recruiterId)
        .get();

    for (var chatDoc in chatsQuery.docs) {
      // Delete messages subcollection for each chat
      final messagesQuery = await chatDoc.reference
          .collection('messages')
          .get();
      for (var msgDoc in messagesQuery.docs) {
        await msgDoc.reference.delete();
      }
      // Delete the chat document itself
      await chatDoc.reference.delete();
    }

    // 3. Delete the Job document
    await _firestore.collection('jobs').doc(jobId).delete();
  }

  // Stream of applications for a specific job
  Stream<List<JobApplicationModel>> getApplicationsStream(String jobId) {
    return _firestore
        .collection('job_applications')
        .where('jobId', isEqualTo: jobId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JobApplicationModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Stream of all applications for a company (for dashboard monitoring)
  // Note: This requires a composite index on companyId (if added to application) or we query by jobs.
  // Assuming JobApplicationModel doesn't have companyId directly, we might need it or query differently.
  // For now, let's assume we filter client side or applications have companyId.
  // Looking at JobApplicationModel, it DOES NOT have companyId.
  // We can either:
  // 1. Add companyId to JobApplicationModel (Preferred for query efficiency)
  // 2. Query all jobs for company, then query applications in (limit 10 for "in" query).
  // For this task, let's assume we mainly need recent applications across all jobs.
  // To keep it simple and efficient, we should really have companyId on Application.
  // But I cannot easily change the data model validation without user request.
  // So I'll implement a method that fetches applications for a known list of Job IDs?
  // Or simpler: fetch recent applications assuming we modify the model later or use collection group queries if strictly needed.
  // For "Live Monitoring", maybe just showing the count of recent applications for the *Recent Jobs* is enough.
  // Let's stick to getJobsStream for now and maybe we can just fetch applications for the top 5 jobs.

  // New method: Recent applications if we can query by some field.
  // If we can't, let's leave it for now and handle per-job in the UI or fetch for specific jobs.

  Future<JobModel?> getJob(String jobId) async {
    final doc = await _firestore.collection('jobs').doc(jobId).get();
    if (doc.exists && doc.data() != null) {
      return JobModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    await _firestore.collection('job_applications').doc(applicationId).update({
      'applicationStatus': status,
    });
  }

  Future<void> saveAiRecommendation(
    String applicationId,
    double score,
    String reason,
  ) async {
    await _firestore.collection('job_applications').doc(applicationId).update({
      'aiMatchScore': score,
      'aiMatchReason': reason,
    });
  }

  Future<void> inviteCandidate({
    required String jobId,
    required String candidateId,
  }) async {
    final applicationId = '${jobId}_$candidateId';
    final docRef = _firestore.collection('job_applications').doc(applicationId);

    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      // Check status to see if re-invitation is possible or if they already applied
      // For now, we simply prevent duplicates if any record exists.
      throw Exception('Candidate has already applied or been invited.');
    }

    final application = JobApplicationModel(
      applicationId: applicationId,
      jobId: jobId,
      candidateId: candidateId,
      resumeUrl: '', // Not available yet
      coverLetter: '', // Not available yet
      applicationStatus: 'invited',
      appliedAt: DateTime.now(),
      source: 'recruiter_invite',
    );

    await docRef.set(application.toMap());
  }

  Future<List<JobApplicationModel>> getApplicationsByCandidates(
    List<String> candidateIds,
  ) async {
    if (candidateIds.isEmpty) return [];

    final List<JobApplicationModel> applications = [];

    // Split into chunks of 10 for whereIn query
    for (var i = 0; i < candidateIds.length; i += 10) {
      final end = (i + 10 < candidateIds.length) ? i + 10 : candidateIds.length;
      final chunk = candidateIds.sublist(i, end);

      final snapshot = await _firestore
          .collection('job_applications')
          .where('candidateId', whereIn: chunk)
          .get();

      applications.addAll(
        snapshot.docs.map(
          (doc) => JobApplicationModel.fromMap(doc.data(), doc.id),
        ),
      );
    }

    return applications;
  }

  Future<void> closeJob(String jobId, String recruiterId) async {
    // 1. Delete all Job Applications for this job
    final applicationsQuery = await _firestore
        .collection('job_applications')
        .where('jobId', isEqualTo: jobId)
        .get();

    for (var doc in applicationsQuery.docs) {
      await doc.reference.delete();
    }

    // 2. Delete all Chats and their Messages for this job
    final chatsQuery = await _firestore
        .collection('chats')
        .where('jobId', isEqualTo: jobId)
        .where('recruiterId', isEqualTo: recruiterId)
        .get();

    for (var chatDoc in chatsQuery.docs) {
      // Delete messages subcollection for each chat
      final messagesQuery = await chatDoc.reference
          .collection('messages')
          .get();
      for (var msgDoc in messagesQuery.docs) {
        await msgDoc.reference.delete();
      }
      // Delete the chat document itself
      await chatDoc.reference.delete();
    }

    // 3. Update Job status to closed
    await _firestore.collection('jobs').doc(jobId).update({
      'status': 'closed',
      'expiresAt': Timestamp.now(), // Set closed date
    });
  }
}
