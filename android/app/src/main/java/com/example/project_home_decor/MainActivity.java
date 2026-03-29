package com.example.project_home_decor;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin;

public class MainActivity extends FlutterActivity {

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // ✅ Register Native Ad Factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
                flutterEngine,
                "listTile", // MUST match Flutter NativeAd.factoryId
                new NativeAdFactoryExample(this));
    }

    @Override
    public void cleanUpFlutterEngine(FlutterEngine flutterEngine) {
        // ✅ Important to avoid memory leak
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
                flutterEngine,
                "listTile");
        super.cleanUpFlutterEngine(flutterEngine);
    }
}
