package com.example.project_home_decor;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.RatingBar;
import android.widget.TextView;

import com.google.android.gms.ads.nativead.MediaView;
import com.google.android.gms.ads.nativead.NativeAd;
import com.google.android.gms.ads.nativead.NativeAdView;

import java.util.Map;

import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin;

public class NativeAdFactoryExample implements GoogleMobileAdsPlugin.NativeAdFactory {

    private final Context context;

    public NativeAdFactoryExample(Context context) {
        this.context = context;
    }

    @Override
    public NativeAdView createNativeAd(
            NativeAd nativeAd,
            Map<String, Object> customOptions) {

        NativeAdView adView = (NativeAdView) LayoutInflater.from(context)
                .inflate(R.layout.native_ad_layout, null);

        // Views
        TextView headline = adView.findViewById(R.id.ad_headline);
        TextView body = adView.findViewById(R.id.ad_body);
        Button cta = adView.findViewById(R.id.ad_call_to_action);
        ImageView icon = adView.findViewById(R.id.ad_app_icon);
        RatingBar ratingBar = adView.findViewById(R.id.ad_stars);
        MediaView mediaView = adView.findViewById(R.id.native_ad_media);

        // HEADLINE (REQUIRED)
        headline.setText(nativeAd.getHeadline());
        adView.setHeadlineView(headline);

        // BODY
        if (nativeAd.getBody() != null) {
            body.setText(nativeAd.getBody());
            body.setVisibility(View.VISIBLE);
            adView.setBodyView(body);
        } else {
            body.setVisibility(View.GONE);
        }

        // CTA
        if (nativeAd.getCallToAction() != null) {
            cta.setText(nativeAd.getCallToAction());
            cta.setVisibility(View.VISIBLE);
            adView.setCallToActionView(cta);
        } else {
            cta.setVisibility(View.GONE);
        }

        // ICON
        if (nativeAd.getIcon() != null) {
            icon.setImageDrawable(nativeAd.getIcon().getDrawable());
            icon.setVisibility(View.VISIBLE);
            adView.setIconView(icon);
        } else {
            icon.setVisibility(View.GONE);
        }

        // RATING
        if (nativeAd.getStarRating() != null) {
            ratingBar.setRating(nativeAd.getStarRating().floatValue());
            ratingBar.setVisibility(View.VISIBLE);
            adView.setStarRatingView(ratingBar);
        } else {
            ratingBar.setVisibility(View.GONE);
        }

        // MEDIA
        adView.setMediaView(mediaView);

        // FINAL REQUIRED CALL
        adView.setNativeAd(nativeAd);

        return adView;
    }
}
