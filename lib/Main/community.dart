import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../singleton.dart';
import '../utils/haptic_utils.dart';

// Data models for community features
class CommunityPost {
  final String id;
  final String authorName;
  final String authorImage;
  final String content;
  final DateTime timestamp;
  final String? category;
  int likes;
  bool isLiked;
  final List<PostComment> comments;

  CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorImage,
    required this.content,
    required this.timestamp,
    this.category,
    this.likes = 0,
    this.isLiked = false,
    List<PostComment>? comments,
  }) : comments = comments ?? [];
}

class PostComment {
  final String id;
  final String authorName;
  final String authorImage;
  final String content;
  final DateTime timestamp;

  PostComment({
    required this.id,
    required this.authorName,
    required this.authorImage,
    required this.content,
    required this.timestamp,
  });
}

class SupportGroup {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int memberCount;
  bool isJoined;

  SupportGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.memberCount,
    this.isJoined = false,
  });
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final singleton = Singleton();
  List<CommunityPost> _posts = [];
  final List<SupportGroup> _groups = <SupportGroup>[
    SupportGroup(
      id: 'caregivers',
      name: 'Caregivers Circle',
      description: 'Support for caregivers and family members',
      icon: Icons.family_restroom_outlined,
      color: const Color(0xFF3B82F6),
      memberCount: 1280,
    ),
    SupportGroup(
      id: 'newly-diagnosed',
      name: 'Newly Diagnosed',
      description: 'Early-stage guidance and peer support',
      icon: Icons.waving_hand_outlined,
      color: const Color(0xFF0EA5E9),
      memberCount: 940,
    ),
    SupportGroup(
      id: 'movement',
      name: 'Movement & Mobility',
      description: 'Daily routines for balance and mobility',
      icon: Icons.directions_walk_rounded,
      color: const Color(0xFF10B981),
      memberCount: 760,
    ),
  ];
  bool _isLoadingFeed = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFeedData();
  }

  DateTime _parseTimestamp(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Future<void> _loadFeedData() async {
    if (!mounted) return;
    setState(() => _isLoadingFeed = true);

    final rawPosts = await singleton.loadCommunityPosts(limit: 100);

    final posts = rawPosts.map((row) {
      return CommunityPost(
        id: row['id']?.toString() ?? '',
        authorName: row['user_name']?.toString() ?? 'Community Member',
        authorImage: row['profile_image']?.toString() ?? 'images/711128.png',
        content: row['content']?.toString() ?? '',
        timestamp: _parseTimestamp(row['created_at']),
        category: row['category']?.toString(),
        likes: (row['likes'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    if (!mounted) return;
    setState(() {
      _posts = posts;
      _isLoadingFeed = false;
    });
  }

  Future<void> _loadCommentsForPost(CommunityPost post) async {
    final rawComments = await singleton.loadCommunityComments(post.id);
    final mapped = rawComments.map((row) {
      return PostComment(
        id: row['id']?.toString() ?? '',
        authorName: row['user_name']?.toString() ?? 'Member',
        authorImage: singleton.image,
        content: row['content']?.toString() ?? '',
        timestamp: _parseTimestamp(row['created_at']),
      );
    }).toList();

    if (!mounted) return;
    setState(() {
      post.comments
        ..clear()
        ..addAll(mapped);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openCommentsSheet(CommunityPost post) async {
    await _loadCommentsForPost(post);
    if (!mounted) return;
    _showCommentsSheet(post);
  }

  void _showCreatePostSheet() {
    final colors = context.colors;
    final textController = TextEditingController();
    String? selectedCategory;
    final categories = [
      'General',
      'Exercise Tips',
      'Speech Therapy',
      'Daily Living',
      'Questions'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create Post',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                // Category selector
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedCategory = cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color:
                                  isSelected ? colors.primary : colors.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : colors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Share your thoughts, experience, or questions...',
                    hintStyle: TextStyle(color: colors.textTertiary),
                    filled: true,
                    fillColor: colors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Cancel',
                            style: TextStyle(color: colors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final content = textController.text.trim();
                          if (content.isEmpty) return;

                          final messenger = ScaffoldMessenger.of(context);
                          HapticUtils.lightImpact();
                          final success = await singleton.createCommunityPost(
                            content: content,
                            category: selectedCategory ?? 'General',
                          );
                          if (!mounted || !ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (success) {
                            await _loadFeedData();
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text('Post shared'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Unable to share post. Complete profile setup first.'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Post'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: colors.primary,
            indicatorWeight: 2,
            labelColor: colors.textPrimary,
            unselectedLabelColor: colors.textTertiary,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Feed'),
              Tab(text: 'Groups'),
              Tab(text: 'Resources'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFeedTab(colors),
              _buildGroupsTab(colors),
              _buildResourcesTab(colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedTab(AppColors colors) {
    return Column(
      children: [
        // Create post button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: _showCreatePostSheet,
            child: ModernCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildUserAvatar(40, colors),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Share something with the community...',
                        style: TextStyle(color: colors.textTertiary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Posts list or empty state
        Expanded(
          child: _isLoadingFeed
              ? Center(
                  child: CircularProgressIndicator(color: colors.primary),
                )
              : _posts.isEmpty
                  ? _buildEmptyFeedState(colors)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildPostCard(_posts[index], colors),
                    ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar(double size, AppColors colors) {
    final hasCustomImage = singleton.image.isNotEmpty &&
        singleton.image != 'images/711128.png' &&
        !singleton.image.contains('711128');

    if (hasCustomImage && singleton.image.startsWith('images/')) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: colors.primary.withValues(alpha: 0.1),
        backgroundImage: AssetImage(singleton.image),
      );
    }

    if (hasCustomImage && File(singleton.image).existsSync()) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: colors.primary.withValues(alpha: 0.1),
        backgroundImage: FileImage(File(singleton.image)),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.primary.withValues(alpha: 0.1),
      child: Text(
        singleton.name.isNotEmpty && singleton.name != '[Name]'
            ? singleton.name[0].toUpperCase()
            : 'U',
        style: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  Widget _buildPostAuthorAvatar(
      CommunityPost post, double size, AppColors colors) {
    final hasCustomImage = post.authorImage.isNotEmpty &&
        post.authorImage != 'images/711128.png' &&
        !post.authorImage.contains('711128');

    if (hasCustomImage) {
      if (post.authorImage.startsWith('images/')) {
        return CircleAvatar(
          radius: size / 2,
          backgroundColor: colors.primary.withValues(alpha: 0.1),
          backgroundImage: AssetImage(post.authorImage),
        );
      }
      if (!File(post.authorImage).existsSync()) {
        return CircleAvatar(
          radius: size / 2,
          backgroundColor: colors.primary.withValues(alpha: 0.1),
          child: Text(
            post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.4,
            ),
          ),
        );
      }
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: colors.primary.withValues(alpha: 0.1),
        backgroundImage: FileImage(File(post.authorImage)),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.primary.withValues(alpha: 0.1),
      child: Text(
        post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'U',
        style: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  Widget _buildCommentAuthorAvatar(
      PostComment comment, double size, AppColors colors) {
    final hasCustomImage = comment.authorImage.isNotEmpty &&
        comment.authorImage != 'images/711128.png' &&
        !comment.authorImage.contains('711128');

    if (hasCustomImage) {
      if (comment.authorImage.startsWith('images/')) {
        return CircleAvatar(
          radius: size / 2,
          backgroundColor: colors.surfaceVariant,
          backgroundImage: AssetImage(comment.authorImage),
        );
      }
      if (!File(comment.authorImage).existsSync()) {
        return CircleAvatar(
          radius: size / 2,
          backgroundColor: colors.surfaceVariant,
          child: Text(
            comment.authorName.isNotEmpty
                ? comment.authorName[0].toUpperCase()
                : 'U',
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.4,
            ),
          ),
        );
      }
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: colors.surfaceVariant,
        backgroundImage: FileImage(File(comment.authorImage)),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.surfaceVariant,
      child: Text(
        comment.authorName.isNotEmpty
            ? comment.authorName[0].toUpperCase()
            : 'U',
        style: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  Widget _buildEmptyFeedState(AppColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 40,
              color: colors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to share something with the community.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showCreatePostSheet,
              child: const Text('Create Post'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post, AppColors colors) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              _buildPostAuthorAvatar(post, 40, colors),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      _formatTimestamp(post.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
              if (post.category != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post.category!,
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Content
          Text(
            post.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 16),

          // Actions row
          Row(
            children: [
              _buildActionButton(
                icon: post.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                label: post.likes.toString(),
                color: post.isLiked ? colors.error : colors.textSecondary,
                onTap: () async {
                  if (post.isLiked) return;
                  HapticUtils.lightImpact();
                  final liked = await singleton.likeCommunityPost(post.id);
                  if (!mounted) return;
                  if (liked) {
                    setState(() {
                      post.isLiked = true;
                      post.likes += 1;
                    });
                  }
                },
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: post.comments.length.toString(),
                color: colors.textSecondary,
                onTap: () => _openCommentsSheet(post),
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                color: colors.textSecondary,
                onTap: () {
                  HapticUtils.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Sharing coming soon!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
            ],
          ),

          // Show preview of comments if any
          if (post.comments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: colors.divider),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _openCommentsSheet(post),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCommentAuthorAvatar(post.comments.first, 28, colors),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall,
                        children: [
                          TextSpan(
                            text: '${post.comments.first.authorName} ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: post.comments.first.content,
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (post.comments.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GestureDetector(
                  onTap: () => _openCommentsSheet(post),
                  child: Text(
                    'View all ${post.comments.length} comments',
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentsSheet(CommunityPost post) {
    final colors = context.colors;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Comments',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Expanded(
                child: post.comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 48, color: colors.textTertiary),
                            const SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              style: TextStyle(color: colors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to comment!',
                              style: TextStyle(
                                  color: colors.textTertiary, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: post.comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final comment = post.comments[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCommentAuthorAvatar(comment, 36, colors),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          comment.authorName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatTimestamp(comment.timestamp),
                                          style: TextStyle(
                                              color: colors.textTertiary,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.content,
                                      style: TextStyle(
                                          color: colors.textSecondary,
                                          height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              // Comment input
              Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.divider)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle: TextStyle(color: colors.textTertiary),
                          filled: true,
                          fillColor: colors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        final comment = commentController.text.trim();
                        if (comment.isEmpty) return;
                        final messenger = ScaffoldMessenger.of(context);
                        HapticUtils.success();
                        final success = await singleton.createCommunityComment(
                          postId: post.id,
                          content: comment,
                        );
                        if (!mounted || !ctx.mounted) return;
                        if (!success) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: const Text('Unable to add comment'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                          );
                          return;
                        }

                        await _loadCommentsForPost(post);
                        if (!mounted || !ctx.mounted) return;
                        setModalState(() {});
                        commentController.clear();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
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

  Widget _buildGroupsTab(AppColors colors) {
    if (_groups.isEmpty) {
      return _buildEmptyGroupsState(colors);
    }

    final joinedGroups = _groups.where((g) => g.isJoined).toList();
    final availableGroups = _groups.where((g) => !g.isJoined).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (joinedGroups.isNotEmpty) ...[
          Text(
            'Your Groups',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          ...joinedGroups.map((group) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildGroupCard(group, colors),
              )),
          const SizedBox(height: 16),
        ],
        if (availableGroups.isNotEmpty) ...[
          Text(
            'Discover',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 12),
          ...availableGroups.map((group) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildGroupCard(group, colors),
              )),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEmptyGroupsState(AppColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 40,
              color: colors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No groups available',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Support groups will appear here as they become available.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(SupportGroup group, AppColors colors) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(group.icon, color: colors.textSecondary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatMemberCount(group.memberCount)} members',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              HapticUtils.lightImpact();
              setState(() {
                group.isJoined = !group.isJoined;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(group.isJoined
                      ? 'Joined ${group.name}'
                      : 'Left ${group.name}'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: group.isJoined ? colors.surfaceVariant : colors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                group.isJoined ? 'Joined' : 'Join',
                style: TextStyle(
                  color: group.isJoined ? colors.textSecondary : Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesTab(AppColors colors) {
    final resources = [
      {
        'icon': Icons.article_outlined,
        'title': 'Latest Research',
        'subtitle': 'Recent studies and findings'
      },
      {
        'icon': Icons.video_library_outlined,
        'title': 'Educational Videos',
        'subtitle': 'Learn about symptom management'
      },
      {
        'icon': Icons.local_hospital_outlined,
        'title': 'Find Specialists',
        'subtitle': 'Connect with movement disorder experts'
      },
      {
        'icon': Icons.event_outlined,
        'title': 'Events Calendar',
        'subtitle': 'Webinars, support groups & meetups'
      },
      {
        'icon': Icons.phone_outlined,
        'title': 'Helpline',
        'subtitle': '24/7 support available'
      },
      {
        'icon': Icons.menu_book_outlined,
        'title': 'Daily Living Guides',
        'subtitle': 'Daily living resources'
      },
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        ...resources.map((resource) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ModernCard(
                onTap: () {
                  HapticUtils.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${resource['title']} - Coming soon'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  );
                },
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(resource['icon'] as IconData,
                        color: colors.textSecondary, size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resource['title'] as String,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            resource['subtitle'] as String,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.textTertiary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 20, color: colors.textTertiary),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 20),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  String _formatMemberCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
