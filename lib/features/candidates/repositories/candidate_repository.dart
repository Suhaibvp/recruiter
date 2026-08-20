import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/candidate_model.dart';

final candidateRepositoryProvider = Provider<CandidateRepository>((ref) {
  return CandidateRepository(FirebaseFirestore.instance);
});

final candidateDetailsProvider = FutureProvider.family<CandidateModel?, String>(
  (ref, candidateId) {
    final repository = ref.watch(candidateRepositoryProvider);
    return repository.getCandidate(candidateId);
  },
);

class CandidateRepository {
  final FirebaseFirestore _firestore;

  CandidateRepository(this._firestore);

  Future<CandidateModel?> getCandidate(String candidateId) async {
    try {
      // Assuming 'candidates' is the collection name used in the Candidate App
      // Make sure this matches the actual collection name in Firestore
      print('DEBUG: Fetching candidate $candidateId');
      print('DEBUG: Auth UID: ${FirebaseAuth.instance.currentUser?.uid}');
      final doc = await _firestore
          .collection('candidates')
          .doc(candidateId)
          .get();
      if (doc.exists && doc.data() != null) {
        // Ensure UID is set from doc ID if missing in data
        final data = doc.data()!;
        data['uid'] = doc.id;
        return CandidateModel.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error fetching candidate: $e');
      return null;
    }
  }

  // Potential future method for batch fetching if needed
  Future<List<CandidateModel>> getCandidates(List<String> candidateIds) async {
    if (candidateIds.isEmpty) return [];

    // Firestore has a limit of 10-30 items in 'in' queries, so batching might be needed for large lists.
    // For now, simpler approach or individual fetches might suffice for small lists.
    // We'll stick to individual fetches or 'where in' for up to 10.

    List<CandidateModel> candidates = [];

    // Fetching documents individually by ID is more reliable and avoids permission issues with collection queries
    for (var i = 0; i < candidateIds.length; i += 10) {
      var end = (i + 10 < candidateIds.length) ? i + 10 : candidateIds.length;
      var chunk = candidateIds.sublist(i, end);

      try {
        final docSnapshots = await Future.wait(
          chunk.map((id) => _firestore.collection('candidates').doc(id).get()),
        );

        for (final doc in docSnapshots) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            data['uid'] = doc.id;
            candidates.add(CandidateModel.fromMap(data));
          }
        }
      } catch (e) {
        print('Error fetching candidate batch: $e');
      }
    }

    return candidates;
  }

  /// Fetch all candidates with an optional limit
  Future<List<CandidateModel>> getAllCandidates({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('candidates')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return CandidateModel.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error fetching all candidates: $e');
      return [];
    }
  }
}
