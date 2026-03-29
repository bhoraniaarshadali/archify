import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdWidget extends StatelessWidget {
  final NativeAd nativeAd;
  final double height;

  const NativeAdWidget({super.key, required this.nativeAd, this.height = 260});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AdWidget(ad: nativeAd),
    );
  }
}
