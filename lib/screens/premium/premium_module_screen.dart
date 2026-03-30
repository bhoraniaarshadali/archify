import 'package:flutter/material.dart';
import '../../services/daily_credit_manager.dart';

class PremiumModuleScreen extends StatefulWidget {
  final int initialTabIndex;
  const PremiumModuleScreen({super.key, this.initialTabIndex = 0});

  @override
  State<PremiumModuleScreen> createState() => _PremiumModuleScreenState();
}

class _PremiumModuleScreenState extends State<PremiumModuleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPremiumPlanIndex = 1; // 0 for Weekly, 1 for Yearly (Default)
  int _selectedCreditPackIndex = -1;

  final List<Map<String, dynamic>> _creditPacks = [
    {'credits': 10, 'price': '\$1.99', 'badge': ''},
    {'credits': 31, 'price': '\$4.99', 'badge': 'POPULAR'},
    {'credits': 70, 'price': '\$9.99', 'badge': ''},
    {'credits': 165, 'price': '\$19.99', 'badge': ''},
    {'credits': 400, 'price': '\$39.99', 'badge': ''},
    {'credits': 860, 'price': '\$56.99', 'badge': ''},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Banner Area
            _buildTopBanner(),

            // 2. Tab Switcher (Pills)
            _buildTabSwitcher(),

            // 3. Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCreditPlanTab(),
                  _buildPremiumPlanTab(),
                ],
              ),
            ),

            // 4. Footer Links
            _buildFooterLinks(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepPurple.withOpacity(0.35),
            const Color(0xFF0D0D0D),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 40,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<int>(
                  valueListenable: DailyCreditManager.creditsNotifier,
                  builder: (context, credits, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '$credits Credits Balance',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _buildTabPill('Credit Plan', 0),
          _buildTabPill('Premium Plan', 1),
        ],
      ),
    );
  }

  Widget _buildTabPill(String label, int index) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreditPlanTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _creditPacks.length,
              itemBuilder: (context, index) {
                final pack = _creditPacks[index];
                final bool isPopular = pack['badge'] == 'POPULAR';
                final bool isSelected = _selectedCreditPackIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCreditPackIndex = index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.deepPurpleAccent 
                            : (isPopular ? Colors.deepPurpleAccent.withOpacity(0.5) : Colors.white10),
                        width: isSelected || isPopular ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        if (isPopular)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: const BoxDecoration(
                                color: Colors.deepPurpleAccent,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(18),
                                  bottomLeft: Radius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'POPULAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${pack['credits']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Credits',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pack['price'],
                                style: const TextStyle(
                                  color: Colors.deepPurpleAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: "Get Credit",
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Coming Soon'), duration: Duration(seconds: 1)),
               );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumPlanTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildPremiumCard(
            index: 0,
            title: "Weekly Plan",
            reward: "50 Credits/week",
            price: "\$2.99/week",
            badge: "",
          ),
          const SizedBox(height: 16),
          _buildPremiumCard(
            index: 1,
            title: "Yearly Plan",
            reward: "300 Credits/week",
            price: "\$17.55/year",
            badge: "SAVE 40%",
          ),
          const Spacer(),
          _buildActionButton(
            label: "Subscribe Now",
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Coming Soon'), duration: Duration(seconds: 1)),
               );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard({
    required int index,
    required String title,
    required String reward,
    required String price,
    required String badge,
  }) {
    final bool isSelected = _selectedPremiumPlanIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPremiumPlanIndex = index),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.deepPurpleAccent : Colors.white10,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reward,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    price,
                    style: const TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.deepPurpleAccent : Colors.white30,
                  width: 2,
                ),
                color: isSelected ? Colors.deepPurpleAccent : Colors.transparent,
              ),
              child: isSelected 
                  ? const Icon(Icons.check, color: Colors.white, size: 14) 
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _FooterLink(label: 'Terms of use'),
          _FooterLinkSpacer(),
          _FooterLink(label: 'Privacy Policy'),
          _FooterLinkSpacer(),
          _FooterLink(label: 'Restore'),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  const _FooterLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(color: Colors.white38, fontSize: 11),
    );
  }
}

class _FooterLinkSpacer extends StatelessWidget {
  const _FooterLinkSpacer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text('|', style: TextStyle(color: Colors.white10, fontSize: 11)),
    );
  }
}
