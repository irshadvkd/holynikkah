import 'package:flutter/foundation.dart';

/// Centralized app-wide constants.
/// Use this to access URLs, asset paths, themes, icons, etc.
final class AppConstants {
  const AppConstants._(); // private constructor (prevent instantiation)

  /// Set to `true` to print console logs even in release mode.
  /// Can also be overridden at build time via: `--dart-define=ENABLE_RELEASE_LOGS=true`
  static const bool enableReleaseLogs = bool.fromEnvironment(
    'ENABLE_RELEASE_LOGS',
    defaultValue: true,
  );

  /// OTP digit count used across login and verification flows.
  static const int otpLength = 4;

  /// 🌐 API URLs
  static const urls = _Urls();

  /// 📁 Local asset JSON paths
  static const json = _JsonPaths();

  /// 🖼️ Icon asset paths
  static const icons = _IconPaths();

  /// 🌄 Image asset paths
  static const images = _ImagePaths();

  /// 🎨 Theme file paths
  static const themes = _ThemePaths();

  /// 🧩 Other useful app constants
  static const misc = _Misc();
}

final class _Urls {
  const _Urls();

  static const String _prodBase = 'https://console.holynikah.com/api';
  static const String _devBase = 'http://172.20.10.2:8000/api';

  static const String _prodImageBase = 'https://console.holynikah.com/';
  static const String _devImageBase = 'http://172.20.10.2:8000/';

  /// Base URL — no trailing slash.
  /// Uses local server in debug mode and production server in release mode.
  /// Can be overridden via: --dart-define=API_BASE_URL=...
  String get base {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    return kDebugMode ? _devBase : _prodBase;
  }

  /// Image base URL — with trailing slash.
  /// Uses local server in debug mode and production server in release mode.
  /// Can be overridden via: --dart-define=IMAGE_BASE_URL=...
  String get imageBaseUrl {
    const envUrl = String.fromEnvironment('IMAGE_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    return kDebugMode ? _devImageBase : _prodImageBase;
  }

  // Auth
  final String login = "/login/login";
  final String register = "/login/register";
  final String verifyEmail = "/verify-email";

  // Content
  final String reels = "/reels";
  final String reelsFeed = "/reels/feed";

  String reelsView(int reelId) => "/reels/$reelId/views";

  // Prayers
  final String prayersFeed = "/prayers/feed";

  String prayersView(int prayerId) => "/prayers/$prayerId/views";

  // Antiaging
  final String antiagingFeed = "/antiaging";
  String antiagingView(int id) => "/antiaging/$id/views";

  // Replenish Except His Own
  final String replenishFeed = "/replenish-except-his-own";
  String replenishView(int id) => "/replenish-except-his-own/$id/views";

  // Aura
  final String auraFeed = "/aura";
  String auraView(int id) => "/aura/$id/views";

  // Shadi Vibes
  final String shadiVibesFeed = "/shadi-vibes";
  String shadiVibesView(int id) => "/shadi-vibes/$id/views";
  final String shaadiVibesFeed = "/shadi-vibes";
  String shaadiVibesView(int id) => "/shadi-vibes/$id/views";

  // Space Ad 1 (Advertisement 1)
  final String spaceAd1Feed = "/advertisement1";
  String spaceAd1View(int id) => "/advertisement1/$id/views";

  // Space Ad 2 (Advertisement 2)
  final String spaceAd2Feed = "/advertisement2";
  String spaceAd2View(int id) => "/advertisement2/$id/views";

  // User
  final String userProfile = "/user/profile";

  // Legal Pages
  final String privacyPolicy = "/legal-pages/privacy-policy";
  final String termsAndConditions = "/legal-pages/terms-and-conditions";

  // Categories
  final String categories = "/categories";
  final String vipCategories = "/vip-categories";

  // Normal users
  final String normalOtpSend = "/normal-users/otp/send";
  final String normalOtpVerify = "/normal-users/otp/verify";
  final String normalUsersRegister = "/normal-users/register";
  final String normalCategorySelect = "/normal-users/category/select";
  final String normalUserDeleteAccount = "/normal-users/delete-account";

  // VIP OTP
  final String vipOtpSend = "/vip-users/otp/send";
  final String vipOtpResend = "/vip-users/otp/resend";
  final String vipOtpVerify = "/vip-users/otp/verify";
  final String vipUsersRegister = "/vip-users/register";
  final String vipCategorySelect = "/vip-users/category/select";
  final String vipUserDeleteAccount = "/vip-users/delete-account";

  /// Delete account endpoint for normal and VIP tiers
  String deleteAccount(bool isVip) => "${_savedPrefix(isVip)}/delete-account";

  // Locations
  final String locationStates = "/locations/states";
  final String locationDistricts = "/locations/districts";

  // Matches (matrimony feed) — tier-prefixed, authenticated.
  String matches(bool isVip) =>
      isVip ? "/vip-users/matches" : "/normal-users/matches";

  /// Request access to a match's contact info (`{profileId}`).
  String matchContactRequest(bool isVip, String profileId) =>
      "${matches(isVip)}/$profileId/contact-request";

  // Phone-visibility requests — tier-prefixed, authenticated.

  /// Create a phone request for a hidden profile (POST, body `{target_id}`).
  String phoneRequests(bool isVip) => "${_savedPrefix(isVip)}/phone-requests";

  /// Requests others made to view my phone (I can approve/reject these).
  String phoneRequestsIncoming(bool isVip) =>
      "${phoneRequests(isVip)}/incoming";

  /// Requests I made; approved ones reveal `target.phone`.
  String phoneRequestsOutgoing(bool isVip) =>
      "${phoneRequests(isVip)}/outgoing";

  /// Approve/reject an incoming phone request (`{requestId}`, body `{action}`).
  String phoneRequestRespond(bool isVip, String requestId) =>
      "${phoneRequests(isVip)}/$requestId/respond";

  // Templates (Server-Driven UI)
  final String templates = "/templates";

  String templateById(String id) => "/templates/$id";

  String templateAsset(String id) => "/templates/assets/$id";

  // Saved (user-filled) templates — tier-prefixed, authenticated.
  String _savedPrefix(bool isVip) => isVip ? "/vip-users" : "/normal-users";

  /// Persist the user's chosen template on the server (`{template_id}`).
  String templateSelect(bool isVip) => "${_savedPrefix(isVip)}/template/select";

  String savedTemplates(bool isVip) => "${_savedPrefix(isVip)}/templates/saved";

  String savedTemplateById(bool isVip, String id) =>
      "${_savedPrefix(isVip)}/templates/saved/$id";

  String savedTemplateDefault(bool isVip) =>
      "${_savedPrefix(isVip)}/templates/saved/default";

  String savedTemplateMakeDefault(bool isVip, String id) =>
      "${_savedPrefix(isVip)}/templates/saved/$id/default";

  // Notifications
  String notifications(bool isVip) => "${_savedPrefix(isVip)}/notifications";
  String notificationRead(bool isVip, int id) =>
      "${_savedPrefix(isVip)}/notifications/$id/read";
  String notificationsMarkAllRead(bool isVip) =>
      "${_savedPrefix(isVip)}/notifications/mark-all-read";
  String deviceToken(bool isVip) => "${_savedPrefix(isVip)}/device-token";
  String profileView(bool isVip, dynamic targetId) =>
      "${_savedPrefix(isVip)}/profiles/$targetId/view";
}

final class _JsonPaths {
  const _JsonPaths();

  final String appConfig = "assets/config/app_config.json";
  final String languageStrings = "assets/lang/en.json";
}

final class _IconPaths {
  const _IconPaths();

  final String appIcon = "assets/logo/app_icon.png";
  final String logoIcon = "assets/logo/logo_icon.png";
  final String logoHorizontal = "assets/logo/logo_horizontal.png";
  final String logoVertical = "assets/logo/logo_vertical.png";
  final String appLogo = "assets/logo/logo_icon.png";
  final String appLogoLight = "assets/logo/logo_horizontal.png";
  final String appLogoDark = "assets/logo/logo_horizontal.png";
  final String vipRegisterBackground =
      "assets/images/vip_register_background.svg";
  final String settings = "assets/icons/settings.png";
  final String profile = "assets/icons/profile.png";
  final String visible = "assets/icons/visible.svg";
  final String hidden = "assets/icons/hidden.svg";
  final String user = "assets/icons/user.svg";
  final String home = "assets/icons/home.svg";
  final String reels = "assets/icons/reels.svg";
  final String ads = "assets/icons/ads.svg";
  final String vipRegister = "assets/icons/vip_register.svg";
  final String crown = "assets/icons/crown.svg";
  final String menu = "assets/icons/menu.svg";
  final String extra = "assets/icons/extra.svg";
  final String like = "assets/icons/like.svg";
  final String comment = "assets/icons/comment.svg";
  final String share = "assets/icons/share.svg";
}

final class _ImagePaths {
  const _ImagePaths();

  final String loginBg = "assets/images/login_bg.png";
  final String adsBg = "assets/images/ads_bg.png";
  final String adsBg1 = "assets/images/ads_bg1.png";
  final String moroccanPattern = "assets/images/moroccan_pattern.jpg";
  final String vipCategoryBg = "assets/images/vip_category_bg.jpeg";
  final String vipCategoryBg2 = "assets/images/vip_category_bg_2.jpeg";
}

final class _ThemePaths {
  const _ThemePaths();

  final String dark = "assets/json/theme/dark_colors.json";
  final String light = "assets/json/theme/light_colors.json";
}

final class _Misc {
  const _Misc();

  // General constants (you can extend later)
  final String appName = "HolyNikah";
  final String defaultLanguage = "en";
  final Duration apiTimeout = const Duration(seconds: 30);
}
