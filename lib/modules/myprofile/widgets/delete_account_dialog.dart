import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/modules/home/screens/home_screen.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/myprofile/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class DeleteAccountDialog extends StatefulWidget {
  final bool initialIsVip;

  const DeleteAccountDialog({
    super.key,
    required this.initialIsVip,
  });

  static Future<void> show(
    BuildContext context, {
    required bool initialIsVip,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DeleteAccountDialog(initialIsVip: initialIsVip),
    );
  }

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  late bool _targetIsVip;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _targetIsVip = widget.initialIsVip;
  }

  Future<void> _handleDelete(
    AuthProvider authProvider,
    ProfileProvider profileProvider,
  ) async {
    setState(() => _isDeleting = true);

    try {
      final response = await authProvider.deleteAccount(isVip: _targetIsVip);

      if (!mounted) return;

      if (response.success) {
        if (_targetIsVip) {
          profileProvider.clearVipProfile();
        } else {
          profileProvider.clearNormalProfile();
        }

        Navigator.of(context, rootNavigator: true).pop(); // Close dialog

        final successMsg = (response.message != null && response.message!.isNotEmpty)
            ? response.message!
            : 'Account deleted successfully.';
        CommonSnackBar.showSuccess(context, successMsg);

        if (!authProvider.isAnyUserLoggedIn) {
          profileProvider.clearProfile();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(initialIndex: 2),
            ),
            (route) => false,
          );
        } else {
          // Switch to remaining logged in profile
          profileProvider.setVipProfile(authProvider.isVipLoggedIn);
          await profileProvider.fetchProfiles(authProvider: authProvider);
        }
      } else {
        setState(() => _isDeleting = false);
        final errorMsg = (response.message != null && response.message!.isNotEmpty)
            ? response.message!
            : 'Failed to delete account. Please try again.';
        CommonSnackBar.showError(context, errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      CommonSnackBar.showError(
        context,
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final hasBothAccounts =
        authProvider.isVipLoggedIn && authProvider.isNormalLoggedIn;

    final hnId = _targetIsVip
        ? profileProvider.vipHnId
        : profileProvider.normalHnId;

    return Dialog(
      backgroundColor: const Color(0xFF101D33), // var(--bg-mid)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(
          color: const Color(0xFFE53935).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400.w),
        child: Padding(
          padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 22.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔴 Warning Icon Header
              Center(
                child: Container(
                  width: 58.w,
                  height: 58.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE53935).withValues(alpha: 0.12),
                    border: Border.all(
                      color: const Color(0xFFE53935).withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.delete_forever_rounded,
                      color: const Color(0xFFEF5350),
                      size: 30.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Title
              Text(
                'Delete ${_targetIsVip ? 'VIP' : 'Normal'} Account',
                textAlign: TextAlign.center,
                style: AppTypography.marcellus(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF4ECDD),
                ),
              ),
              SizedBox(height: 6.h),

              // Subtitle / Account ID
              if (hnId.isNotEmpty)
                Text(
                  'HolyNikah ID: $hnId',
                  textAlign: TextAlign.center,
                  style: AppTypography.marcellus(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFC9A15F),
                  ),
                ),
              SizedBox(height: 14.h),

              // Tier switch tab if dual login active
              if (hasBothAccounts) ...[
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E182A),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: const Color(0xFFE3C78F).withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _isDeleting
                              ? null
                              : () {
                                  setState(() => _targetIsVip = true);
                                },
                          child: Container(
                            height: 34.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.r),
                              color: _targetIsVip
                                  ? const Color(0xFFE53935).withValues(alpha: 0.25)
                                  : Colors.transparent,
                              border: _targetIsVip
                                  ? Border.all(
                                      color: const Color(0xFFE53935).withValues(alpha: 0.6),
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'VIP Account',
                                style: AppTypography.marcellus(
                                  fontSize: 13.sp,
                                  fontWeight: _targetIsVip
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: _targetIsVip
                                      ? const Color(0xFFF4ECDD)
                                      : const Color(0xFFCBB388).withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isDeleting
                              ? null
                              : () {
                                  setState(() => _targetIsVip = false);
                                },
                          child: Container(
                            height: 34.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.r),
                              color: !_targetIsVip
                                  ? const Color(0xFFE53935).withValues(alpha: 0.25)
                                  : Colors.transparent,
                              border: !_targetIsVip
                                  ? Border.all(
                                      color: const Color(0xFFE53935).withValues(alpha: 0.6),
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Normal Account',
                                style: AppTypography.marcellus(
                                  fontSize: 13.sp,
                                  fontWeight: !_targetIsVip
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: !_targetIsVip
                                      ? const Color(0xFFF4ECDD)
                                      : const Color(0xFFCBB388).withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
              ],

              // ⚠️ Warning Box
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: const Color(0xFFE53935).withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This action cannot be undone:',
                      style: AppTypography.marcellus(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF8A80),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    _buildWarningPoint(
                      'Permanently erase your matrimonial profile, personal details, and gallery photos.',
                    ),
                    _buildWarningPoint(
                      'Delete all partner matches, contact requests, and phone view permissions.',
                    ),
                    if (_targetIsVip)
                      _buildWarningPoint(
                        'Terminate VIP membership, priority listing, and exclusive tier benefits.',
                      ),
                    _buildWarningPoint(
                      'Clear all saved profile templates and category preferences.',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),

              if (hasBothAccounts)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    'Note: Only this ${_targetIsVip ? 'VIP' : 'Normal'} account will be deleted. Your other profile will remain active.',
                    style: AppTypography.marcellus(
                      fontSize: 12.sp,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFCBB388).withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              SizedBox(height: 18.h),

              // Action Buttons
              Row(
                children: [
                  // Cancel / Keep
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        side: BorderSide(
                          color: const Color(0xFFC9A15F).withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0xFFCBB388),
                      ),
                      onPressed: _isDeleting
                          ? null
                          : () => Navigator.of(context, rootNavigator: true).pop(),
                      child: Text(
                        'Keep Account',
                        style: AppTypography.marcellus(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Confirm Delete
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                      ),
                      onPressed: _isDeleting
                          ? null
                          : () => _handleDelete(
                                authProvider,
                                profileProvider,
                              ),
                      child: _isDeleting
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Delete Account',
                              style: AppTypography.marcellus(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4.h, right: 8.w),
            child: Container(
              width: 5.w,
              height: 5.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF8A80),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.marcellus(
                fontSize: 12.5.sp,
                height: 1.35,
                color: const Color(0xFFF4ECDD).withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
