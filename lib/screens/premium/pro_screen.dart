import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../home/home_screen.dart';
import 'purchase_loading_screen.dart';

import '../../services/credit_controller.dart';
import '../../services/firebase_analytics_service.dart';
import '../../services/remote_config_controller.dart';

import '../../utils/app_constant.dart';
import '../../widgets/CustomPressButton.dart';
import '../../utils/tester_workflow.dart';

class ProScreen extends StatefulWidget {
  final String from;
  final bool isFromInsufficientCoins;
  final int initialTabIndex;

  const ProScreen({
    super.key,
    required this.from,
    this.isFromInsufficientCoins = false,
    this.initialTabIndex = 0,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  int creditPlanIndex = 0;
  int premiumPlanIndex = 0;
  bool isLoading = true;
  late bool _isCreditPlan;

  Map<String, Package>? availablePackages;
  Package? selectedCreditPackage;
  Package? selectedPremiumPackage;
  
  Package? firstCoinPackage;
  Package? secondCoinPackage;
  Package? thirdCoinPackage;
  Package? fourthCoinPackage;
  Package? fifthCoinPackage;
  Package? sixthCoinPackage;

  Package? weeklyPackage;
  Package? yearlyPackage;
  
  Offerings? _offerings;

  @override
  void initState() {
    super.initState();
    _isCreditPlan = widget.initialTabIndex == 0;
    FirebaseAnalyticsService.logScreenView('pro');
    FirebaseAnalyticsService.logEvent(eventName: "CREDIT_PREMIUM_SCREEN");
    
    // Initialize indexes based on current config
    _initializeIndexes();
    callFirst();
  }

  void _initializeIndexes() {
    final selectedCredit = AdsVariable.selectedCreditPlan;
    final selectedPremium = AdsVariable.selectedPremiumPlan;

    if (selectedCredit == AppConstant.firstCoinIdentifier) creditPlanIndex = 0;
    else if (selectedCredit == AppConstant.secondCoinIdentifier) creditPlanIndex = 1;
    else if (selectedCredit == AppConstant.thirdCoinIdentifier) creditPlanIndex = 2;
    else if (selectedCredit == AppConstant.fourthCoinIdentifier) creditPlanIndex = 3;
    else if (selectedCredit == AppConstant.fifthCoinIdentifier) creditPlanIndex = 4;
    else if (selectedCredit == AppConstant.sixthCoinIdentifier) creditPlanIndex = 5;

    if (selectedPremium == AppConstant.weeklyIdentifier) premiumPlanIndex = 0;
    else premiumPlanIndex = 1;
  }

  Future<void> callFirst() async {
    bool connected = await AdsVariable.isInternetConnected();
    if (connected) {
      // Always fetch regardless of isConfigured state — RevenueCat handles caching
      await fetchData();
    } else {
      debugPrint("[ProScreen]: No internet connection. Cannot fetch offerings.");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchData() async {
    debugPrint("[ProScreen]: fetchData() called.");
    try {
      _offerings = await Purchases.getOfferings();
      debugPrint("[ProScreen]: Offerings fetched. Current: ${_offerings?.current?.identifier}");
      
      if (_offerings?.current != null) {
        availablePackages = {
          for (var package in _offerings!.current!.availablePackages)
            package.storeProduct.identifier: package,
        };
        debugPrint("[ProScreen]: Available packages: ${availablePackages?.keys.toList()}");

        firstCoinPackage = _getPackageById(AppConstant.firstCoinIdentifier);
        secondCoinPackage = _getPackageById(AppConstant.secondCoinIdentifier);
        thirdCoinPackage = _getPackageById(AppConstant.thirdCoinIdentifier);
        fourthCoinPackage = _getPackageById(AppConstant.fourthCoinIdentifier);
        fifthCoinPackage = _getPackageById(AppConstant.fifthCoinIdentifier);
        sixthCoinPackage = _getPackageById(AppConstant.sixthCoinIdentifier);
        
        weeklyPackage = _getPackageById(AppConstant.weeklyIdentifier);
        yearlyPackage = _getPackageById(AppConstant.yearlyIdentifier);

        debugPrint("[ProScreen]: Weekly: $weeklyPackage, Yearly: $yearlyPackage");

        // Set default selected packages
        selectedCreditPackage = _getPackageById(AdsVariable.selectedCreditPlan);
        selectedPremiumPackage = _getPackageById(AdsVariable.selectedPremiumPlan);
        
        if (mounted) setState(() => isLoading = false);
      } else {
        // current offering is null — show UI without packages
        debugPrint("[ProScreen]: ⚠️ _offerings.current is NULL! No packages to show.");
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("[ProScreen]: ❌ ERROR fetchData: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Package? _getPackageById(String identifier) {
    if (availablePackages == null) return null;
    return availablePackages![identifier];
  }

  Future<void> creditContinueTap() async {
    // if (AdsVariable.isSendAppInMaintenance) {
    //   FirebaseAnalyticsService.logEvent(eventName: "APP_IN_MAINTENANCE");
    //   return;
    // }
    
    if (selectedCreditPackage == null) return;
    
    purchaseLoadingScreen.show();

    try {
      await Purchases.purchasePackage(selectedCreditPackage!);
      initPlatformStateCredit();
    } on PlatformException catch (e) {
      purchaseLoadingScreen.hide();
      debugPrint('Purchase error: ${e.message}');
    } catch (_) {
      purchaseLoadingScreen.hide();
    }
  }

  Future<void> initPlatformStateCredit() async {
    final customerInfo = await Purchases.getCustomerInfo();
    if (customerInfo.entitlements.all[AppConstant.entitlementKey]?.isActive == true) {
      final creditController = CreditController.to;
      int purchasedCoins = int.parse(getCreditByIndex(creditPlanIndex));

      FirebaseAnalyticsService.logEvent(
        eventName: 'purchase_coins',
        parameters: {
          'coins': purchasedCoins,
          'plan_id': AdsVariable.selectedCreditPlan,
        },
      );

      await creditController.addCoins(purchasedCoins);
      purchaseLoadingScreen.hide();
      
      if (widget.from == "splash") {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) Navigator.pop(context);
      }
    } else {
      purchaseLoadingScreen.hide();
    }
  }

  Future<void> premiumContinueTap() async {
    // if (AdsVariable.isSendAppInMaintenance) {
    //   FirebaseAnalyticsService.logEvent(eventName: "APP_IN_MAINTENANCE");
    //   return;
    // }
    
    if (selectedPremiumPackage == null) return;
    
    purchaseLoadingScreen.show();

    try {
      await Purchases.purchasePackage(selectedPremiumPackage!);
      initPlatformStatePremium();
    } on PlatformException catch (_) {
      purchaseLoadingScreen.hide();
    } catch (_) {
      purchaseLoadingScreen.hide();
    }
  }

  Future<void> initPlatformStatePremium() async {
    final customerInfo = await Purchases.getCustomerInfo();
    if (customerInfo.entitlements.all[AppConstant.entitlementKey]?.isActive == true) {
      final creditController = CreditController.to;
      int bonusCoins = 0;
      String planName = "";

      if (premiumPlanIndex == 0) {
        bonusCoins = int.parse(AdsVariable.weeklyBonusCredit);
        planName = "Weekly";
      } else {
        bonusCoins = int.parse(AdsVariable.yearlyBonusCredit);
        planName = "Yearly";
      }

      FirebaseAnalyticsService.logEvent(
        eventName: 'purchase_plan',
        parameters: {'plan': planName},
      );

      await creditController.updatePremiumStatus(
        true,
        addCoins: bonusCoins,
        plan: planName,
      );

      purchaseLoadingScreen.hide();
      if (widget.from == "splash") {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) Navigator.pop(context);
      }
    } else {
      purchaseLoadingScreen.hide();
    }
  }

  String getCreditByIndex(int index) {
    switch (index) {
      case 0: return AdsVariable.firstCoinPlan;
      case 1: return AdsVariable.secondCoinPlan;
      case 2: return AdsVariable.thirdCoinPlan;
      case 3: return AdsVariable.fourthCoinPlan;
      case 4: return AdsVariable.fifthCoinPlan;
      case 5: return AdsVariable.sixthCoinPlan;
      default: return AdsVariable.firstCoinPlan;
    }
  }

  double calculateDiscount({required int credit, required double price}) {
    double firstPrice = firstCoinPackage?.storeProduct.price ?? 0;
    int firstCredits = int.tryParse(AdsVariable.firstCoinPlan) ?? 0;
    if (firstPrice == 0 || firstCredits == 0 || credit == 0) return 0;
    double perCoinChargeForFirstPackage = firstPrice / firstCredits;
    double perCoinChargeForCurrentPackage = price / credit;
    double rawDiscount = (100 - ((perCoinChargeForCurrentPackage * 100) / perCoinChargeForFirstPackage));
    return rawDiscount > 0 ? rawDiscount : 0;
  }

  double calculateDiscountForPremiumPlan({required double weeklyPrice, required double yearlyPrice}) {
    if (weeklyPrice == 0) return 0;
    double weekPriceForYearlyPurchase = yearlyPrice / 52;
    double rawDiscount = (100 - ((weekPriceForYearlyPurchase * 100) / weeklyPrice));
    return rawDiscount > 0 ? rawDiscount : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              _buildTopSection(),
              _buildActivePlanInfo(),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _isCreditPlan ? _buildCreditGrid() : _buildPremiumList(),
                ),
              ),
              const SizedBox(height: 100), // Space for bottom button
            ],
          ),
          _buildCloseButton(),
          _buildBottomActionSection(),
        ],
      ),
    );
  }


  Widget _buildTopSection() {
    return Stack(
      children: [
        // Premium gradient background (replaces missing asset)
        Container(
          height: MediaQuery.of(context).size.height * 0.45,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A0033),
                Color(0xFF3D0B72),
                Color(0xFF6A1FA0),
                Color(0xFF3D0B72),
              ],
              stops: [0.0, 0.35, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles for depth
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepPurpleAccent.withOpacity(0.2),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purple.withOpacity(0.15),
                  ),
                ),
              ),
              // Center icon
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, size: 52, color: Colors.amber),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Archify Pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Unlock unlimited AI power',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Bottom fade overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.8), Colors.black],
                stops: const [0.0, 0.5, 0.85, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 15,
          child: _buildPlanSwitcher(),
        ),
      ],
    );
  }

  Widget _buildPlanSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            _buildSwitcherTab('Credit Plan', _isCreditPlan, () => setState(() => _isCreditPlan = true)),
            _buildSwitcherTab('Premium Plan', !_isCreditPlan, () => setState(() => _isCreditPlan = false)),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitcherTab(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.black : Colors.white60,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivePlanInfo() {
    return GetBuilder<CreditController>(
      id: 'premium_status',
      builder: (controller) {
        if (!_isCreditPlan && controller.isPremium.value && controller.activePlan.value.isNotEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF6EC531).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6EC531).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF6EC531), size: 20),
                const SizedBox(width: 8),
                Text(
                  "Active Plan: ${controller.activePlan.value}",
                  style: GoogleFonts.poppins(color: const Color(0xFF6EC531), fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCreditGrid() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 15,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        Package? pkg;
        switch (index) {
          case 0: pkg = firstCoinPackage; break;
          case 1: pkg = secondCoinPackage; break;
          case 2: pkg = thirdCoinPackage; break;
          case 3: pkg = fourthCoinPackage; break;
          case 4: pkg = fifthCoinPackage; break;
          case 5: pkg = sixthCoinPackage; break;
        }
        return _buildCreditItem(pkg, index);
      },
    );
  }

  Widget _buildCreditItem(Package? package, int index) {
    bool isSelected = creditPlanIndex == index;
    String credits = getCreditByIndex(index);
    String price = package?.storeProduct.priceString ?? "-";
    double discount = calculateDiscount(credit: int.parse(credits), price: package?.storeProduct.price ?? 0);

    return GestureDetector(
      onTap: () => setState(() {
        creditPlanIndex = index;
        selectedCreditPackage = package;
      }),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSelected ? Colors.deepPurpleAccent : Colors.white10, width: isSelected ? 2 : 1),
              color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.amber, size: 30),
                const SizedBox(height: 8),
                Text("$credits Credits", style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(price, style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          if (discount.round() > 5 && index > 0)
            Positioned(
              right: 4, top: -8,
              child: _buildDiscountBadge(discount.round()),
            ),
        ],
      ),
    );
  }

  Widget _buildDiscountBadge(int discount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.deepPurpleAccent, borderRadius: BorderRadius.circular(10)),
      child: Text("-$discount%", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPremiumList() {
    return Column(
      children: [
        _buildPremiumItem(weeklyPackage, 0),
        const SizedBox(height: 16),
        _buildPremiumItem(yearlyPackage, 1),
        const SizedBox(height: 20),
        _buildPremiumBenefits(),
      ],
    );
  }

  Widget _buildPremiumItem(Package? package, int index) {
    bool isSelected = premiumPlanIndex == index;
    String title = index == 0 ? "Weekly Plan" : "Yearly Plan";
    String credits = index == 0 ? AdsVariable.weeklyBonusCredit : AdsVariable.yearlyBonusCredit;
    String price = package?.storeProduct.priceString ?? "-";

    return GestureDetector(
      onTap: () => setState(() {
        premiumPlanIndex = index;
        selectedPremiumPackage = package;
      }),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? Colors.deepPurpleAccent : Colors.white10, width: 2),
          color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("$credits Credits included", style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14)),
                ],
              ),
            ),
            Text(price, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBenefits() {
    return Column(
      children: [
        _benefitItem(Icons.bolt_rounded, "Unlimited AI Transformations"),
        _benefitItem(Icons.hd_rounded, "HD Quality Results"),
        _benefitItem(Icons.speaker_notes_off_rounded, "No Advertisements"),
      ],
    );
  }

  Widget _benefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurpleAccent, size: 20),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildBottomActionSection() {
    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPressButton(
              onTap: _isCreditPlan ? creditContinueTap : premiumContinueTap,
              borderRadius: 32,
              child: Container(
                height: 60, width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8A2BE2), Color(0xFF4B0082)]),
                  borderRadius: BorderRadius.circular(32),
                ),
                alignment: Alignment.center,
                child: Text(
                  _isCreditPlan ? 'Get Credits' : 'Subscribe Now',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (AdsVariable.isShowIAmTester && widget.isFromInsufficientCoins) ...[
              const SizedBox(height: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  debugPrint("Tester button tapped");
                  debugPrint(
                      "Email: ${AdsVariable.testEmail}, Pass: ${AdsVariable.testPassword}");
                  TesterWorkflow.show(
                    context,
                    onSuccess: () async {
                      // Success logic (bypass is activated in DailyCreditManager)
                    },
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.deepPurpleAccent.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'I am Tester',
                    style: GoogleFonts.poppins(
                        color: Colors.deepPurpleAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _footerLink('Terms of Use', () {}),
                const SizedBox(width: 20),
                _footerLink('Privacy Policy', () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(text, style: const TextStyle(color: Colors.white38, fontSize: 12)),
    );
  }

}
