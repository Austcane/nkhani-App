import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/auth/user_model.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/features/auth/widgets/app_colors.dart';
import 'package:nkhani/features/feed/news_model.dart';
import 'package:nkhani/features/feed/news_service.dart';
import 'package:nkhani/features/feed/story_detail_screen.dart';
import 'package:nkhani/features/home/news_search_delegate.dart';
import 'package:nkhani/features/notifications/notification_screen.dart';
import 'package:nkhani/features/notifications/notification_service.dart';
import 'package:nkhani/features/organizations/media_profile_screen.dart';
import 'package:nkhani/features/organizations/org_model.dart';
import 'package:nkhani/features/organizations/org_service.dart';
import 'package:nkhani/features/organizations/org_story_submit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _brand = AppColors.primary;
  static const Color _surface = Color(0xFFF5F6FA);

  String _selectedCategory = 'All';
  bool _imagesOnly = false;
  bool _sortNewest = true;

  void _openSearch() {
    showSearch(
      context: context,
      delegate: NewsSearchDelegate(),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }

  void _openOrgStudio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OrganizationStorySubmitScreen(),
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_FeedFilter>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: _FilterSheet(
              selectedCategory: _selectedCategory,
              imagesOnly: _imagesOnly,
              sortNewest: _sortNewest,
            ),
          ),
        );
      },
    );

    if (result == null) return;

    setState(() {
      _selectedCategory = result.category;
      _imagesOnly = result.imagesOnly;
      _sortNewest = result.sortNewest;
    });
  }

  Stream<List<News>> _newsStream() {
    if (_selectedCategory == 'All') {
      return NewsService().getNewsFeed();
    }
    return NewsService().getNewsFeedByCategory(_selectedCategory);
  }

  List<News> _applyLocalFilters(List<News> items) {
    var filtered = items;
    if (_imagesOnly) {
      filtered = filtered.where((item) => item.imageUrls.isNotEmpty).toList();
    }
    filtered.sort((a, b) => _sortNewest
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to continue.')),
      );
    }

    return Scaffold(
      backgroundColor: _surface,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: StreamBuilder<AppUser?>(
        stream: UserService().watchUser(firebaseUser.uid),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
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
                  'Your free trial has ended. Activate subscription from Profile to continue reading.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8B1D76),
                            Color(0xFFB42586),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Nkhani',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                _NotificationBell(
                                  userId: firebaseUser.uid,
                                  onPressed: _openNotifications,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Hello ${appUser.name}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Catch up on the latest stories',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _openSearch,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.search,
                                            color: Colors.grey.shade500,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Search stories',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: _CategoryRow(
                        selectedCategory: _selectedCategory,
                        onCategorySelected: (value) {
                          setState(() => _selectedCategory = value);
                        },
                        onOpenFilter: _openFilterSheet,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: StreamBuilder<List<News>>(
                      stream: _newsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(child: Text('No stories yet.')),
                          );
                        }

                        final filtered = _applyLocalFilters(snapshot.data!);
                        if (filtered.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(child: Text('No stories match this filter.')),
                          );
                        }

                        final heroStory = filtered.reduce((current, candidate) {
                          return candidate.createdAt.isAfter(current.createdAt)
                              ? candidate
                              : current;
                        });
                        final remaining = filtered
                            .where((item) => item.id != heroStory.id)
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _HeroStoryCard(
                                news: heroStory,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StoryDetailScreen(news: heroStory),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Media',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const _MediaStrip(),
                            const SizedBox(height: 18),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Latest',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                final news = remaining[index];
                                return _NewsListCard(
                                  news: news,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StoryDetailScreen(news: news),
                                      ),
                                    );
                                  },
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemCount: remaining.length,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              ),
              if (appUser.isSuperuser || appUser.isOrganizationAdmin)
                Positioned(
                  right: 20,
                  bottom: 110,
                  child: FloatingActionButton(
                    backgroundColor: _brand,
                    onPressed: _openOrgStudio,
                    child: const Icon(Icons.post_add, color: Colors.white),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final String userId;
  final VoidCallback onPressed;

  const _NotificationBell({
    required this.userId,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService().watchUnreadCount(userId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications,
                color: Colors.white,
              ),
              onPressed: onPressed,
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 18),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MediaStrip extends StatelessWidget {
  const _MediaStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: StreamBuilder<List<Organization>>(
        stream: OrganizationService().watchOrganizationsByStatus('approved'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('No media profiles yet.'),
              ),
            );
          }

          final orgs = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: orgs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final org = orgs[index];
              return _MediaCard(organization: org);
            },
          );
        },
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final Organization organization;

  const _MediaCard({required this.organization});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'M';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MediaProfileScreen(organization: organization),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 88,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFF4E8F2),
              child: Text(
                _initials(organization.name),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B1D76),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              organization.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onOpenFilter;

  const _CategoryRow({
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onOpenFilter,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...News.categories, 'More'];

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final isSelected = category == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      if (category == 'More') {
                        onOpenFilter();
                        return;
                      }
                      onCategorySelected(category);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          if (category == 'More')
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.tune, size: 14),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onOpenFilter,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.filter_alt, size: 18),
          ),
        ),
      ],
    );
  }
}

class _HeroStoryCard extends StatelessWidget {
  final News news;
  final VoidCallback onTap;

  const _HeroStoryCard({
    required this.news,
    required this.onTap,
  });

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    final image = news.imageUrls.isNotEmpty ? news.imageUrls.first : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              if (image != null)
                Image.network(
                  image,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                )
              else
                Container(
                  color: Colors.grey.shade300,
                  child: const Center(child: Icon(Icons.image_not_supported)),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        news.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      news.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(news.createdAt),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsListCard extends StatelessWidget {
  final News news;
  final VoidCallback onTap;

  const _NewsListCard({
    required this.news,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = news.imageUrls.isNotEmpty ? news.imageUrls.first : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 84,
                height: 84,
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
            const SizedBox(width: 14),
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
                      fontSize: 14,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        news.category,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      ),
                    ],
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

class _FeedFilter {
  final String category;
  final bool imagesOnly;
  final bool sortNewest;

  const _FeedFilter({
    required this.category,
    required this.imagesOnly,
    required this.sortNewest,
  });
}

class _FilterSheet extends StatefulWidget {
  final String selectedCategory;
  final bool imagesOnly;
  final bool sortNewest;

  const _FilterSheet({
    required this.selectedCategory,
    required this.imagesOnly,
    required this.sortNewest,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _category;
  late bool _imagesOnly;
  late bool _sortNewest;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _imagesOnly = widget.imagesOnly;
    _sortNewest = widget.sortNewest;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Filter stories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Category'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'All',
            ...News.categories,
          ].map((category) {
            final isSelected = category == _category;
            return ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => setState(() => _category = category),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _imagesOnly,
          onChanged: (value) => setState(() => _imagesOnly = value),
          title: const Text('Images only'),
        ),
        SwitchListTile(
          value: _sortNewest,
          onChanged: (value) => setState(() => _sortNewest = value),
          title: const Text('Newest first'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                _FeedFilter(
                  category: _category,
                  imagesOnly: _imagesOnly,
                  sortNewest: _sortNewest,
                ),
              );
            },
            child: const Text('Apply filters'),
          ),
        ),
      ],
    );
  }
}
