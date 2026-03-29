import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../models/interior_style_model.dart';
import '../remote_config_controller.dart';

class InteriorStylesRepository {
  static Future<List<InteriorStyle>> loadStyles() async {
    // 1. Try Remote Config first (via Get)
    try {
      final remoteConfigController = Get.find<RemoteConfigController>();
      final remoteStyles = remoteConfigController.adsVariable.value.interiorStyles;
      
      if (remoteStyles.isNotEmpty) {
        return remoteStyles
            .where((e) => e['type'] == 'interior')
            .map((e) => InteriorStyle.fromJson(e))
            .toList();
      }
    } catch (e) {
      print("Remote config styles fetch error: $e");
    }

    // 2. Fallback to assets
    final jsonString =
        await rootBundle.loadString('assets/json/interior_styles.json');

    final List data = json.decode(jsonString);

    return data
        .where((e) => e['type'] == 'interior')
        .map((e) => InteriorStyle.fromJson(e))
        .toList();
  }
}
