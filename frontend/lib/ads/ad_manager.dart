import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  AdManager._();

  static final AdManager instance = AdManager._();

  RewardedAd? _lifeRewardedAd;
  bool _initialized = false;
  bool _loadingReward = false;

  bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_initialized || !isSupported) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  Future<void> preloadLifeRewardAd() async {
    if (!isSupported) return;
    await initialize();
    await _loadLifeRewardedAd();
  }

  Future<bool> showLifeRewardAd() async {
    if (!isSupported) return false;
    await initialize();
    if (_lifeRewardedAd == null) {
      await _loadLifeRewardedAd();
    }
    final ad = _lifeRewardedAd;
    if (ad == null) return false;

    final completer = Completer<bool>();
    var earnedReward = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _lifeRewardedAd = null;
        _loadLifeRewardedAd();
        if (!completer.isCompleted) completer.complete(earnedReward);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _lifeRewardedAd = null;
        _loadLifeRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    ad.show(
      onUserEarnedReward: (_, __) {
        earnedReward = true;
      },
    );
    _lifeRewardedAd = null;
    return completer.future;
  }

  Future<void> _loadLifeRewardedAd() async {
    if (_lifeRewardedAd != null || _loadingReward) return;
    _loadingReward = true;
    try {
      await RewardedAd.load(
        adUnitId: _lifeRewardAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _lifeRewardedAd = ad;
          },
          onAdFailedToLoad: (error) {
            _lifeRewardedAd = null;
          },
        ),
      );
    } finally {
      _loadingReward = false;
    }
  }

  String get _lifeRewardAdUnitId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ca-app-pub-3940256099942544/5224354917'; // Test rewarded
      case TargetPlatform.iOS:
        return 'ca-app-pub-3940256099942544/1712485313'; // Test rewarded
      default:
        return 'test';
    }
  }
}
