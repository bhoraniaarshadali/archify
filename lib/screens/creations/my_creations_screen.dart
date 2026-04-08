import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:io';
import '../../services/helper/my_creations_service.dart';
import '../exterior/result_screen.dart';
import '../video_generation/video_result_screen.dart';
import '../../navigation/app_navigator.dart';

class MyCreationsScreen extends StatefulWidget {
  const MyCreationsScreen({super.key});

  @override
  State<MyCreationsScreen> createState() => _MyCreationsScreenState();
}

class _MyCreationsScreenState extends State<MyCreationsScreen> {
  List<MyCreation> _creations = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Images',
    'Videos',
    'Interior',
    'Exterior',
    'Garden',
    'Text-to-Image',
    'Floor Plan',
    'Custom',
    // 'Remove Object',
    // 'Replace Object',
  ];

  @override
  void initState() {
    super.initState();
    _loadCreations();
    MyCreationsService.creationsChangeNotifier.addListener(_loadCreations);
  }

  @override
  void dispose() {
    MyCreationsService.creationsChangeNotifier.removeListener(_loadCreations);
    super.dispose();
  }

  Future<void> _loadCreations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final creations = await MyCreationsService.getCreations();
      if (mounted) {
        setState(() {
          _creations = creations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading creations: $e');
    }
  }

  List<MyCreation> get _filteredCreations {
    if (_selectedFilter == 'All') return _creations;
    if (_selectedFilter == 'Images') {
      return _creations.where((c) => c.type == CreationType.image).toList();
    }
    if (_selectedFilter == 'Videos') {
      return _creations.where((c) => c.type == CreationType.video).toList();
    }

    // Category mapping
    final filterToCategory = {
      'Interior': 'interior',
      'Exterior': 'exterior',
      'Garden': 'garden',
      'Text-to-Image': 'textToImage',
      'Floor Plan': 'floorPlan',
      'Custom': 'custom',
      // 'Remove Object': 'removeObject',
      // 'Replace Object': 'replaceObject',
    };

    final targetCategory = filterToCategory[_selectedFilter];
    if (targetCategory == null) return [];

    return _creations.where((c) => c.category.name == targetCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildFilters()),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Colors.black)),
            )
          else if (_filteredCreations.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildCreationCard(_filteredCreations[index]),
                  childCount: _filteredCreations.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFF9FAFB),
      elevation: 0,
      centerTitle: false,
      title: const Text(
        'MY GALLERY',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 28,
          letterSpacing: -1.5,
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: isSelected ? Colors.black : Colors.black12),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_mosaic_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No designs yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildCreationCard(MyCreation creation) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () async {
          if (creation.status == GenerationStatus.processing) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Still processing... Please wait ✨')),
            );
            return;
          }
          if (creation.status == GenerationStatus.failed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Generation failed. Try creating a new one!')),
            );
            return;
          }

          bool? shouldRefresh;


          if (creation.type == CreationType.image) {
            shouldRefresh = await AppNavigator.push(
              context,
              ResultScreen(
                originalImage: creation.originalMediaUrl ?? creation.mediaUrl,
                generatedImage: creation.mediaUrl,
                styleName: _getCategoryLabel(creation.category),
                allowFromCreations: true,
                creationId: creation.id,
              ),
            );
          } else {
            shouldRefresh = await AppNavigator.push(
              context,
              VideoResultScreen(
                videoUrl: creation.mediaUrl,
                category: creation.category.name,
                duration: creation.metadata?['duration'] ?? 5,
                originalImageUrl: creation.originalMediaUrl,
                creationId: creation.id,
                allowFromCreations: true,
              ),
            );
          }

          // Only reload if the detail screen explicitly asks for it
          // (e.g. after delete, download, or edit)
          if (shouldRefresh == true) {
            _loadCreations();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildMediaThumb(
                (creation.thumbnailPath != null && creation.thumbnailPath!.isNotEmpty)
                    ? creation.thumbnailPath!
                    : (creation.type == CreationType.video
                        ? (creation.originalMediaUrl ?? creation.mediaUrl)
                        : creation.mediaUrl),
                creation,
              ),

              if (creation.type == CreationType.video)
                const Center(
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 24,
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                  ),
                ),
              Positioned(
                top: 12,
                left: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.55),
                            Colors.black.withOpacity(0.25),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getCategoryLabel(creation.category),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ✅ PROCESSING OVERLAY
              if (creation.status == GenerationStatus.processing)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Processing...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black.withOpacity(0.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ✅ FAILED OVERLAY
              if (creation.status == GenerationStatus.failed)
                Container(
                  color: Colors.red.withOpacity(0.1),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 32),
                        const SizedBox(height: 4),
                        Text(
                          'Failed',
                          style: TextStyle(
                            color: Colors.red[400],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaThumb(String url, MyCreation creation) {
    if (creation.status == GenerationStatus.processing || url.isEmpty) {
      // Show original image if available during processing
      if (creation.originalMediaUrl != null && creation.originalMediaUrl!.isNotEmpty) {
        return _buildImage(creation.originalMediaUrl!);
      }
      return Container(
        color: Colors.grey[100],
        child: const Icon(Icons.image_outlined, color: Colors.black12, size: 40),
      );
    }
    return _buildImage(url);
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        cacheWidth: 300,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(color: Colors.grey[100]);
        },
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error_outline),
      );
    } else {
      final cleanPath = url.replaceFirst('file://', '');
      return Image.file(
        File(cleanPath),
        fit: BoxFit.cover,
        cacheWidth: 300,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
      );
    }
  }


  String _getCategoryLabel(CreationCategory category) {
    switch (category) {
      case CreationCategory.textToImage:
        return 'AI ART';
      case CreationCategory.removeObject:
        return 'REMOVAL';
      case CreationCategory.replaceObject:
        return 'REPLACE';
      case CreationCategory.custom:
        return 'CUSTOM';
      default:
        return category.name.toUpperCase();
    }
  }
}