import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../ads/app_state.dart';
import '../daily_credit_manager.dart';

class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // Product IDs
  static const String planStandard = 'plan_standard';
  static const String planPremium = 'plan_premium';
  static const String planArchitect = 'plan_architect';

  static const String creditsSmall = 'credits_pack_small';
  static const String creditsMedium = 'credits_pack_medium';
  static const String creditsLarge = 'credits_pack_large';

  static const Set<String> _subscriptionIds = {
    planStandard,
    planPremium,
    planArchitect,
  };

  static const Set<String> _consumableIds = {
    creditsSmall,
    creditsMedium,
    creditsLarge,
  };

  static const Set<String> allIds = {
    ..._subscriptionIds,
    ..._consumableIds,
  };

  /// Initialize billing and start listening to purchases
  void init() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) {
        debugPrint('❌ BillingService Error: $error');
      },
    );
  }

  void dispose() {
    _subscription.cancel();
  }

  /// Handle incoming purchase updates
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        // Show pending UI if needed
        debugPrint('⏳ Purchase Pending: ${purchase.productID}');
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('❌ Purchase Error: ${purchase.error}');
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.purchased || 
                 purchase.status == PurchaseStatus.restored) {
        
        await _handleSuccessfulPurchase(purchase);
      }
    }
  }

  /// Process successful purchases or restores
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    final String productId = purchase.productID;
    debugPrint('✅ Processing Success: $productId');

    // 1. Handle Subscriptions
    if (_subscriptionIds.contains(productId)) {
      PlanTier tier = PlanTier.free;
      if (productId == planStandard) tier = PlanTier.standard;
      if (productId == planPremium) tier = PlanTier.premium;
      if (productId == planArchitect) tier = PlanTier.architect;

      if (tier != PlanTier.free) {
        await AppState.updatePlanTier(tier);
      }
    }

    // 2. Handle Consumables (Credits)
    if (_consumableIds.contains(productId)) {
      int amount = 0;
      if (productId == creditsSmall) amount = 50;
      if (productId == creditsMedium) amount = 150;
      if (productId == creditsLarge) amount = 500;

      if (amount > 0) {
        await DailyCreditManager.addCredits(amount);
      }
    }

    // 3. Complete the purchase
    if (purchase.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchase);
      debugPrint('🏁 Purchase Completed: $productId');
    }
  }

  /// Fetch product details from store
  Future<List<ProductDetails>> getProducts(Set<String> ids) async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      debugPrint('❌ Store not available');
      return [];
    }
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(ids);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('⚠️ Products not found: ${response.notFoundIDs}');
    }
    return response.productDetails;
  }

  /// Start purchase flow
  Future<void> buyProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    if (_consumableIds.contains(product.id)) {
      await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    } else {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }
}
