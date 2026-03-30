import 'package:flutter/material.dart';
import '../../navigation/app_navigator.dart';
import '../../ads/remote_config_service.dart';

// Screens
import '../video_generation/video_generation_screen.dart';
import '../interior/interior_upload_screen.dart';
import '../exterior/exterior_upload_screen.dart';
import '../garden/garden_upload_screen.dart';
import '../floor_plan/floor_plan_upload_screen.dart';
import '../edit_item/item_edit_upload_screen.dart';
import '../style_transfer/style_transfer_upload_screen.dart';
import '../text_to_image/text_to_image_screen.dart';

class AiToolsDashboard extends StatelessWidget {
  const AiToolsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          children: _buildDashboardContent(context),
        ),
      ),
    );
  }

  List<Widget> _buildDashboardContent(BuildContext context) {
    final List<Widget> content = [];

    // 1. Full Width Video Tile
    if (RemoteConfigService.isFeatureEnabled(FeatureType.videoGeneration)) {
      content.add(
        _ToolTile(
          title: 'Generate Video',
          subtitle: 'Turn your design into a cinematic animation',
          icon: Icons.movie_filter_rounded,
          color: const Color(0xFFE8EAF6),
          isFullWidth: true,
          onTap: () => AppNavigator.push(context, VideoGenerationScreen()),
        ),
      );
      content.add(const SizedBox(height: 16));
    }

    // 2. Grid Items
    final List<Widget> gridItems = [];

    // Interior
    if (RemoteConfigService.isFeatureEnabled(FeatureType.interior)) {
      gridItems.add(_ToolTile(
        title: 'Interior',
        subtitle: 'Redesign interior',
        icon: Icons.chair_rounded,
        color: const Color(0xFFE3F2FD),
        onTap: () => AppNavigator.push(context, const InteriorUploadScreen()),
      ));
    }

    // Exterior
    if (RemoteConfigService.isFeatureEnabled(FeatureType.exterior)) {
      gridItems.add(_ToolTile(
        title: 'Exterior',
        subtitle: 'Revamp facades',
        icon: Icons.home_work_rounded,
        color: const Color(0xFFE8F5E9),
        onTap: () => AppNavigator.push(context, const ExteriorUploadScreen()),
      ));
    }

    // Garden AI
    if (RemoteConfigService.isFeatureEnabled(FeatureType.garden)) {
      gridItems.add(_ToolTile(
        title: 'Garden AI',
        subtitle: 'Landscape ideas',
        icon: Icons.yard_rounded,
        color: const Color(0xFFFCE4EC),
        onTap: () => AppNavigator.push(context, const GardenUploadScreen()),
      ));
    }

    // Floor Plan (2D → 3D)
    if (RemoteConfigService.isFeatureEnabled(FeatureType.floorPlan)) {
      gridItems.add(_ToolTile(
        title: '2D → 3D',
        subtitle: 'Architecture AI',
        icon: Icons.map_outlined,
        color: const Color(0xFFF3E5F5),
        onTap: () => AppNavigator.push(context, const FloorPlanUploadScreen()),
      ));
    }

    // Object Removal
    if (RemoteConfigService.isFeatureEnabled(FeatureType.objectRemove)) {
      gridItems.add(_ToolTile(
        title: 'Remove Object',
        subtitle: 'Cleanup space',
        icon: Icons.cleaning_services_rounded,
        color: const Color(0xFFF5F5F5),
        onTap: () => AppNavigator.push(context, const ItemEditUploadScreen(mode: 'remove')),
      ));
    }

    // Object Replacement
    if (RemoteConfigService.isFeatureEnabled(FeatureType.objectReplace)) {
      gridItems.add(_ToolTile(
        title: 'Replace Object',
        subtitle: 'Smart edit',
        icon: Icons.auto_fix_high_rounded,
        color: const Color(0xFFFFFDE7),
        onTap: () => AppNavigator.push(context, const ItemEditUploadScreen(mode: 'replace')),
      ));
    }

    // Style Transfer
    if (RemoteConfigService.isFeatureEnabled(FeatureType.styleTransfer)) {
      gridItems.add(_ToolTile(
        title: 'Style Transfer',
        subtitle: 'Apply artistic styles',
        icon: Icons.palette_rounded,
        color: const Color(0xFFFFF3E0),
        onTap: () => AppNavigator.push(context, const StyleTransferUploadScreen()),
      ));
    }

    // Image Generation
    if (RemoteConfigService.isFeatureEnabled(FeatureType.imageGeneration)) {
      gridItems.add(_ToolTile(
        title: 'Generate Image',
        subtitle: 'Describe your dream room',
        isPro: true,
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFFE0F7FA),
        onTap: () => AppNavigator.push(context, const TextToImageScreen(designType: 'Interior')),
      ));
    }

    // Group grid items into rows
    for (int i = 0; i < gridItems.length; i += 2) {
      if (i + 1 < gridItems.length) {
        content.add(_DashboardRow(left: gridItems[i], right: gridItems[i + 1]));
      } else {
        // Handle odd item: show as full width or half width with space
        content.add(_DashboardRow(
          left: gridItems[i],
          right: const SizedBox.shrink(),
        ));
      }
    }

    return content;
  }
}

class _DashboardRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _DashboardRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isPro;
  final bool isFullWidth;

  const _ToolTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isPro = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.blueGrey[800], size: 24),
                ),
                if (isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.blueGrey[900],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.blueGrey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}