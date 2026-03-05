import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/bookmarks/bookmark_service.dart';
import 'package:nkhani/features/feed/news_model.dart';
import 'package:nkhani/features/feed/story_detail_screen.dart';

class SavedStoriesScreen extends StatelessWidget {
  const SavedStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Stories')),
      body: StreamBuilder<List<News>>(
        stream: BookmarkService().watchBookmarks(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load saved stories: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No saved stories yet.'));
          }

          final stories = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final story = stories[index];
              return _SavedStoryCard(news: story);
            },
          );
        },
      ),
    );
  }
}

class _SavedStoryCard extends StatelessWidget {
  final News news;

  const _SavedStoryCard({required this.news});

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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
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
