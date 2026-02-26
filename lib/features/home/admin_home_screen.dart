import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/auth/user_model.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/features/feed/news_model.dart';
import 'package:nkhani/features/feed/news_service.dart';
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rejection failed: $e')),
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
        body: Center(child: Text('No admin user logged in.')),
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
                length: 4,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Stories'),
                        Tab(text: 'Reports'),
                        Tab(text: 'Users'),
                        Tab(text: 'Orgs'),
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
                                                  value: 'admin',
                                                  child: Text('Set admin'),
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
