import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/auth/user_model.dart';
import 'package:nkhani/features/feed/news_model.dart';
import 'package:nkhani/features/organizations/org_model.dart';

class SchemaHealthScreen extends StatelessWidget {
  const SchemaHealthScreen({super.key});

  Future<_SchemaHealthReport> _scan() async {
    final firestore = FirebaseFirestore.instance;

    final usersSnapshot = await firestore.collection('users').get();
    final orgsSnapshot = await firestore.collection('organizations').get();
    final newsSnapshot = await firestore.collection('news').get();
    final reportsSnapshot = await firestore.collection('reports').get();
    final auditSnapshot = await firestore.collection('audit_logs').get();
    final notificationsSnapshot =
        await firestore.collection('notifications').get();

    final invalidUsers = <String>[];
    for (final doc in usersSnapshot.docs) {
      final user = AppUser.fromMap(doc.data(), doc.id);
      if (!user.isValidProfile) {
        invalidUsers.add(doc.id);
      }
    }

    final invalidOrgs = <String>[];
    for (final doc in orgsSnapshot.docs) {
      final org = Organization.fromMap(doc.data(), doc.id);
      if (org.name.trim().isEmpty ||
          org.contactEmail.trim().isEmpty ||
          org.createdBy.trim().isEmpty ||
          org.status.trim().isEmpty) {
        invalidOrgs.add(doc.id);
      }
    }

    final invalidNews = <String>[];
    for (final doc in newsSnapshot.docs) {
      final news = News.fromMap(doc.data(), doc.id);
      if (!news.isValidDraft) {
        invalidNews.add(doc.id);
      }
    }

    return _SchemaHealthReport(
      invalidUsers: invalidUsers,
      invalidOrganizations: invalidOrgs,
      invalidNews: invalidNews,
      totalUsers: usersSnapshot.docs.length,
      totalOrganizations: orgsSnapshot.docs.length,
      totalNews: newsSnapshot.docs.length,
      totalReports: reportsSnapshot.docs.length,
      totalAuditLogs: auditSnapshot.docs.length,
      totalNotifications: notificationsSnapshot.docs.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schema Health')),
      body: FutureBuilder<_SchemaHealthReport>(
        future: _scan(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Scan failed: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final report = snapshot.data;
          if (report == null) {
            return const Center(child: Text('No report data.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatTile(label: 'Users', value: report.totalUsers),
              _StatTile(label: 'Organizations', value: report.totalOrganizations),
              _StatTile(label: 'News', value: report.totalNews),
              _StatTile(label: 'Reports', value: report.totalReports),
              _StatTile(label: 'Audit logs', value: report.totalAuditLogs),
              _StatTile(label: 'Notifications', value: report.totalNotifications),
              const SizedBox(height: 16),
              _IssueTile(
                label: 'Invalid users',
                items: report.invalidUsers,
              ),
              _IssueTile(
                label: 'Invalid organizations',
                items: report.invalidOrganizations,
              ),
              _IssueTile(
                label: 'Invalid news',
                items: report.invalidNews,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SchemaHealthReport {
  final List<String> invalidUsers;
  final List<String> invalidOrganizations;
  final List<String> invalidNews;
  final int totalUsers;
  final int totalOrganizations;
  final int totalNews;
  final int totalReports;
  final int totalAuditLogs;
  final int totalNotifications;

  _SchemaHealthReport({
    required this.invalidUsers,
    required this.invalidOrganizations,
    required this.invalidNews,
    required this.totalUsers,
    required this.totalOrganizations,
    required this.totalNews,
    required this.totalReports,
    required this.totalAuditLogs,
    required this.totalNotifications,
  });
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;

  const _StatTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(label),
        trailing: Text(value.toString()),
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  final String label;
  final List<String> items;

  const _IssueTile({
    required this.label,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(label),
        subtitle: Text(items.isEmpty ? 'None' : items.join(', ')),
      ),
    );
  }
}
