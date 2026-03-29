import 'package:flutter/material.dart';
import '../services/daily_credit_manager.dart';
import '../ads/app_state.dart';

class DailyCreditBadge extends StatelessWidget {
  final Color themeColor;

  const DailyCreditBadge({
    super.key,
    this.themeColor = Colors.indigo,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, _) {
        final bool isPremium = AppState.isPremiumUser;

        if (isPremium) {
          return _buildProBadge();
        }

        return ValueListenableBuilder<int>(
          valueListenable: DailyCreditManager.creditsNotifier,
          builder: (context, credits, child) {
            return Container(
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
            );
          },
        );
      },
    );
  }

  Widget _buildProBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: 14,
            color: Colors.black,
          ),
          SizedBox(width: 4),
          Text(
            'PRO',
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
