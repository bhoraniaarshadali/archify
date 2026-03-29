import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showToast(String msg) {
  Get.snackbar(
    "Notification",
    msg,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.black87,
    colorText: Colors.white,
    margin: const EdgeInsets.all(16),
    borderRadius: 8,
    duration: const Duration(seconds: 2),
  );
}
