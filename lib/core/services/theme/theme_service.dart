import 'package:holynikkah/core/services/theme/color_service.dart';
import 'package:holynikkah/core/services/theme/text_service.dart';

class ThemeService {
  ThemeService._();

  static AppThemeMode currentMode = AppThemeMode.light;

  static Future<void> initTheme(AppThemeMode mode) async {
    await ColorService.init(mode: mode);
    await TextService.init(mode: mode);
    currentMode = mode;
  }

  static Future<void> switchTheme(AppThemeMode mode) async {
    await initTheme(mode);
  }
}
