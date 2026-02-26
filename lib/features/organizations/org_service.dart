import 'package:cloud_firestore/cloud_firestore.dart';
import 'org_model.dart';

class OrganizationService {
  final CollectionReference _orgsRef =
      FirebaseFirestore.instance.collection('organizations');
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');

  Stream<List<Organization>> watchMyOrganizations(String uid) {
    return _orgsRef
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) =>
              Organization.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<Organization>> watchOrganizationsByStatus(String status) {
    return _orgsRef
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) =>
              Organization.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> createOrganization({
    required String name,
    required String contactEmail,
    required String description,
    required String createdBy,
  }) async {
    await _orgsRef.add({
      'name': name,
      'contactEmail': contactEmail,
      'description': description,
      'status': 'pending',
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approveOrganization({
    required Organization organization,
    required String reviewerId,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final orgRef = _orgsRef.doc(organization.id);
    final userRef = _usersRef.doc(organization.createdBy);

    batch.update(orgRef, {
      'status': 'approved',
      'reviewedBy': reviewerId,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    batch.update(userRef, {
      'organizationId': organization.id,
      'organizationRole': 'org_admin',
    });

    await batch.commit();
  }

  Future<void> rejectOrganization({
    required Organization organization,
    required String reviewerId,
  }) async {
    await _orgsRef.doc(organization.id).update({
      'status': 'rejected',
      'reviewedBy': reviewerId,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }
}
