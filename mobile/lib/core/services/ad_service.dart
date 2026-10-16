import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Official Google Sample / Test Ad Unit IDs
  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Official Android test rewarded ad ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Official iOS test rewarded ad ID
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
      debugPrint('[AdService] Google Mobile Ads SDK initialized successfully.');
    } catch (e) {
      debugPrint('[AdService] MobileAds initialize error: $e');
    }
  }

  /// Attempts to load and display a real Google AdMob Rewarded Video ad.
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

    bool rewardEarned = false;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('[AdService] RewardedAd loaded successfully.');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (RewardedAd ad) {
              debugPrint('[AdService] Ad showed full screen content.');
            },
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              debugPrint('[AdService] Ad dismissed full screen content. Reward earned: $rewardEarned');
              ad.dispose();
              if (!rewardEarned) {
                onAdDismissedWithoutReward();
              }
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              debugPrint('[AdService] Ad failed to show: $error');
              ad.dispose();
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
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdService] RewardedAd failed to load: $error');
          onAdFailed(error.message);
        },
      ),
    );
  }
}
