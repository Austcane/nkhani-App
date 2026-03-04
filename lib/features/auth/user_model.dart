import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final bool subscriptionActive;
  final DateTime? trialEndsAt;
  final String? photoUrl;
  final String? organizationId;
  final String? organizationRole;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.subscriptionActive,
    required this.trialEndsAt,
    this.photoUrl,
    this.organizationId,
    this.organizationRole,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    final rawTrialEndsAt = data['trialEndsAt'];

    DateTime? trialEndsAt;
    if (rawTrialEndsAt is Timestamp) {
      trialEndsAt = rawTrialEndsAt.toDate();
    } else if (rawTrialEndsAt is DateTime) {
      trialEndsAt = rawTrialEndsAt;
    }

    return AppUser(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      subscriptionActive: data['subscriptionActive'] ?? false,
      trialEndsAt: trialEndsAt,
      photoUrl: data['photoUrl'],
      organizationId: data['organizationId'],
      organizationRole: data['organizationRole'],
    );
  }

  bool get isSuperuser => role == 'superuser';

  bool get isOrganizationAdmin => organizationRole == 'org_admin';

  bool get isValidProfile {
    if (name.trim().isEmpty) return false;
    if (email.trim().isEmpty) return false;
    if (role.trim().isEmpty) return false;
    return true;
  }

  bool get isTrialActive {
    if (trialEndsAt == null) return false;
    return trialEndsAt!.isAfter(DateTime.now());
  }

  bool get hasAccess => subscriptionActive || isTrialActive;

  int get trialDaysLeft {
    if (!isTrialActive || trialEndsAt == null) return 0;
    final diff = trialEndsAt!.difference(DateTime.now());
    final days = diff.inDays;
    final hasPartialDay = diff.inHours % 24 != 0;
    return hasPartialDay ? days + 1 : days;
  }
}
