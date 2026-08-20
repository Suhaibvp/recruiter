import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company_model.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});

class CompanyRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CompanyRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  Future<String> uploadLogo(File file, String companyName) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${companyName.replaceAll(' ', '_')}.jpg';
      final ref = _storage.ref().child('company_logos').child(fileName);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload logo: $e');
    }
  }

  Future<void> createCompanyProfile({
    required CompanyModel company,
    required String recruiterUid,
  }) async {
    try {
      final batch = _firestore.batch();

      // Create Company Document
      final companyRef = _firestore
          .collection('companies')
          .doc(company.id ?? _firestore.collection('companies').doc().id);

      // Update company with the generated ID if it was null
      final finalCompany = company.id == null
          ? company.copyWith(id: companyRef.id)
          : company;

      batch.set(companyRef, finalCompany.toMap());

      // Update Recruiter Document to link company and set companyCreated flag
      final recruiterRef = _firestore
          .collection('recruiters')
          .doc(recruiterUid);
      batch.update(recruiterRef, {
        'companyId': companyRef.id,
        'companyCreated': true,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create company profile: $e');
    }
  }

  Future<void> updateCompanyProfile(CompanyModel company) async {
    try {
      if (company.id == null) throw Exception('Company ID is missing');

      final companyRef = _firestore.collection('companies').doc(company.id);

      // Update updated_at
      final updatedCompany = company.copyWith(
        meta: company.meta.copyWith(updatedAt: DateTime.now()),
      );

      await companyRef.update(updatedCompany.toMap());
    } catch (e) {
      throw Exception('Failed to update company profile: $e');
    }
  }

  Future<CompanyModel?> fetchCompany(String companyId) async {
    try {
      if (companyId.isEmpty) return null;
      final doc = await _firestore.collection('companies').doc(companyId).get();
      if (doc.exists) {
        return CompanyModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch company: $e');
    }
  }
}
