import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../ads/app_state.dart';
import '../../services/premium/billing_service.dart';
import '../../services/daily_credit_manager.dart';

class PremiumModuleScreen extends StatefulWidget {
  final int initialTabIndex;
  const PremiumModuleScreen({super.key, this.initialTabIndex = 0});

  @override
  State<PremiumModuleScreen> createState() => _PremiumModuleScreenState();
}

class _PremiumModuleScreenState extends State<PremiumModuleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Premium Center',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.deepPurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepPurple,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Subscriptions'),
            Tab(text: 'Credits'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const SubscriptionPlansTab(),
          CreditPurchaseTab(onUpgradeRequest: () {
            _tabController.animateTo(0);
          }),
        ],
      ),
    );
  }
}

class SubscriptionPlansTab extends StatefulWidget {
  const SubscriptionPlansTab({super.key});

  @override
  State<SubscriptionPlansTab> createState() => _SubscriptionPlansTabState();
}

class _SubscriptionPlansTabState extends State<SubscriptionPlansTab> {
  List<ProductDetails> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final products = await BillingService().getProducts({
      BillingService.planStandard,
      BillingService.planPremium,
      BillingService.planArchitect,
    });
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Sort products based on price or custom logic
    _products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Choose Your Plan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._products.map((product) {
            PlanTier tier = PlanTier.free;
            String title = product.title.split('(').first.trim();
            Color color = Colors.blue.shade700;
            List<String> features = [];
            bool isBestValue = false;

            if (product.id == BillingService.planStandard) {
              tier = PlanTier.standard;
              features = ['HD Quality', 'Basic Styles', 'Ad-Free'];
            } else if (product.id == BillingService.planPremium) {
              tier = PlanTier.premium;
              features = ['Ultra-HD Quality', 'All Styles', 'Priority Queue', 'Ad-Free'];
              color = Colors.deepPurple.shade700;
              isBestValue = true;
            } else if (product.id == BillingService.planArchitect) {
              tier = PlanTier.architect;
              features = ['Commercial License', '4K Renders', 'Unlimited Credits', '24/7 Support'];
              color = Colors.indigo.shade900;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildPlanCard(
                context,
                tier: tier,
                title: title,
                price: product.price,
                features: features,
                color: color,
                isBestValue: isBestValue,
                product: product,
              ),
            );
          }),
          if (_products.isEmpty)
            const Text('No plans available at the moment. Please try again later.'),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required PlanTier tier,
    required String title,
    required String price,
    required List<String> features,
    required Color color,
    required ProductDetails product,
    bool isBestValue = false,
  }) {
    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        final bool isCurrent = AppState.planTier == tier;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (isBestValue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Best Value',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const Divider(color: Colors.white24, height: 32),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Text(f, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isCurrent
                      ? null
                      : () => BillingService().buyProduct(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    disabledBackgroundColor: Colors.white.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isCurrent ? 'Current Plan' : 'Subscribe',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CreditPurchaseTab extends StatefulWidget {
  final VoidCallback onUpgradeRequest;
  const CreditPurchaseTab({super.key, required this.onUpgradeRequest});

  @override
  State<CreditPurchaseTab> createState() => _CreditPurchaseTabState();
}

class _CreditPurchaseTabState extends State<CreditPurchaseTab> {
  List<ProductDetails> _creditProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final products = await BillingService().getProducts({
      BillingService.creditsSmall,
      BillingService.creditsMedium,
      BillingService.creditsLarge,
    });
    if (mounted) {
      setState(() {
        _creditProducts = products;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        final tier = AppState.planTier;
        final bool canBuy = tier == PlanTier.premium || tier == PlanTier.architect;

        if (!canBuy) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Exclusive Feature',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Credit purchasing is only available for Premium and Architect members.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: widget.onUpgradeRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Upgrade Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return _buildCreditStore();
      },
    );
  }

  Widget _buildCreditStore() {
    _creditProducts.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Refill Credits',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Keep generating without waiting',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              ValueListenableBuilder<int>(
                valueListenable: DailyCreditManager.creditsNotifier,
                builder: (context, credits, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '$credits',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._creditProducts.map((product) {
            String title = 'Starter Pack';
            int credits = 0;
            bool isRecommended = false;

            if (product.id == BillingService.creditsSmall) {
              title = 'Small Pack';
              credits = 50;
            } else if (product.id == BillingService.creditsMedium) {
              title = 'Medium Pack';
              credits = 150;
              isRecommended = true;
            } else if (product.id == BillingService.creditsLarge) {
              title = 'Large Pack';
              credits = 500;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildCoinPack(
                title: title,
                credits: credits,
                price: product.price,
                isRecommended: isRecommended,
                product: product,
              ),
            );
          }),
          if (_creditProducts.isEmpty)
            const Text('No credit packs available.'),
        ],
      ),
    );
  }

  Widget _buildCoinPack({
    required String title,
    required int credits,
    required String price,
    required ProductDetails product,
    bool isRecommended = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isRecommended ? Colors.deepPurple : Colors.grey.shade200, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('$credits Credits', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => BillingService().buyProduct(product),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRecommended ? Colors.deepPurple : Colors.grey.shade100,
              foregroundColor: isRecommended ? Colors.white : Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
