import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../services/daily_credit_manager.dart';
import '../../utils/app_constant.dart';
import '../../core/logger.dart';

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
  bool _isLoading = true;

  Package? _weeklyPackage;
  Package? _yearlyPackage;
  List<Package> _creditPacksList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        _creditPacksList.clear();
        
        // Use a Map to quickly look up packages by identifier
        final Map<String, Package> packageMap = {
          for (var pkg in offerings.current!.availablePackages) pkg.storeProduct.identifier: pkg
        };

        // Find subscription packages
        _weeklyPackage = packageMap[AppConstant.weeklyIdentifier];
        _yearlyPackage = packageMap[AppConstant.yearlyIdentifier];

        // Explicitly build the 6-item grid list based on AppConstant identifiers
        final coinIds = [
          AppConstant.firstCoinIdentifier,
          AppConstant.secondCoinIdentifier,
          AppConstant.thirdCoinIdentifier,
          AppConstant.fourthCoinIdentifier,
          AppConstant.fifthCoinIdentifier,
          AppConstant.sixthCoinIdentifier,
        ];

        for (var id in coinIds) {
          if (packageMap.containsKey(id)) {
            _creditPacksList.add(packageMap[id]!);
          }
        }
      }
    } catch (e) {
      showLog("Error fetching offerings: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _buyPackage(Package package) async {
    setState(() => _isLoading = true);
    try {
      final result = await Purchases.purchasePackage(package);
      final customerInfo = result.customerInfo;
      
      // Check if the entitlement is active
      if (customerInfo.entitlements.all[AppConstant.entitlementKey]?.isActive == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase Successful!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } else {
        // Handle non-subscription purchase (e.g. credits)
        // You might need a separate way to detect if a consumable was successful if not using entitlements for it.
        // Usually, if purchasePackage doesn't throw, it's successful.
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you for your purchase!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      showLog("Purchase error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          SafeArea(
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
          
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
              ),
            ),
        ],
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
    if (_creditPacksList.isEmpty && !_isLoading) {
       return const Center(child: Text("No credit packs available", style: TextStyle(color: Colors.white70)));
    }

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
              itemCount: _creditPacksList.length,
              itemBuilder: (context, index) {
                final package = _creditPacksList[index];
                final product = package.storeProduct;
                final bool isSelected = _selectedCreditPackIndex == index;
                final bool isPopular = index == 1; // Assuming second item is popular as before

                // Try to extract credits from ID: "some_id_300" -> "300"
                String creditsStr = product.title.split(' ')[0];
                final idParts = product.identifier.split('_');
                if (idParts.isNotEmpty) {
                  final lastPart = idParts.last;
                  if (int.tryParse(lastPart) != null) {
                    creditsStr = lastPart;
                  }
                }

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
                                creditsStr,
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
                                product.priceString,
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
            label: "Buy Credits",
            onPressed: () {
               if (_selectedCreditPackIndex >= 0) {
                 _buyPackage(_creditPacksList[_selectedCreditPackIndex]);
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Please select a credit pack')),
                 );
               }
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
          if (_weeklyPackage != null)
            _buildPremiumCard(
              index: 0,
              title: "Weekly Plan",
              subTitle: _weeklyPackage!.storeProduct.title.split(' (').first,
              reward: "Unlimited Access",
              price: _weeklyPackage!.storeProduct.priceString,
              badge: "",
            ),
          const SizedBox(height: 16),
          if (_yearlyPackage != null)
            _buildPremiumCard(
              index: 1,
              title: "Yearly Plan",
              subTitle: _yearlyPackage!.storeProduct.title.split(' (').first,
              reward: "Premium Features",
              price: _yearlyPackage!.storeProduct.priceString,
              badge: "SAVE 40%",
            ),
            
          if (_weeklyPackage == null && _yearlyPackage == null && !_isLoading)
            const Center(child: Text("No subscription plans available", style: TextStyle(color: Colors.white70))),

          const Spacer(),
          _buildActionButton(
            label: "Subscribe Now",
            onPressed: () {
               if (_selectedPremiumPlanIndex == 0 && _weeklyPackage != null) {
                 _buyPackage(_weeklyPackage!);
               } else if (_selectedPremiumPlanIndex == 1 && _yearlyPackage != null) {
                 _buyPackage(_yearlyPackage!);
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Please select a plan')),
                 );
               }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard({
    required int index,
    required String title,
    required String subTitle,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (subTitle.isNotEmpty)
                              Text(
                                subTitle,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10, // Small subtitle
                                ),
                              ),
                          ],
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

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      if (customerInfo.entitlements.all[AppConstant.entitlementKey]?.isActive == true) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchases Restored!'), backgroundColor: Colors.green),
          );
           Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active subscriptions found.')),
          );
        }
      }
    } catch (e) {
      showLog("Restore error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildFooterLinks() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FooterLink(label: 'Terms of use', onTap: () {}),
          const _FooterLinkSpacer(),
          _FooterLink(label: 'Privacy Policy', onTap: () {}),
          const _FooterLinkSpacer(),
          _FooterLink(label: 'Restore', onTap: _restorePurchases),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white38, fontSize: 11),
      ),
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
