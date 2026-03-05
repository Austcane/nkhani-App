import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nkhani/features/auth/user_model.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/features/drafts/draft_comment_model.dart';
import 'package:nkhani/features/drafts/draft_comment_service.dart';
import 'package:nkhani/features/feed/news_model.dart';
import 'package:nkhani/features/feed/news_service.dart';

class OrganizationStorySubmitScreen extends StatefulWidget {
  const OrganizationStorySubmitScreen({super.key});

  @override
  State<OrganizationStorySubmitScreen> createState() =>
      _OrganizationStorySubmitScreenState();
}

class _OrganizationStorySubmitScreenState
    extends State<OrganizationStorySubmitScreen> {
  static const Color _primaryColor = Color(0xFF8B1D76);

  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final _newsService = NewsService();
  final _commentService = DraftCommentService();
  final _imagePicker = ImagePicker();
  final PageController _imagePageController = PageController();
  bool _isSubmitting = false;
  String _selectedCategory = News.categories.first;
  final List<File> _selectedImages = [];
  double _uploadProgress = 0;
  UploadTask? _currentUploadTask;
  bool _cancelRequested = false;
  int _currentImageIndex = 0;

  static const int _maxImages = 5;
  static const int _maxImageBytes = 5 * 1024 * 1024;
  static const List<String> _allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
  ];

  Future<void> _showComments(News draft) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comments for "${draft.title}"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: StreamBuilder<List<DraftComment>>(
                    stream: _commentService.watchComments(draft.id),
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
                            'Failed to load comments: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No comments yet.'));
                      }

                      final comments = snapshot.data!;

                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return ListTile(
                            title: Text(comment.message),
                            subtitle: Text(comment.authorId),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _primaryColor),
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: _primaryColor,
            ),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: _primaryColor,
          width: 2,
        ),
      ),
    );
  }

  Future<void> _submit(AppUser appUser) async {
    final title = _titleController.text.trim();
    final summary = _summaryController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content are required.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0;
      _cancelRequested = false;
    });

    try {
      final imageUrls = await _uploadSelectedImages(appUser.uid);
      if (_cancelRequested) {
        throw Exception('Upload cancelled');
      }
      await _newsService.createNews(
        title: title,
        summary: summary.isEmpty ? null : summary,
        content: content,
        imageUrls: imageUrls,
        authorId: appUser.uid,
        organizationId: appUser.organizationId,
        category: _selectedCategory,
      );

      _titleController.clear();
      _summaryController.clear();
      _contentController.clear();
      setState(() => _selectedImages.clear());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story submitted as draft.')),
      );
    } catch (e) {
      if (!mounted) return;
      if (_cancelRequested) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload cancelled.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        // ignore: prefer_const_constructors
        SnackBar(content: Text('Maximum $_maxImages images allowed.')),
      );
      return;
    }
    final picked = await _imagePicker.pickMultiImage(
      imageQuality: 100,
      maxWidth: 2200,
    );
    if (picked.isEmpty) return;
    for (final file in picked) {
      if (_selectedImages.length >= _maxImages) break;
      final extension = _extensionFromName(file.name);
      final hasAllowedExtension = _allowedExtensions.contains(extension);
      if (!hasAllowedExtension) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only JPG and PNG images are allowed.')),
        );
        continue;
      }
      try {
        final localFile = await _ensureLocalFile(file, extension);
        final cropped = await _cropImage(localFile);
        if (cropped == null) continue;
        final compressed = await _compressImage(cropped);
        final bytes = await compressed.length();
        if (bytes > _maxImageBytes) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image too large. Max size is 5MB.'),
            ),
          );
          continue;
        }
        setState(() => _selectedImages.add(compressed));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image processing failed: $e')),
        );
      }
    }
    if (mounted && _selectedImages.isNotEmpty) {
      setState(() => _currentImageIndex = 0);
    }
  }

  String _extensionFromName(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) {
      return '.jpg';
    }
    return name.substring(dotIndex).toLowerCase();
  }

  Future<File> _ensureLocalFile(XFile file, String extension) async {
    if (!file.path.startsWith('content://')) {
      return File(file.path);
    }
    final bytes = await file.readAsBytes();
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/picked_${DateTime.now().millisecondsSinceEpoch}$extension';
    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(bytes, flush: true);
    return targetFile;
  }

  Future<File?> _cropImage(File imageFile) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Image'),
        ],
      );
      if (cropped == null) return null;
      return File(cropped.path);
    } catch (e) {
      return imageFile;
    }
  }

  Future<File> _compressImage(File imageFile) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      imageFile.path,
      targetPath,
      quality: 75,
    );
    if (result == null) return imageFile;
    return File(result.path);
  }

  Future<List<String>> _uploadSelectedImages(String uid) async {
    if (_selectedImages.isEmpty) return [];
    final urls = <String>[];
    for (var i = 0; i < _selectedImages.length; i += 1) {
      if (_cancelRequested) break;
      final imageFile = _selectedImages[i];
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('news_images')
          .child(uid)
          .child(fileName);
      _currentUploadTask = ref.putFile(imageFile);
      _currentUploadTask!.snapshotEvents.listen((snapshot) {
        if (!mounted) return;
        final progress =
            snapshot.bytesTransferred / snapshot.totalBytes;
        setState(() {
          _uploadProgress =
              (i / _selectedImages.length) + (progress / _selectedImages.length);
        });
      });
      await _currentUploadTask;
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  void _cancelUploads() {
    _cancelRequested = true;
    _currentUploadTask?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Organization Story')),
      body: StreamBuilder<AppUser?>(
        stream: UserService().watchUser(firebaseUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('User profile not found.'));
          }

          final appUser = snapshot.data!;

          if (!appUser.isSuperuser &&
              (!appUser.isOrganizationAdmin ||
                  appUser.organizationId == null)) {
            return const Center(
              child: Text('Organization admin access required.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.post_add, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Organization Studio',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Draft, upload, and manage your stories.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Submit story draft',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: _inputDecoration(
                        'Title',
                        icon: Icons.title,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _summaryController,
                      decoration: _inputDecoration(
                        'Summary (optional)',
                        icon: Icons.short_text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: _inputDecoration(
                        'Category',
                        icon: Icons.category,
                      ),
                      style: const TextStyle(color: Colors.black87),
                      items: News.categories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedCategory = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _contentController,
                      maxLines: 5,
                      decoration: _inputDecoration(
                        'Content',
                        icon: Icons.article,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Images (${_selectedImages.length}/$_maxImages)',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _isSubmitting ? null : _pickImages,
                            child: Container(
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.grey.shade100,
                              ),
                              child: _selectedImages.isEmpty
                                  ? const Center(
                                      child: Icon(
                                        Icons.add_photo_alternate,
                                        size: 36,
                                        color: Color(0xFF8B1D76),
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Stack(
                                        children: [
                                          PageView.builder(
                                            controller: _imagePageController,
                                            itemCount: _selectedImages.length,
                                            onPageChanged: (index) {
                                              setState(() {
                                                _currentImageIndex = index;
                                              });
                                            },
                                            itemBuilder: (context, index) {
                                              final image = _selectedImages[index];
                                              return Image.file(
                                                image,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                          if (_selectedImages.length > 1)
                                            Positioned(
                                              bottom: 8,
                                              left: 0,
                                              right: 0,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: List.generate(
                                                  _selectedImages.length,
                                                  (index) {
                                                    final isActive =
                                                        index == _currentImageIndex;
                                                    return Container(
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 3,
                                                      ),
                                                      width: isActive ? 8 : 6,
                                                      height: isActive ? 8 : 6,
                                                      decoration: BoxDecoration(
                                                        color: isActive
                                                            ? Colors.white
                                                            : Colors.white70,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          if (_selectedImages.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Text(
                                    '${_selectedImages.length} image(s) selected',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: _isSubmitting
                                        ? null
                                        : () {
                                            setState(() {
                                              _selectedImages.clear();
                                            });
                                          },
                                    child: const Text('Clear'),
                                  ),
                                ],
                              ),
                            ),
                          if (_selectedImages.length > 1)
                            SizedBox(
                              height: 72,
                              child: ListView.separated(
                                padding: const EdgeInsets.only(top: 10),
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final image = _selectedImages[index];
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          image,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        right: -6,
                                        top: -6,
                                        child: IconButton(
                                          icon: const Icon(Icons.cancel, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              _selectedImages.removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isSubmitting && _selectedImages.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(value: _uploadProgress),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${(_uploadProgress * 100).round()}% uploaded'),
                              TextButton(
                                onPressed: _cancelUploads,
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : () => _submit(appUser),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8B1D76),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Submit Draft'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'My Drafts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<News>>(
                stream: _newsService.getDraftsByAuthor(appUser.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load drafts: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No drafts yet.'));
                  }

                  final drafts = snapshot.data!;

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: drafts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final draft = drafts[index];
                      return Container(
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
                                width: 60,
                                height: 60,
                                child: draft.imageUrls.isEmpty
                                    ? Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      )
                                    : Image.network(
                                        draft.imageUrls.first,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    draft.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    draft.summary?.isNotEmpty == true
                                        ? draft.summary!
                                        : draft.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.comment),
                              onPressed: () => _showComments(draft),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
