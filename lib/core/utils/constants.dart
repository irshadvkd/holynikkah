/// Centralized app-wide constants.
/// Use this to access URLs, asset paths, themes, icons, etc.
final class AppConstants {
  const AppConstants._(); // private constructor (prevent instantiation)

  /// OTP digit count used across login and verification flows.
  static const int otpLength = 4;

  /// 🌐 API URLs
  static const urls = _Urls();

  /// 📁 Local asset JSON paths
  static const json = _JsonPaths();

  /// 🖼️ Icon asset paths
  static const icons = _IconPaths();

  /// 🎨 Theme file paths
  static const themes = _ThemePaths();

  /// 🧩 Other useful app constants
  static const misc = _Misc();
}

final class _Urls {
  const _Urls();

  /// Base URL — no trailing slash.
  final String base = "http://172.20.10.2:8000/api";

  // Auth
  final String login = "/login/login";
  final String register = "/login/register";

  // Content
  final String reels = "/reels";
  final String reelsFeed = "/reels/feed";

  String reelsView(int reelId) => "/reels/$reelId/views";

  // Prayers
  final String prayersFeed = "/prayers/feed";

  String prayersView(int prayerId) => "/prayers/$prayerId/views";

  // User
  final String userProfile = "/user/profile";

  // Categories
  final String categories = "/categories";
  final String vipCategories = "/vip-categories";

  // Normal users
  final String normalOtpSend = "/normal-users/otp/send";
  final String normalOtpVerify = "/normal-users/otp/verify";
  final String normalUsersRegister = "/normal-users/register";
  final String normalCategorySelect = "/normal-users/category/select";

  // VIP OTP
  final String vipOtpSend = "/vip-users/otp/send";
  final String vipOtpResend = "/vip-users/otp/resend";
  final String vipOtpVerify = "/vip-users/otp/verify";
  final String vipUsersRegister = "/vip-users/register";
  final String vipCategorySelect = "/vip-users/category/select";

  // Locations
  final String locationStates = "/locations/states";
  final String locationDistricts = "/locations/districts";
}

final class _JsonPaths {
  const _JsonPaths();

  final String appConfig = "assets/config/app_config.json";
  final String languageStrings = "assets/lang/en.json";
}

final class _IconPaths {
  const _IconPaths();

  final String appLogoLight = "assets/images/app_logo_light.png";
  final String appLogoDark = "assets/images/app_logo_dark.png";
  final String settings = "assets/icons/settings.png";
  final String profile = "assets/icons/profile.png";
  final String visible = "assets/icons/visible.svg";
  final String hidden = "assets/icons/hidden.svg";
  final String user = "assets/icons/user.svg";
  final String home = "assets/icons/home.svg";
  final String reels = "assets/icons/reels.svg";
  final String ads = "assets/icons/ads.svg";
  final String vipRegister = "assets/icons/vip_register.svg";
  final String menu = "assets/icons/menu.svg";
  final String extra = "assets/icons/extra.svg";
  final String like = "assets/icons/like.svg";
  final String comment = "assets/icons/comment.svg";
  final String share = "assets/icons/share.svg";
}

final class _ThemePaths {
  const _ThemePaths();

  final String dark = "assets/json/theme/dark_colors.json";
  final String light = "assets/json/theme/light_colors.json";
}

final class _Misc {
  const _Misc();

  // General constants (you can extend later)
  final String appName = "Holy Nikkah";
  final String defaultLanguage = "en";
  final Duration apiTimeout = const Duration(seconds: 30);
}
