import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../ads/nativeAds/reel_native_ad_helper.dart';

class ReelAdItem extends StatefulWidget {
  final ReelNativeAdHelper adHelper;
  const ReelAdItem({super.key, required this.adHelper});

  @override
  State<ReelAdItem> createState() => _ReelAdItemState();
}

class _ReelAdItemState extends State<ReelAdItem> {
  @override
  void initState() {
    super.initState();
    // Start loading the ad as soon as the item is created if not already
    if (!widget.adHelper.isAdLoaded && !widget.adHelper.isAdLoading) {
      widget.adHelper.loadAd(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: AnimatedBuilder(
        animation: widget.adHelper,
        builder: (context, _) {
          if (widget.adHelper.isAdLoaded && widget.adHelper.nativeAd != null) {
            return Center(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: AdWidget(ad: widget.adHelper.nativeAd!),
              ),
            );
          } else if (widget.adHelper.lastError != null) {
             // If there's an error, we should technically not show this item,
             // handled in parent (skip).
             return const Center(child: Text(''));
          } else {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
        },
      ),
    );
  }
}
