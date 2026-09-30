import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/services/legal_service.dart';
import 'package:holynikkah/core/theme/app_typography.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  LegalPage? _page;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = await LegalService.instance.getTermsAndConditions();
      if (mounted) {
        if (page != null) {
          setState(() {
            _page = page;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to load Terms & Conditions';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -1.0),
                  radius: 1.2,
                  colors: [
                    Color(0xFF101D33),
                    Color(0xFF0A1220),
                    Color(0xFF050810),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Color(0xFFCBB388)),
                  title: Text(
                    _page?.title ?? 'Terms & Conditions',
                    style: AppTypography.marcellus(
                      color: const Color(0xFFF4ECDD),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFCBB388),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: AppTypography.marcellus(
                  color: Colors.redAccent,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC9A15F),
                  foregroundColor: const Color(0xFF0A1220),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                onPressed: _fetchContent,
                child: Text(
                  'Retry',
                  style: AppTypography.marcellus(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      physics: const BouncingScrollPhysics(),
      child: Text(
        _page?.content ?? '',
        style: AppTypography.marcellus(
          color: const Color(0xFFF4ECDD),
          fontSize: 15.sp,
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  LegalPage? _page;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = await LegalService.instance.getPrivacyPolicy();
      if (mounted) {
        if (page != null) {
          setState(() {
            _page = page;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to load Privacy Policy';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -1.0),
                  radius: 1.2,
                  colors: [
                    Color(0xFF101D33),
                    Color(0xFF0A1220),
                    Color(0xFF050810),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Color(0xFFCBB388)),
                  title: Text(
                    _page?.title ?? 'Privacy Policy',
                    style: AppTypography.marcellus(
                      color: const Color(0xFFF4ECDD),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFCBB388),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: AppTypography.marcellus(
                  color: Colors.redAccent,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC9A15F),
                  foregroundColor: const Color(0xFF0A1220),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                onPressed: _fetchContent,
                child: Text(
                  'Retry',
                  style: AppTypography.marcellus(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      physics: const BouncingScrollPhysics(),
      child: Text(
        _page?.content ?? '',
        style: AppTypography.marcellus(
          color: const Color(0xFFF4ECDD),
          fontSize: 15.sp,
          height: 1.6,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
