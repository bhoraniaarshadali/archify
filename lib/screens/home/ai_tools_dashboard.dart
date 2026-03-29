import 'package:flutter/material.dart';
import '../exterior/exterior_upload_screen.dart';
import '../interior/interior_upload_screen.dart';
import '../garden/garden_upload_screen.dart';
import '../edit_item/item_edit_upload_screen.dart';
import '../floor_plan/floor_plan_upload_screen.dart';
import '../text_to_image/text_to_image_screen.dart';
import '../style_transfer/style_transfer_upload_screen.dart';
import '../../navigation/app_navigator.dart';
import '../video_generation/video_generation_screen.dart';


class AiToolsDashboard extends StatelessWidget {
  const AiToolsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary prevents the dashboard from being redrawn unnecessarily
    return RepaintBoundary(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        child: Column(
          children: [
            // 🧪 EXPERIMENTAL TEST BUTTON (Hidden as per request)
            /*
            _ToolTile(
              title: '🧪 Interior Experiment',
              subtitle: 'Test JSON-based pipeline with API',
              icon: Icons.science_rounded,
              color: const Color(0xFFFFF9C4),
              isFullWidth: true,
              onTap: () => AppNavigator.push(context, const InteriorExperimentScreen()),
            ),
            const SizedBox(height: 16),
            */

            _ToolTile(
              title: 'Generate Video',
              subtitle: 'Turn your design into a cinematic animation',
              icon: Icons.movie_filter_rounded,
              color: const Color(0xFFE8EAF6),
              isFullWidth: true,
              onTap: () => AppNavigator.push(context, VideoGenerationScreen()),
            ),
            const SizedBox(height: 16),

            _DashboardRow(
              left: _ToolTile(
                title: 'Interior',
                subtitle: 'Redesign interior',
                icon: Icons.chair_rounded,
                color: const Color(0xFFE3F2FD),
                onTap: () => AppNavigator.push(context, const InteriorUploadScreen()),
              ),
              right: _ToolTile(
                title: 'Exterior',
                subtitle: 'Revamp facades',
                icon: Icons.home_work_rounded,
                color: const Color(0xFFE8F5E9),
                onTap: () => AppNavigator.push(context, const ExteriorUploadScreen()),
              ),
            ),

            _DashboardRow(
              left: _ToolTile(
                title: 'Garden AI',
                subtitle: 'Landscape ideas',
                icon: Icons.yard_rounded,
                color: const Color(0xFFFCE4EC),
                onTap: () => AppNavigator.push(context, const GardenUploadScreen()),
              ),
              right: _ToolTile(
                title: '2D → 3D',
                subtitle: 'Architecture AI',
                icon: Icons.map_outlined,
                color: const Color(0xFFF3E5F5),
                onTap: () => AppNavigator.push(context, const FloorPlanUploadScreen()),
              ),
            ),

            _DashboardRow(
              left: _ToolTile(
                title: 'Remove Object',
                subtitle: 'Cleanup space',
                icon: Icons.cleaning_services_rounded,
                color: const Color(0xFFF5F5F5),
                onTap: () => AppNavigator.push(context, const ItemEditUploadScreen(mode: 'remove')),
              ),
              right: _ToolTile(
                title: 'Replace Object',
                subtitle: 'Smart edit',
                icon: Icons.auto_fix_high_rounded,
                color: const Color(0xFFFFFDE7),
                onTap: () => AppNavigator.push(context, const ItemEditUploadScreen(mode: 'replace')),
              ),
            ),

            _DashboardRow(
              left: _ToolTile(
                title: 'Style Transfer',
                subtitle: 'Apply artistic styles',
                icon: Icons.palette_rounded,
                color: const Color(0xFFFFF3E0),
                onTap: () => AppNavigator.push(context, const StyleTransferUploadScreen()),
              ),
              right: _ToolTile(
                title: 'Generate Image',
                subtitle: 'Describe your dream room',
                isPro: true,
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFFE0F7FA),
                onTap: () => AppNavigator.push(context, const TextToImageScreen(designType: 'Interior')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Optimized row widget to reduce nested code
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 32, color: Colors.black87),
                if (isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Text(
                      'FREE',
                      style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            if (!isFullWidth) const SizedBox(height: 12),
            if (!isFullWidth)
              const Align(
                alignment: Alignment.bottomRight,
                child: Icon(Icons.arrow_forward_rounded, color: Colors.black26, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}