import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/audit/audit_model.dart';
import 'package:nkhani/features/audit/audit_service.dart';
import 'package:nkhani/features/admin/schema_health_screen.dart';
import 'package:nkhani/features/auth/user_model.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/features/drafts/draft_comment_service.dart';
import 'package:nkhani/features/feed/news_model.dart';
import 'package:nkhani/features/feed/news_service.dart';
import 'package:nkhani/features/notifications/notification_service.dart';
import 'package:nkhani/features/organizations/org_model.dart';
import 'package:nkhani/features/organizations/org_service.dart';
import 'package:nkhani/features/reports/report_model.dart';
import 'package:nkhani/features/reports/report_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _newsService = NewsService();
  final _reportService = ReportService();
  final _userService = UserService();
  final _orgService = OrganizationService();
  final _auditService = AuditService();
  final _draftCommentService = DraftCommentService();
  final _notificationService = NotificationService();
  bool _isSubmitting = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _submitNews() async {
    final user = _currentUser;
    if (user == null) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and content.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _newsService.createNews(
        title: title,
        content: content,
        authorId: user.uid,
      );

      _titleController.clear();
      _contentController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story created as draft.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create story: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _togglePublished(News news, bool value) async {
    try {
      await _newsService.setPublished(newsId: news.id, published: value);
      await _auditService.logAction(
        action: value ? 'publish_story' : 'unpublish_story',
        actorId: _currentUser?.uid ?? '',
        targetType: 'news',
        targetId: news.id,
        metadata: {
          'title': news.title,
          'authorId': news.authorId,
          'organizationId': news.organizationId,
        },
      );
      await _notificationService.createNotification(
        userId: news.authorId,
        title: value ? 'Story published' : 'Story unpublished',
        body: 'Your story "${news.title}" was ${value ? "published" : "unpublished"}.',
        type: value ? 'publish' : 'unpublish',
        metadata: {'newsId': news.id},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _resolveReport(Report report) async {
    try {
      await _reportService.resolveReport(report.id);
      await _auditService.logAction(
        action: 'resolve_report',
        actorId: _currentUser?.uid ?? '',
        targetType: 'report',
        targetId: report.id,
        metadata: {
          'newsId': report.newsId,
          'reporterId': report.reporterId,
        },
      );
      await _notificationService.createNotification(
        userId: report.reporterId,
        title: 'Report resolved',
        body: 'Your report on story ${report.newsId} was resolved.',
        type: 'report_resolved',
        metadata: {'reportId': report.id, 'newsId': report.newsId},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resolve failed: $e')),
      );
    }
  }

  Future<void> _unpublishStory(String newsId) async {
    try {
      await _newsService.setPublished(newsId: newsId, published: false);
      await _auditService.logAction(
        action: 'unpublish_story',
        actorId: _currentUser?.uid ?? '',
        targetType: 'news',
        targetId: newsId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unpublish failed: $e')),
      );
    }
  }

  Future<void> _updateUserRole(AppUser user, String role) async {
    try {
      await _userService.updateUserRole(uid: user.uid, role: role);
      await _auditService.logAction(
        action: 'update_user_role',
        actorId: _currentUser?.uid ?? '',
        targetType: 'user',
        targetId: user.uid,
        metadata: {
          'newRole': role,
          'email': user.email,
        },
      );
      await _notificationService.createNotification(
        userId: user.uid,
        title: 'Role updated',
        body: 'Your account role was updated to $role.',
        type: 'role_update',
        metadata: {'role': role},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role update failed: $e')),
      );
    }
  }

  Future<void> _approveOrganization(Organization organization, String reviewerId) async {
    try {
      await _orgService.approveOrganization(
        organization: organization,
        reviewerId: reviewerId,
      );
      await _auditService.logAction(
        action: 'approve_org',
        actorId: reviewerId,
        targetType: 'organization',
        targetId: organization.id,
        metadata: {
          'name': organization.name,
          'createdBy': organization.createdBy,
        },
      );
      await _notificationService.createNotification(
        userId: organization.createdBy,
        title: 'Organization approved',
        body: 'Your organization "${organization.name}" was approved.',
        type: 'org_approved',
        metadata: {'organizationId': organization.id},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approval failed: $e')),
      );
    }
  }

  Future<void> _rejectOrganization(Organization organization, String reviewerId) async {
    try {
      await _orgService.rejectOrganization(
        organization: organization,
        reviewerId: reviewerId,
      );
      await _auditService.logAction(
        action: 'reject_org',
        actorId: reviewerId,
        targetType: 'organization',
        targetId: organization.id,
        metadata: {
          'name': organization.name,
          'createdBy': organization.createdBy,
        },
      );
      await _notificationService.createNotification(
        userId: organization.createdBy,
        title: 'Organization rejected',
        body: 'Your organization "${organization.name}" was rejected.',
        type: 'org_rejected',
        metadata: {'organizationId': organization.id},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rejection failed: $e')),
      );
    }
  }

  Future<void> _addDraftComment(News draft) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Comment'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Comment',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    final message = result ?? '';
    if (message.isEmpty) return;

    try {
      await _draftCommentService.addComment(
        newsId: draft.id,
        newsAuthorId: draft.authorId,
        organizationId: draft.organizationId,
        authorId: _currentUser?.uid ?? '',
        message: message,
      );
      await _auditService.logAction(
        action: 'comment_draft',
        actorId: _currentUser?.uid ?? '',
        targetType: 'news',
        targetId: draft.id,
        metadata: {'message': message},
      );
      await _notificationService.createNotification(
        userId: draft.authorId,
        title: 'Draft comment',
        body: 'Admin commented on your draft "${draft.title}".',
        type: 'draft_comment',
        metadata: {'newsId': draft.id},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No superuser logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Story',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitNews,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Draft'),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: DefaultTabController(
                length: 7,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Stories'),
                        Tab(text: 'Review'),
                        Tab(text: 'Reports'),
                        Tab(text: 'Users'),
                        Tab(text: 'Orgs'),
                        Tab(text: 'Audit'),
                        Tab(text: 'Health'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        children: [
                          StreamBuilder<List<News>>(
                            stream: _newsService.getAdminNewsFeed(user.uid),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Failed to load stories: ${snapshot.error}',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text('No stories yet.'),
                                );
                              }

                              final stories = snapshot.data!;

                              return ListView.builder(
                                itemCount: stories.length,
                                itemBuilder: (context, index) {
                                  final story = stories[index];
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: ListTile(
                                      title: Text(story.title),
                                      subtitle: Text(
                                        story.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Switch(
                                        value: story.published,
                                        onChanged: (value) =>
                                            _togglePublished(story, value),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          StreamBuilder<List<News>>(
                            stream: _newsService.getDrafts(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Failed to load drafts: ${snapshot.error}',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text('No drafts awaiting review.'),
                                );
                              }

                              final drafts = snapshot.data!;

                              return ListView.builder(
                                itemCount: drafts.length,
                                itemBuilder: (context, index) {
                                  final draft = drafts[index];
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: ListTile(
                                      leading: draft.imageUrls.isEmpty
                                          ? const Icon(Icons.image_not_supported)
                                          : Image.network(
                                              draft.imageUrls.first,
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Icon(Icons.broken_image),
                                            ),
                                      title: Text(draft.title),
                                      subtitle: Text(
                                        draft.summary?.isNotEmpty == true
                                            ? draft.summary!
                                            : draft.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Wrap(
                                        spacing: 8,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.comment),
                                            tooltip: 'Comment',
                                            onPressed: () =>
                                                _addDraftComment(draft),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.check),
                                            tooltip: 'Publish',
                                            onPressed: () => _togglePublished(
                                              draft,
                                              true,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            tooltip: 'Delete',
                                            onPressed: () async {
                                              await _newsService.deleteNews(
                                                draft.id,
                                              );
                                              await _auditService.logAction(
                                                action: 'delete_draft',
                                                actorId:
                                                    _currentUser?.uid ?? '',
                                                targetType: 'news',
                                                targetId: draft.id,
                                                metadata: {
                                                  'title': draft.title,
                                                  'authorId': draft.authorId,
                                                  'organizationId':
                                                      draft.organizationId,
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          StreamBuilder<List<Report>>(
                            stream: _reportService.watchOpenReports(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Failed to load reports: ${snapshot.error}',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text('No open reports.'),
                                );
                              }

                              final reports = snapshot.data!;

                              return ListView.builder(
                                itemCount: reports.length,
                                itemBuilder: (context, index) {
                                  final report = reports[index];
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: ListTile(
                                      title: Text('Story: ${report.newsId}'),
                                      subtitle: Text(
                                        report.reason,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Wrap(
                                        spacing: 8,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.block),
                                            tooltip: 'Unpublish story',
                                            onPressed: () =>
                                                _unpublishStory(report.newsId),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.check),
                                            tooltip: 'Resolve report',
                                            onPressed: () => _resolveReport(report),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          StreamBuilder<List<AppUser>>(
                            stream: _userService.watchAllUsers(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text('No users found.'),
                                );
                              }

                              final users = snapshot.data!;

                              return ListView.builder(
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final appUser = users[index];
                                  final isSelf = appUser.uid == user.uid;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: ListTile(
                                      title: Text(appUser.name.isNotEmpty
                                          ? appUser.name
                                          : appUser.email),
                                      subtitle: Text(
                                        '${appUser.email} • ${appUser.role}',
                                      ),
                                      trailing: isSelf
                                          ? const Text('You')
                                          : PopupMenuButton<String>(
                                              onSelected: (role) =>
                                                  _updateUserRole(
                                                appUser,
                                                role,
                                              ),
                                              itemBuilder: (context) => const [
                                                PopupMenuItem(
                                                  value: 'user',
                                                  child: Text('Set user'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'org_admin',
                                                  child: Text('Set org admin'),
                                                ),
                                              ],
                                            ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          StreamBuilder<List<Organization>>(
                            stream: _orgService.watchOrganizationsByStatus('pending'),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Failed to load organizations: ${snapshot.error}',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text('No pending organizations.'),
                                );
                              }

                              final orgs = snapshot.data!;

                              return ListView.builder(
                                itemCount: orgs.length,
                                itemBuilder: (context, index) {
                                  final org = orgs[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    child: ListTile(
                                      title: Text(org.name),
                                      subtitle: Text(
                                        '${org.contactEmail} • ${org.createdBy}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Wrap(
                                        spacing: 8,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check),
                                            tooltip: 'Approve',
                                            onPressed: () => _approveOrganization(
                                              org,
                                              user.uid,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            tooltip: 'Reject',
                                            onPressed: () => _rejectOrganization(
                                              org,
                                              user.uid,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          StreamBuilder<List<AuditLog>>(
                            stream: _auditService.watchLogs(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Failed to load audit logs: ${snapshot.error}',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text('No audit logs yet.'),
                                );
                              }

                              final logs = snapshot.data!;

                              return ListView.builder(
                                itemCount: logs.length,
                                itemBuilder: (context, index) {
                                  final log = logs[index];
                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: ListTile(
                                      title: Text(log.action),
                                      subtitle: Text(
                                        '${log.targetType}: ${log.targetId}',
                                      ),
                                      trailing: Text(
                                        log.actorId,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SchemaHealthScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.health_and_safety),
                              label: const Text('Run Schema Health Scan'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
