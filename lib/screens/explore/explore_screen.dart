import 'dart:ui';
import 'package:flutter/material.dart';
import '../reels/reels_screen.dart';
import '../home/home_screen.dart';
import '../../ads/app_state.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    setState(() {}); // Rebuild for switcher state
    if (_tabController.indexIsChanging) return;
    final isReels = _tabController.index == 1;
    AppState().setShowBottomNav(!isReels);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    // Ensure bottom nav is visible when leaving ExploreScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppState().setShowBottomNav(true);
    });
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _tabController.index == 1 ? Colors.black : const Color(0xFFF8F9FC),
      body: Stack(
        children: [
          // Content
          TabBarView(
            controller: _tabController,
            children: [
              _buildInspirationView(),
              const ReelsScreen(),
            ],
          ),
          
          // Floating Top Switcher
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopSwitcher(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSwitcher() {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: topPadding + 10, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Back Button
          _buildGlassCircleButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () {
              AppState().setShowBottomNav(true);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
          
          const Spacer(),
          
          // Tab Switcher
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSwitchTab('Inspiration', 0),
                    _buildSwitchTab('Reels', 1),
                  ],
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Empty space to balance the back button
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildSwitchTab(String text, int index) {
    bool isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4FF00) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.black.withOpacity(0.9),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCircleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInspirationView() {
    final topPadding = MediaQuery.of(context).padding.top + 80;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPadding),
          // Categories
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                 _buildCategoryChip('All', isSelected: true),
                 _buildCategoryChip('Modern'),
                 _buildCategoryChip('Industrial'),
                 _buildCategoryChip('Minimalist'),
                 _buildCategoryChip('Victorian'),
                 _buildCategoryChip('Rustic'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Inspiration Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: 10,
              itemBuilder: (context, index) {
                return _buildInspirationCard(index);
              },
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade200,
        ),
      ),
      child: Center(
        child: Text(label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildInspirationCard(int index) {
    final images = [
      'assets/images/styles/interior/industrial.jpg',
      'assets/images/styles/interior/minimalist.jpg',
      'assets/images/styles/interior/modern.jpg',
      'assets/images/styles/interior/scandinavian.jpg',
      'assets/images/styles/interior/luxury.jpg',
      'assets/images/styles/interior/rustic.jpg',
      'assets/images/styles/interior/bohemian.jpg',
      'assets/images/styles/interior/victorian.jpg',
      'assets/images/styles/interior/japanese_zen.jpg',
      'assets/images/styles/interior/mediterranean.jpg',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Image.asset(
                images[index % images.length],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Modern Living Room',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Curated by AI',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
