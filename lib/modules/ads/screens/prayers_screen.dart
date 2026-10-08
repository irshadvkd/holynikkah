import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/models/prayer_model.dart';
import 'package:holynikkah/modules/ads/services/prayers_service.dart';
import 'package:shimmer/shimmer.dart';

class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key});

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  final PageController _pageController = PageController();
  List<PrayerModel> _prayers = [];
  int _currentIndex = 0;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  int? _lastActiveIndex;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showSwipeHint = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    _loadPrayers();
  }

  Future<void> _loadPrayers({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _loadMoreFailed = false;
      _lastActiveIndex = null;
      _showSwipeHint = true;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await PrayersService.instance.fetchFeed(page: 1);

    if (!mounted) return;

    if (response.success && response.data != null) {
      final feed = response.data!;
      setState(() {
        _prayers = feed.prayers;
        _currentPage = feed.currentPage;
        _hasMore = feed.hasMore;
        _isLoading = false;
      });
      _onPageChanged(0);
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = response.message ?? 'Failed to load prayers';
    });
  }

  Future<void> _loadMorePrayers() async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreFailed = false;
    });

    final nextPage = _currentPage + 1;
    final currentIds = _prayers.map((p) => p.id).whereType<int>();
    final response = await PrayersService.instance.fetchFeed(
      page: nextPage,
      excludeIds: currentIds,
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      final feed = response.data!;
      final existingIds = _prayers.map((p) => p.id).whereType<int>().toSet();
      final newPrayers = feed.prayers
          .where((p) => p.id == null || !existingIds.contains(p.id))
          .toList();

      final previousLength = _prayers.length;
      setState(() {
        _prayers = [..._prayers, ...newPrayers];
        _currentPage = feed.currentPage;
        _hasMore = feed.hasMore && newPrayers.isNotEmpty;
        _isLoadingMore = false;
        _loadMoreFailed = false;
      });
      if (newPrayers.isNotEmpty && _currentIndex >= previousLength) {
        _recordViewIfNeeded(_currentIndex);
      }
      return;
    }

    setState(() {
      _isLoadingMore = false;
      _loadMoreFailed = true;
    });
    AppLogger.warning(
      'Failed to load more prayers: ${response.message}',
      tag: 'PrayersScreen',
    );
  }

  void _maybeLoadMore(int index) {
    if (!_hasMore || _isLoadingMore || _prayers.isEmpty) return;
    if (index == _prayers.length - 1) {
      _loadMorePrayers();
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _showSwipeHint = false;
    });

    if (index >= _prayers.length) {
      if (_hasMore && !_isLoadingMore) {
        _loadMorePrayers();
      }
      return;
    }

    _maybeLoadMore(index);
    _recordViewIfNeeded(index);
  }

  void _recordViewIfNeeded(int index) {
    if (index < 0 || index >= _prayers.length) return;
    if (_lastActiveIndex == index) return;

    _lastActiveIndex = index;

    final prayer = _prayers[index];
    final prayerId = prayer.id;
    if (prayerId == null || prayer.isWatched) return;

    PrayersService.instance.recordView(
      prayerId: prayerId,
      isWatched: prayer.isWatched,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            const _StaticHeader(title: 'Prayers'),
            Expanded(
              child: _buildBody(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: AppColors.textSecondary,
                size: 48.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () => _loadPrayers(refresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
                child: Text(
                  'Retry',
                  style: AppTypography.button(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_prayers.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                color: AppColors.textSecondary,
                size: 48.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                'No prayers available',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () => _loadPrayers(refresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
                child: Text(
                  'Refresh',
                  style: AppTypography.button(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final canSwipeNext =
        _currentIndex < _prayers.length - 1 || _hasMore;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _prayers.length + (_hasMore ? 1 : 0),
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            if (index >= _prayers.length) {
              return _NextPageLoader(
                isLoading: _isLoadingMore,
                hasFailed: _loadMoreFailed,
                onRetry: _loadMorePrayers,
              );
            }

            return _PrayerItem(prayer: _prayers[index]);
          },
        ),
        if (_showSwipeHint && canSwipeNext)
          Positioned(
            bottom: bottomPadding + 16.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: AppColors.white.withValues(alpha: 0.8),
                      size: 20.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Swipe up for next',
                      style: AppTypography.marcellus(
                        color: AppColors.white.withValues(alpha: 0.8),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StaticHeader extends StatelessWidget {
  const _StaticHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 6.h,
        bottom: 12.h,
        left: 16.w,
        right: 16.w,
      ),
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        border: Border(
          bottom: BorderSide(
            color: Color(0x1FFFFFFF),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary,
                size: 18.sp,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              title,
              style: AppTypography.title(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerItem extends StatelessWidget {
  const _PrayerItem({required this.prayer});

  final PrayerModel prayer;

  @override
  Widget build(BuildContext context) {
    if (prayer.imageUrl.isEmpty) {
      return Center(
        child: Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary, size: 48.sp),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final screenAspect = screenWidth / (screenHeight > 0 ? screenHeight : 1);
        final isWideScreen = screenAspect > 0.62; // Standard phones are ~0.45 - 0.56. Tablets / iPads > 0.65

        if (!isWideScreen) {
          // Mobile phones: Standard full screen BoxFit.cover
          return CachedNetworkImage(
            imageUrl: prayer.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: AppColors.secondary,
              highlightColor: AppColors.secondaryLight,
              child: const ColoredBox(color: AppColors.secondary),
            ),
            errorWidget: (context, url, error) => Center(
              child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary, size: 48.sp),
            ),
          );
        }

        // Tablets / iPads (wide screens): Ambient Blurred Backdrop + BoxFit.contain
        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Ambient blurred background filling wide tablet / iPad screens
            CachedNetworkImage(
              imageUrl: prayer.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.secondary),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
            // 2. Full uncropped crisp poster in center
            Center(
              child: CachedNetworkImage(
                imageUrl: prayer.imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: AppColors.secondary,
                  highlightColor: AppColors.secondaryLight,
                  child: const ColoredBox(color: AppColors.secondary),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary, size: 48.sp),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NextPageLoader extends StatefulWidget {
  const _NextPageLoader({
    required this.isLoading,
    required this.hasFailed,
    required this.onRetry,
  });

  final bool isLoading;
  final bool hasFailed;
  final VoidCallback onRetry;

  @override
  State<_NextPageLoader> createState() => _NextPageLoaderState();
}

class _NextPageLoaderState extends State<_NextPageLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isLoading) {
        widget.onRetry();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: widget.hasFailed
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, color: AppColors.textSecondary, size: 40.sp),
                SizedBox(height: 12.h),
                Text(
                  'Could not load more prayers',
                  style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: widget.onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  ),
                  child: Text(
                    'Retry',
                    style: AppTypography.button(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          : const CircularProgressIndicator(color: AppColors.primary),
    );
  }
}
