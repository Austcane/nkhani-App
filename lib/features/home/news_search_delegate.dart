import 'package:flutter/material.dart';
import 'package:nkhani/features/feed/news_model.dart';
import 'package:nkhani/features/feed/news_service.dart';
import 'package:nkhani/features/feed/story_detail_screen.dart';

class NewsSearchDelegate extends SearchDelegate<News?> {
  NewsSearchDelegate();

  @override
  String get searchFieldLabel => 'Search news';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultsList(query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResultsList(query);
  }

  Widget _buildResultsList(String rawQuery) {
    final normalized = rawQuery.trim().toLowerCase();

    return StreamBuilder<List<News>>(
      stream: normalized.isEmpty
          ? const Stream<List<News>>.empty()
          : NewsService().searchPublishedNewsByTitle(normalized),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (normalized.isEmpty) {
          return const Center(child: Text('Type to search news.'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No matches found.'));
        }

        final newsItems = snapshot.data!;

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: newsItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final news = newsItems[index];
            return Card(
              elevation: 1,
              child: ListTile(
                leading: news.imageUrls.isEmpty
                    ? const Icon(Icons.image_not_supported)
                    : Image.network(
                        news.imageUrls.first,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                      ),
                title: Text(
                  news.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  news.summary?.isNotEmpty == true
                      ? news.summary!
                      : news.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoryDetailScreen(news: news),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
