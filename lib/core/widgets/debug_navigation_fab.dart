import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:holynikkah/core/utils/routes.dart';
import 'package:holynikkah/core/services/navigation_guard.dart';
import 'package:holynikkah/core/theme/context_extension.dart';

/// 🐛 Debug Navigation FAB
/// 
/// Shows a floating action button in debug mode to access navigation analytics
class DebugNavigationFAB extends StatelessWidget {
  const DebugNavigationFAB({super.key});

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) return const SizedBox.shrink();

    return Positioned(
      bottom: 100,
      right: 16,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: AppColors.brandYellow,
        foregroundColor: Colors.black,
        onPressed: () async {
          await context.navigationGuard.navigateTo(
            context,
            Routes.navigationAnalytics,
            trigger: 'debug_access',
          );
        },
        child: const Icon(Icons.analytics),
      ),
    );
  }
}

/// Extension to easily add debug FAB to any screens
extension DebugNavigationExtension on Widget {
  Widget withDebugNavigation() {
    return Stack(
      children: [
        this,
        const DebugNavigationFAB(),
      ],
    );
  }
}