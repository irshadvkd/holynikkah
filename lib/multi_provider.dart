import 'package:flutter/material.dart';
import 'package:holynikkah/application.dart';
import 'package:holynikkah/core/provider/theme_provider.dart';
import 'package:holynikkah/modules/category/controller/category_provider.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/myprofile/providers/profile_provider.dart';
import 'package:holynikkah/modules/registration/providers/registration_provider.dart';
import 'package:holynikkah/modules/template/providers/template_provider.dart';
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
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(
          create: (_) => TemplateProvider()..loadTemplateSelection(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider()..loadCategory(),
        ),
      ],
      child: const Application(),
    );
  }
}
