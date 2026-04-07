import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../services/firebase_analytics_service.dart';

@protected
final scaffoldGlobalKey = GlobalKey<ScaffoldState>();

class PurchaseLoadingScreen {
  final GlobalKey globalKey;

  PurchaseLoadingScreen(this.globalKey);

  void show([String? text]) {
    FirebaseAnalyticsService.logScreenView('purchase_loading');
    showDialog<String>(
      context: Get.context!,
      builder: (BuildContext context) => Scaffold(
        backgroundColor: const Color.fromRGBO(0, 0, 0, 0.3),
        body: SizedBox.expand(
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  CupertinoActivityIndicator(color: Colors.white, radius: 50.r),
                  SizedBox(height: 50.h),
                  text == null
                      ? const Text(
                          "Processing...",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        )
                      : Text(
                          text.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48.sp,
                          ),
                        ).marginSymmetric(horizontal: 50.w, vertical: 5.w),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void hide() {
    if (Get.context == null) return;
    Navigator.pop(Get.context!);
  }
}

@protected
var purchaseLoadingScreen = PurchaseLoadingScreen(scaffoldGlobalKey);
