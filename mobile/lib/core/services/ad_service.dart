import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  RewardedAd? _preloadedAd;
  bool _isLoadingPreload = false;

  // Production Google AdMob Rewarded Ad Unit IDs
  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-6882482812110955/8705983307'; // Production Android rewarded ad ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-6882482812110955/8705983307'; // Production iOS rewarded ad ID
    }
    return '';
  }

  /// Safely initialize Google Mobile Ads SDK (avoids crashing on Web/unsupported platforms).
  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('[AdService] Google Mobile Ads is not supported on web; using simulator fallback.');
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      preloadRewardedAd();
      debugPrint('[AdService] Google Mobile Ads SDK initialized successfully.');
    } catch (e) {
      debugPrint('[AdService] MobileAds initialize error: $e');
    }
  }

  /// Pre-loads a rewarded ad so it displays with zero delay when requested.
  void preloadRewardedAd() {
    if (kIsWeb || !_isInitialized || _isLoadingPreload || _preloadedAd != null) return;
    final adUnitId = rewardedAdUnitId;
    if (adUnitId.isEmpty) return;

    _isLoadingPreload = true;
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _preloadedAd = ad;
          _isLoadingPreload = false;
          debugPrint('[AdService] RewardedAd preloaded successfully in background.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _preloadedAd = null;
          _isLoadingPreload = false;
          debugPrint('[AdService] RewardedAd preload failed: $error');
        },
      ),
    );
  }

  /// Attempts to display a real Google AdMob Rewarded Video ad.
  /// If it succeeds and the user watches the entire video: calls [onUserEarnedReward].
  /// If the user dismisses/skips before completion: calls [onAdDismissedWithoutReward].
  /// If loading or showing fails: calls [onAdFailed].
  void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    required VoidCallback onAdDismissedWithoutReward,
    required void Function(String error) onAdFailed,
  }) {
    if (kIsWeb || !_isInitialized) {
      onAdFailed('AdMob is not available on this platform. Falling back to in-app player.');
      return;
    }

    final adUnitId = rewardedAdUnitId;
    if (adUnitId.isEmpty) {
      onAdFailed('Ad unit ID not found.');
      return;
    }

    // If preloaded ad is ready, use it immediately
    if (_preloadedAd != null) {
      final ad = _preloadedAd!;
      _preloadedAd = null;
      _presentAd(
        ad: ad,
        onUserEarnedReward: onUserEarnedReward,
        onAdDismissedWithoutReward: onAdDismissedWithoutReward,
        onAdFailed: onAdFailed,
      );
      return;
    }

    // Otherwise load on-demand
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _presentAd(
            ad: ad,
            onUserEarnedReward: onUserEarnedReward,
            onAdDismissedWithoutReward: onAdDismissedWithoutReward,
            onAdFailed: onAdFailed,
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdService] RewardedAd failed to load: $error');
          preloadRewardedAd();
          onAdFailed(error.message);
        },
      ),
    );
  }

  void _presentAd({
    required RewardedAd ad,
    required VoidCallback onUserEarnedReward,
    required VoidCallback onAdDismissedWithoutReward,
    required void Function(String error) onAdFailed,
  }) {
    bool rewardEarned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        debugPrint('[AdService] Ad showed full screen content.');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('[AdService] Ad dismissed full screen content. Reward earned: $rewardEarned');
        ad.dispose();
        preloadRewardedAd(); // Preload next ad in background
        if (!rewardEarned) {
          onAdDismissedWithoutReward();
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('[AdService] Ad failed to show: $error');
        ad.dispose();
        preloadRewardedAd();
        onAdFailed(error.message);
      },
    );

    ad.setImmersiveMode(true);
    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('[AdService] User earned reward: ${reward.amount} ${reward.type}');
        rewardEarned = true;
        onUserEarnedReward();
      },
    );
  }
}
