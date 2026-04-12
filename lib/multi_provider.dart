import 'package:flutter/material.dart';
import 'package:holynikkah/application.dart';
import 'package:holynikkah/core/provider/theme_provider.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/registration/providers/registration_provider.dart';
import 'package:provider/provider.dart';

/// 🔹 Sets up all app-wide providers
class MultiProviderSetup extends StatelessWidget {
  const MultiProviderSetup({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
      ],
      child: const Application(),
    );
  }
}
