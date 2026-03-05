import 'package:flutter/material.dart';
import 'package:nkhani/features/feed/news_model.dart';
import 'package:nkhani/features/feed/news_service.dart';
import 'package:nkhani/features/feed/story_detail_screen.dart';
import 'package:nkhani/features/organizations/org_model.dart';

class MediaProfileScreen extends StatelessWidget {
  final Organization organization;

  const MediaProfileScreen({super.key, required this.organization});

  String _handleFromName(String name) {
    final lower = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return lower.isEmpty ? 'media' : lower;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'M';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(organization.name),
      ),
      body: StreamBuilder<List<News>>(
        stream: NewsService().getPublishedNewsByOrganization(organization.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final stories = snapshot.data ?? [];
          final newsCount = stories.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(
                      _initials(organization.name),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B1D76),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          organization.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${_handleFromName(organization.name)}',
                          style: const TextStyle(color: Colors.black54),
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
              const SizedBox(height: 12),
              Text(
                organization.description.isNotEmpty
                    ? organization.description
                    : 'Official media profile.',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(label: 'News', value: '$newsCount'),
                    _StatItem(label: 'Followers', value: '0'),
                    _StatItem(label: 'Following', value: '0'),
                    _StatItem(label: 'Upvoted', value: '0'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _CategoryChip(
                    label: 'News',
                    selected: true,
                    onTap: () {},
                  ),
                  const SizedBox(width: 10),
                  _CategoryChip(
                    label: 'Updates',
                    selected: false,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (stories.isEmpty)
                const Center(child: Text('No stories yet.'))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final news = stories[index];
                    return _StoryCard(news: news);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8B1D76) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF8B1D76) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final News news;

  const _StoryCard({required this.news});

  @override
  Widget build(BuildContext context) {
    final image = news.imageUrls.isNotEmpty ? news.imageUrls.first : null;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StoryDetailScreen(news: news),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 70,
                height: 70,
                child: image == null
                    ? Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported),
                      )
                    : Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    news.summary?.isNotEmpty == true
                        ? news.summary!
                        : news.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
