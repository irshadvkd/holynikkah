import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/widgets/legal_screens.dart';
import 'package:holynikkah/modules/home/screens/home_screen.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/myprofile/providers/profile_provider.dart';
import 'package:holynikkah/modules/myprofile/widgets/delete_account_dialog.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _buildMenuItem(
              context,
              icon: Icons.person,
              title: 'Profile',
              onTap: () => _navigateToProfile(context),
            ),
            _buildMenuItem(
              context,
              icon: Icons.description,
              title: 'Terms & Conditions',
              onTap: () => _navigateToTerms(context),
            ),
            _buildMenuItem(
              context,
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () => _navigateToPrivacy(context),
            ),
            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () => _logout(context),
              isDestructive: false,
            ),
            _buildMenuItem(
              context,
              icon: Icons.delete_forever,
              title: 'Delete Account',
              onTap: () => _deleteAccount(context),
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.r),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.white,
          size: 24.sp,
        ),
        title: Text(
          title,
          style: AppTypography.marcellus(
            color: isDestructive ? Colors.red : Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 16.sp,
        ),
          onTap: onTap,
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _navigateToTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsScreen()),
    );
  }

  void _navigateToPrivacy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyScreen()),
    );
  }

  void _deleteAccount(BuildContext context) {
    final profileProvider = context.read<ProfileProvider>();
    DeleteAccountDialog.show(
      context,
      initialIsVip: profileProvider.isVipProfile,
    );
  }

  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Logout', style: AppTypography.marcellus(color: Colors.white)),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTypography.marcellus(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTypography.marcellus(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final profileProvider = context.read<ProfileProvider>();
              await authProvider.logoutAll();
              profileProvider.clearProfile();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen(initialIndex: 2)),
                (route) => false,
              );
            },
            child: Text('Logout', style: AppTypography.marcellus(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Profile', style: AppTypography.marcellus(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text(
          'Profile Screen',
          style: AppTypography.marcellus(color: Colors.white, fontSize: 18.sp),
        ),
      ),
    );
  }
}


