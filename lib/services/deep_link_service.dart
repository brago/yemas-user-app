import 'package:app_links/app_links.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/screens/auth/sign_in_screen.dart';
import 'package:booking_system_flutter/screens/dashboard/dashboard_screen.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:nb_utils/nb_utils.dart';

import '../utils/configs.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();

  factory DeepLinkService() => _instance;

  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  String? _pendingReferralCode;
  bool _isInitialized = false;

  /// Initialize deep link listener
  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Handle initial link (when app is opened from a link)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      log('Deep link error: $err');
    });
  }

  /// Handle deep link
 /* void _handleDeepLink(Uri uri) {
    log('Deep link received: $uri');

    String? referralCode;


    if (uri.scheme == 'handyman' && uri.host == 'app') {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'referral') {
        referralCode = uri.queryParameters['code'];
      }
    }
    else if (uri.scheme == 'http' || uri.scheme == 'https') {
      if (uri.host == 'laratest.iqonic.design' || uri.host.contains('iqonic.design') || uri.host == '192.168.1.166' || uri.host.contains('handyman')) {
        if (uri.path.contains('referral') || uri.pathSegments.contains('referral')) {
          referralCode = uri.queryParameters['code'];
        }
      }
    }

    if (referralCode != null && referralCode.isNotEmpty) {
      log('Referral code extracted: $referralCode');
      _pendingReferralCode = referralCode;
      _navigateToReferral(referralCode);
    } else {
      log('No referral code found in deep link');
    }
  }*/
  void _handleDeepLink(Uri uri) {
    log('Deep link received: $uri');

    String? referralCode;

    // 1. App scheme: handyman://app/referral?code=XXXX
    if (uri.scheme == 'handyman' && uri.host == 'app') {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'referral') {
        referralCode = uri.queryParameters['code'] ?? uri.queryParameters['ref'];
      }
    }
    // 2. HTTP / HTTPS links
    else if (uri.scheme == 'http' || uri.scheme == 'https') {
      // Host from DOMAIN_URL (e.g. https://apps.iqonic.design)
      String configuredHost = '';
      try {
        configuredHost = Uri.parse(DOMAIN_URL).host; // from constant.dart
      } catch (e) {
        log('Error parsing DOMAIN_URL: $e');
      }

      final host = uri.host;

      // Is this link from our configured domain?
      final bool isFromConfiguredDomain = configuredHost.isNotEmpty && host == configuredHost;

      // (Optional) keep support for old/local domains if you still need them
      final bool isFromKnownDevDomain =
          host == '192.168.1.166' || host.contains('iqonic.design') || host.contains('handyman');

      if (isFromConfiguredDomain || isFromKnownDevDomain) {
        // New format: /handyman/register-page?ref=XXXX
        // Old format: /handyman?code=XXXX
        final segments = uri.pathSegments; // e.g. ['handyman', 'register-page']

        final bool isRegisterPage = segments.contains('register-page');
        final bool isHandymanRoot = segments.length == 1 && segments.first == 'handyman';
        final bool isReferralPath = segments.contains('referral') || uri.path.contains('referral');

        if (isRegisterPage || isHandymanRoot || isReferralPath) {
          // Prefer new param `ref`, but still accept `code` for backward compatibility
          referralCode = uri.queryParameters['ref'] ?? uri.queryParameters['code'];
        }
      }
    }

    if (referralCode != null && referralCode.isNotEmpty) {
      log('Referral code extracted: $referralCode');
      _pendingReferralCode = referralCode;
      _navigateToReferral(referralCode);
    } else {
      log('No referral code found in deep link');
    }
  }

  /// Navigate based on referral code and auth state
  void _navigateToReferral(String referralCode) {
    setValue(PENDING_REFERRAL_CODE, referralCode);
    _pendingReferralCode = referralCode;

    Future.delayed(const Duration(milliseconds: 1000), () {
      _performNavigation(referralCode);
    });
  }

  /// Perform navigation after app is ready
  void _performNavigation(String referralCode) {
    final context = navigatorKey.currentContext;
    if (context == null) {

      log('Deep link: Context not available yet, referral code saved: $referralCode');
      return;
    }


    if (appStore.isLoggedIn) {
      DashboardScreen().launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      toast('Referral code received: $referralCode');
    } else {
      SignInScreen().launch(context, isNewTask: true, pageRouteAnimation: PageRouteAnimation.Fade);
      toast('Referral code received: $referralCode. Use it during sign up!');
    }
  }

  /// Get pending referral code and clear it
  String? getPendingReferralCode() {
    final code = _pendingReferralCode ?? getStringAsync(PENDING_REFERRAL_CODE);
    if (code.isNotEmpty) {
      _pendingReferralCode = null;
      removeKey(PENDING_REFERRAL_CODE);
    }
    return code;
  }

  /// Clear pending referral code
  void clearPendingReferralCode() {
    _pendingReferralCode = null;
    removeKey(PENDING_REFERRAL_CODE);
  }
}
