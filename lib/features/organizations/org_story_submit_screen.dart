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
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final _newsService = NewsService();
  final _commentService = DraftCommentService();
  final _imagePicker = ImagePicker();
  bool _isSubmitting = false;
  String _selectedCategory = News.categories.first;
  final List<File> _selectedImages = [];
  double _uploadProgress = 0;
  UploadTask? _currentUploadTask;
  bool _cancelRequested = false;

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

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Submit story (draft)',
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
                  controller: _summaryController,
                  decoration: const InputDecoration(
                    labelText: 'Summary (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
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
                const SizedBox(height: 8),
                TextField(
                  controller: _contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final image in _selectedImages)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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
                                setState(() => _selectedImages.remove(image));
                              },
                            ),
                          ),
                        ],
                      ),
                    GestureDetector(
                      onTap: _isSubmitting ? null : _pickImages,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_photo_alternate),
                      ),
                    ),
                  ],
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
                      const SizedBox(height: 12),
                    ],
                  ),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submit(appUser),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Draft'),
                ),
                const SizedBox(height: 18),
                const Text(
                  'My Drafts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<News>>(
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

                      return ListView.builder(
                        itemCount: drafts.length,
                        itemBuilder: (context, index) {
                          final draft = drafts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: draft.imageUrls.isEmpty
                                  ? const Icon(Icons.image_not_supported)
                                  : Image.network(
                                      draft.imageUrls.first,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                        Icons.broken_image,
                                      ),
                                    ),
                              title: Text(draft.title),
                              subtitle: Text(
                                draft.summary?.isNotEmpty == true
                                    ? draft.summary!
                                    : draft.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.comment),
                                onPressed: () => _showComments(draft),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
