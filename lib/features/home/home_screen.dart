import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/auth/user_model.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/features/feed/news_model.dart';
import 'package:nkhani/features/feed/news_service.dart';
import 'package:nkhani/features/feed/story_detail_screen.dart';
import 'package:nkhani/features/notifications/notification_screen.dart';
import 'package:nkhani/features/notifications/notification_service.dart';
import 'package:nkhani/features/organizations/org_story_submit_screen.dart';
import 'package:nkhani/features/reports/report_service.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF8B1D76),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B1D76),
        elevation: 0,
        title: const Text(
          'Nkhani',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          StreamBuilder<int>(
            stream: NotificationService().watchUnreadCount(user?.uid ?? ''),
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;
              return IconButton(
                onPressed: user == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );
                      },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none),
                    if (unread > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Notifications',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: user == null
          ? null
          : StreamBuilder<AppUser?>(
              stream: UserService().watchUser(user.uid),
              builder: (context, snapshot) {
                final appUser = snapshot.data;
                if (appUser == null || !appUser.isOrganizationAdmin) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 90),
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const OrganizationStorySubmitScreen(),
                        ),
                      );
                    },
                    tooltip: 'Open Org Studio',
                    child: const Icon(Icons.post_add),
                  ),
                );
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF0F2F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: user == null
            ? const Center(child: Text('No user logged in'))
            : StreamBuilder<AppUser?>(
                stream: UserService().watchUser(user.uid),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!userSnapshot.hasData || userSnapshot.data == null) {
                    return const Center(child: Text('User profile not found.'));
                  }

                  final appUser = userSnapshot.data!;

                  if (!appUser.hasAccess) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Your free trial has ended. Activate subscription (MWK 500) from Profile to continue reading.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return StreamBuilder<List<News>>(
                    stream: NewsService().getNewsFeed(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No news yet'));
                      }

                      final newsList = snapshot.data!;

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        itemCount: newsList.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _NewsPostCard(
                            news: newsList[index],
                            reporterId: user.uid,
                          );
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _NewsPostCard extends StatefulWidget {
  final News news;
  final String reporterId;

  const _NewsPostCard({
    required this.news,
    required this.reporterId,
  });

  @override
  State<_NewsPostCard> createState() => _NewsPostCardState();
}

class _NewsPostCardState extends State<_NewsPostCard>
    with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  bool _isExpanded = false;
  bool _showHeart = false;

  int _likeCount = 9700;
  int _shareCount = 235;

  late final AnimationController _heartController;
  late final Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) {
      return '${diff.inDays}d';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours}h';
    }
    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m';
    }
    return 'now';
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
      _showHeart = true;
    });

    _heartController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _showHeart = false);
      }
    });
  }

  Future<void> _showReportDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Report Story'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Report'),
            ),
          ],
        );
      },
    );

    final reason =
        (result == null || result.isEmpty) ? 'No reason provided' : result;

    try {
      await ReportService().createReport(
        newsId: widget.news.id,
        reporterId: widget.reporterId,
        reason: reason,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report failed: $e')),
      );
    }
  }

  void _openShareSheet() {
    Share.share(
      '${widget.news.title}\n\n${widget.news.summary ?? ''}',
    );
    setState(() => _shareCount += 1);
  }

  @override
  Widget build(BuildContext context) {
    final news = widget.news;
    final previewText =
        news.summary?.isNotEmpty == true ? news.summary! : news.content;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFF8B1D76),
                  child: Icon(Icons.newspaper, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news.organizationId ?? 'Timveni News',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_timeAgo(news.createdAt)} · 🌍',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'report',
                      child: Text('Report Post'),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'report') {
                      _showReportDialog();
                    }
                  },
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                previewText,
                maxLines: _isExpanded ? null : 3,
                overflow:
                    _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (news.imageUrls.isNotEmpty)
            GestureDetector(
              onDoubleTap: _toggleLike,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoryDetailScreen(news: news),
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    news.imageUrls.first,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(
                      height: 250,
                      child: Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                  if (_showHeart)
                    ScaleTransition(
                      scale: _heartAnimation,
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 90,
                      ),
                    ),
                ],
              ),
            ),
          if (news.imageUrls.isEmpty)
            const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.thumb_up, size: 16, color: Colors.blue),
                const SizedBox(width: 5),
                Text(_formatNumber(_likeCount)),
                const Spacer(),
                Text('${_formatNumber(_shareCount)} shares'),
              ],
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                onPressed: _toggleLike,
                icon: Icon(
                  _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: _isLiked ? Colors.blue : Colors.grey,
                ),
                label: Text(
                  'Like',
                  style: TextStyle(
                    color: _isLiked ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _openShareSheet,
                icon: const Icon(Icons.share_outlined, color: Colors.grey),
                label: const Text(
                  'Share',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
