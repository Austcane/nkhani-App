import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/bookmarks/bookmark_service.dart';
import 'package:nkhani/features/reports/report_service.dart';
import 'package:share_plus/share_plus.dart';
import 'news_model.dart';

class StoryDetailScreen extends StatefulWidget {
  final News news;

  const StoryDetailScreen({super.key, required this.news});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  static const Color _brand = Color(0xFF8B1D76);

  final PageController _pageController = PageController();
  final BookmarkService _bookmarkService = BookmarkService();
  final ReportService _reportService = ReportService();
  int _currentIndex = 0;
  bool _liked = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) {
      return '${diff.inDays}d ago';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours}h ago';
    }
    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m ago';
    }
    return 'just now';
  }

  String _readTime(String content) {
    final words = content.trim().split(RegExp(r'\s+')).length;
    final minutes = (words / 200).ceil();
    return '${minutes.clamp(1, 20)} min read';
  }

  Future<void> _toggleBookmark({
    required String uid,
    required News news,
    required bool isBookmarked,
  }) async {
    try {
      if (isBookmarked) {
        await _bookmarkService.removeBookmark(uid: uid, newsId: news.id);
      } else {
        await _bookmarkService.addBookmark(uid: uid, news: news);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bookmark failed: $e')),
      );
    }
  }

  Future<void> _shareStory(News news) async {
    final text = [
      news.title,
      if (news.summary?.isNotEmpty == true) news.summary!,
      'Category: ${news.category}',
    ].join('\n');

    await Share.share(text);
  }

  Future<void> _showReportDialog({
    required News news,
    required String reporterId,
  }) async {
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
      await _reportService.createReport(
        newsId: news.id,
        reporterId: reporterId,
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

  @override
  Widget build(BuildContext context) {
    final news = widget.news;
    final images = news.imageUrls;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 320,
                      child: images.isNotEmpty
                          ? PageView.builder(
                              controller: _pageController,
                              itemCount: images.length,
                              onPageChanged: (index) {
                                setState(() => _currentIndex = index);
                              },
                              itemBuilder: (context, index) {
                                final url = images[index];
                                return Image.network(
                                  url,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(Icons.image_not_supported),
                              ),
                            ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              color: Colors.white,
                              onPressed: () => Navigator.pop(context),
                            ),
                            Row(
                              children: [
                                if (userId == null)
                                  IconButton(
                                    icon: const Icon(Icons.bookmark_border),
                                    color: Colors.white,
                                    onPressed: null,
                                  )
                                else
                                  StreamBuilder<bool>(
                                    stream:
                                        _bookmarkService.watchBookmarkStatus(
                                      userId,
                                      news.id,
                                    ),
                                    builder: (context, snapshot) {
                                      final isBookmarked =
                                          snapshot.data ?? false;
                                      return IconButton(
                                        icon: Icon(
                                          isBookmarked
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                        ),
                                        color: Colors.white,
                                        onPressed: () => _toggleBookmark(
                                          uid: userId,
                                          news: news,
                                          isBookmarked: isBookmarked,
                                        ),
                                      );
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  color: Colors.white,
                                  onPressed: () => _shareStory(news),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                  ),
                                  onSelected: (value) {
                                    if (value != 'report') return;
                                    if (userId == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Please login to report.'),
                                        ),
                                      );
                                      return;
                                    }
                                    _showReportDialog(
                                      news: news,
                                      reporterId: userId,
                                    );
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'report',
                                      child: Text('Report post'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              _MetaChip(label: news.category),
                              _MetaChip(label: _readTime(news.content)),
                              _MetaChip(label: _timeAgo(news.createdAt)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            news.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _MetricPill(icon: Icons.thumb_up, label: '2.5k'),
                              const SizedBox(width: 8),
                              _MetricPill(icon: Icons.chat_bubble, label: '540'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (index) {
                            final isActive = index == _currentIndex;
                            return Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              width: isActive ? 8 : 6,
                              height: isActive ? 8 : 6,
                              decoration: BoxDecoration(
                                color:
                                    isActive ? Colors.white : Colors.white70,
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _brand,
                    child: const Icon(Icons.newspaper, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          news.organizationId ?? 'Timveni News',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Verified source',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE84E4E),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {},
                    child: const Text('Follow'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (news.summary?.isNotEmpty == true)
                    Text(
                      news.summary!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  if (news.summary?.isNotEmpty == true)
                    const SizedBox(height: 16),
                  Text(
                    news.content,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _liked ? _brand : Colors.white,
        foregroundColor: _liked ? Colors.white : _brand,
        onPressed: () {
          setState(() => _liked = !_liked);
        },
        child: Icon(_liked ? Icons.favorite : Icons.favorite_border),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
