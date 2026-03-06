import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/admin/schema_health_screen.dart';
import 'package:nkhani/features/auth/user_model.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/features/auth/widgets/app_colors.dart';
import 'package:nkhani/features/audit/audit_model.dart';
import 'package:nkhani/features/audit/audit_service.dart';
import 'package:nkhani/features/feed/news_model.dart';
import 'package:nkhani/features/feed/news_service.dart';
import 'package:nkhani/features/feed/story_detail_screen.dart';
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
  static const Color _brand = AppColors.primary;
  static const Color _surface = Color(0xFFF5F6FA);

  final NewsService _newsService = NewsService();
  final OrganizationService _organizationService = OrganizationService();
  final ReportService _reportService = ReportService();
  final UserService _userService = UserService();
  final AuditService _auditService = AuditService();

  final List<String> _tabs = [
    'Stories',
    'Review',
    'Reports',
    'Users',
    'Orgs',
    'Audit',
    'Health',
  ];

  int _selectedTab = 0;

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Stream<int> _draftCount() {
    return _newsService.getDrafts().map((items) => items.length);
  }

  Stream<int> _pendingOrgCount() {
    return _organizationService
        .watchOrganizationsByStatus('pending')
        .map((items) => items.length);
  }

  Stream<int> _openReportsCount() {
    return _reportService.watchOpenReports().map((items) => items.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTabs(),
          const SizedBox(height: 16),
          _buildTabContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B1D76), Color(0xFFB42586)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Superuser controls',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Review drafts, approve media, and resolve reports.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  label: 'Drafts',
                  stream: _draftCount(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatPill(
                  label: 'Org requests',
                  stream: _pendingOrgCount(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatPill(
                  label: 'Reports',
                  stream: _openReportsCount(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final label = _tabs[index];
          final isSelected = _selectedTab == index;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _brand : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _brand : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildStories();
      case 1:
        return _buildReview();
      case 2:
        return _buildReports();
      case 3:
        return _buildUsers();
      case 4:
        return _buildOrganizations();
      case 5:
        return _buildAuditLogs();
      case 6:
        return _buildHealth();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStories() {
    return _buildSectionCard(
      child: StreamBuilder<List<News>>(
        stream: _newsService.getNewsFeed(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load stories: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No published stories yet.'));
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final news = items[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          news.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${news.category} • ${_formatDate(news.createdAt)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StoryDetailScreen(news: news),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility_off),
                        onPressed: () async {
                          try {
                            await _newsService.setPublished(
                              newsId: news.id,
                              published: false,
                            );
                            _showMessage('Story unpublished.');
                          } catch (e) {
                            _showMessage('Failed: $e');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReview() {
    return _buildSectionCard(
      child: StreamBuilder<List<News>>(
        stream: _newsService.getDrafts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load drafts: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No drafts waiting for review.'));
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final draft = items[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    draft.summary?.isNotEmpty == true
                        ? draft.summary!
                        : draft.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () async {
                          try {
                            await _newsService.setPublished(
                              newsId: draft.id,
                              published: true,
                              title: draft.title,
                              category: draft.category,
                            );
                            _showMessage('Draft published.');
                          } catch (e) {
                            _showMessage('Failed: $e');
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _brand,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Publish'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () async {
                          try {
                            await _newsService.deleteNews(draft.id);
                            _showMessage('Draft deleted.');
                          } catch (e) {
                            _showMessage('Failed: $e');
                          }
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReports() {
    return _buildSectionCard(
      child: StreamBuilder<List<Report>>(
        stream: _reportService.watchOpenReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load reports: ${snapshot.error}'));
          }
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return const Center(child: Text('No open reports.'));
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final report = reports[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.reason,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'News: ${report.newsId}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    'Reporter: ${report.reporterId}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        _formatDate(report.createdAt),
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          try {
                            await _reportService.resolveReport(report.id);
                            _showMessage('Report resolved.');
                          } catch (e) {
                            _showMessage('Failed: $e');
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _brand,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Resolve'),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUsers() {
    return _buildSectionCard(
      child: StreamBuilder<List<AppUser>>(
        stream: _userService.watchAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load users: ${snapshot.error}'));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final user = users[index];
              return Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFF4E8F2),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: _brand,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        if (user.organizationRole != null &&
                            user.organizationId != null)
                          Text(
                            '${user.organizationRole} • ${user.organizationId}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      try {
                        await _userService.updateUserRole(
                          uid: user.uid,
                          role: value,
                        );
                        _showMessage('Role updated.');
                      } catch (e) {
                        _showMessage('Failed: $e');
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'user',
                        child: Text('Set as user'),
                      ),
                      PopupMenuItem(
                        value: 'superuser',
                        child: Text('Set as superuser'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.role,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOrganizations() {
    final reviewerId = FirebaseAuth.instance.currentUser?.uid;

    return _buildSectionCard(
      child: StreamBuilder<List<Organization>>(
        stream: _organizationService.watchOrganizationsByStatus('pending'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load org requests: ${snapshot.error}'),
            );
          }
          final orgs = snapshot.data ?? [];
          if (orgs.isEmpty) {
            return const Center(child: Text('No pending organization requests.'));
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orgs.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final org = orgs[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    org.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    org.contactEmail,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    org.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: reviewerId == null
                            ? null
                            : () async {
                                try {
                                  await _organizationService.approveOrganization(
                                    organization: org,
                                    reviewerId: reviewerId,
                                  );
                                  _showMessage('Organization approved.');
                                } catch (e) {
                                  _showMessage('Failed: $e');
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: _brand,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: reviewerId == null
                            ? null
                            : () async {
                                try {
                                  await _organizationService.rejectOrganization(
                                    organization: org,
                                    reviewerId: reviewerId,
                                  );
                                  _showMessage('Organization rejected.');
                                } catch (e) {
                                  _showMessage('Failed: $e');
                                }
                              },
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAuditLogs() {
    return _buildSectionCard(
      child: StreamBuilder<List<AuditLog>>(
        stream: _auditService.watchLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load logs: ${snapshot.error}'));
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(child: Text('No audit logs yet.'));
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.action,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Actor: ${log.actorId}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    'Target: ${log.targetType} • ${log.targetId}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(log.createdAt),
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHealth() {
    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schema health',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Run a quick scan for invalid documents across key collections.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SchemaHealthScreen(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open schema health'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Stream<int> stream;

  const _StatPill({
    required this.label,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: StreamBuilder<int>(
        stream: stream,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}
