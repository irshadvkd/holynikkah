import 'package:flutter/material.dart';
import 'package:holynikkah/modules/myprofile/screens/profile_update_screen.dart';

class VipProfileUpdateScreen extends StatelessWidget {
  const VipProfileUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileUpdateScreen(isVip: true);
  }
}