import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/credit_controller.dart';
import '../screens/premium/pro_screen.dart';
import '../navigation/app_navigator.dart';

class DailyCreditBadge extends StatelessWidget {
  final Color themeColor;

  const DailyCreditBadge({
    super.key,
    this.themeColor = Colors.indigo,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final credits = CreditController.to.userCoins.value;
      return GestureDetector(
        onTap: () => AppNavigator.push(context, const ProScreen(from: "credits")),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: themeColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 14,
                color: themeColor,
              ),
              const SizedBox(width: 4),
              Text(
                '$credits Credits',
                style: TextStyle(
                  color: themeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
