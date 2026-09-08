import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/models/prayer_model.dart';
import 'package:holynikkah/modules/ads/services/common_ad_feed_service.dart';
import 'package:holynikkah/modules/reels/screens/reel_video_player.dart';
import 'package:shimmer/shimmer.dart';

class CommonAdFeedScreen extends StatefulWidget {
  final String title;
  final String feedUrl;
  final String Function(int id) viewUrlBuilder;

  const CommonAdFeedScreen({
    super.key,
    required this.title,
    required this.feedUrl,
    required this.viewUrlBuilder,
  });

  @override
  State<CommonAdFeedScreen> createState() => _CommonAdFeedScreenState();
}

class _CommonAdFeedScreenState extends State<CommonAdFeedScreen> {
  final PageController _pageController = PageController();
  List<PrayerModel> _items = [];
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
    _loadFeed();
  }

  Future<void> _loadFeed({bool refresh = false}) async {
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

    final response = await CommonAdFeedService.instance.fetchFeed(
      feedUrl: widget.feedUrl,
      page: 1,
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      final feed = response.data!;
      setState(() {
        _items = feed.prayers;
        _currentPage = feed.currentPage;
        _hasMore = feed.hasMore;
        _isLoading = false;
      });
      _onPageChanged(0);
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = response.message ?? 'Failed to load ${widget.title.toLowerCase()}';
    });
  }

  Future<void> _loadMoreFeed() async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreFailed = false;
    });

    final nextPage = _currentPage + 1;
    final response = await CommonAdFeedService.instance.fetchFeed(
      feedUrl: widget.feedUrl,
      page: nextPage,
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      final feed = response.data!;
      final previousLength = _items.length;
      setState(() {
        _items = [..._items, ...feed.prayers];
        _currentPage = feed.currentPage;
        _hasMore = feed.hasMore;
        _isLoadingMore = false;
        _loadMoreFailed = false;
      });
      if (_currentIndex >= previousLength) {
        _recordViewIfNeeded(_currentIndex);
      }
      return;
    }

    setState(() {
      _isLoadingMore = false;
      _loadMoreFailed = true;
    });
    AppLogger.warning(
      'Failed to load more ${widget.title.toLowerCase()}: ${response.message}',
      tag: 'CommonAdFeedScreen',
    );
  }

  void _maybeLoadMore(int index) {
    if (!_hasMore || _isLoadingMore || _items.isEmpty) return;
    if (index == _items.length - 1) {
      _loadMoreFeed();
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _showSwipeHint = false;
    });

    if (index >= _items.length) {
      if (_hasMore && !_isLoadingMore) {
        _loadMoreFeed();
      }
      return;
    }

    _maybeLoadMore(index);
    _recordViewIfNeeded(index);
  }

  void _recordViewIfNeeded(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_lastActiveIndex == index) return;

    _lastActiveIndex = index;

    final item = _items[index];
    final itemId = item.id;
    if (itemId == null || item.isWatched) return;

    CommonAdFeedService.instance.recordView(
      viewUrl: widget.viewUrlBuilder(itemId),
      itemId: itemId,
      isWatched: item.isWatched,
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
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.secondaryLight,
              AppColors.secondary,
              AppColors.background,
            ],
          ),
        ),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          _FeedOverlay(
            title: widget.title,
            showSwipeHint: false,
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, color: AppColors.textSecondary, size: 48.sp),
                  SizedBox(height: 16.h),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: () => _loadFeed(refresh: true),
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
          ),
          _FeedOverlay(
            title: widget.title,
            showSwipeHint: false,
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Center(
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
                    'No items available in ${widget.title.toLowerCase()}',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: () => _loadFeed(refresh: true),
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
          ),
          _FeedOverlay(
            title: widget.title,
            showSwipeHint: false,
          ),
        ],
      );
    }

    final canSwipeNext = _currentIndex < _items.length - 1 || _hasMore;

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _items.length + (_hasMore ? 1 : 0),
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            if (index >= _items.length) {
              return _NextPageLoader(
                isLoading: _isLoadingMore,
                hasFailed: _loadMoreFailed,
                onRetry: _loadMoreFeed,
                title: widget.title,
              );
            }

            return _FeedItem(item: _items[index]);
          },
        ),
        _FeedOverlay(
          title: widget.title,
          showSwipeHint: _showSwipeHint && canSwipeNext,
        ),
      ],
    );
  }
}

class _FeedOverlay extends StatelessWidget {
  const _FeedOverlay({
    required this.title,
    required this.showSwipeHint,
  });

  final String title;
  final bool showSwipeHint;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.6, 1],
                ),
              ),
              child: SizedBox(height: topPadding + 64.h),
            ),
          ),
          if (showSwipeHint)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SizedBox(height: bottomPadding + 72.h),
              ),
            ),
          Positioned(
            top: topPadding + 8.h,
            left: 20.w,
            right: 20.w,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 40.w,
                    height: 40.w,
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
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.headline(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 40.w),
              ],
            ),
          ),
          if (showSwipeHint)
            Positioned(
              bottom: bottomPadding + 24.h,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: showSwipeHint ? 1 : 0,
                  duration: const Duration(milliseconds: 400),
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
      ),
    );
  }
}

class _FeedItem extends StatelessWidget {
  const _FeedItem({required this.item});

  final PrayerModel item;

  @override
  Widget build(BuildContext context) {
    if (item.imageUrl.isEmpty) {
      return Center(
        child: Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary, size: 48.sp),
      );
    }

    if (item.mediaType == 'video') {
      return ReelVideoPlayer(
        videoUrl: item.imageUrl,
        thumbnail: '',
      );
    }

    return CachedNetworkImage(
      imageUrl: item.imageUrl,
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
}

class _NextPageLoader extends StatefulWidget {
  const _NextPageLoader({
    required this.isLoading,
    required this.hasFailed,
    required this.onRetry,
    required this.title,
  });

  final bool isLoading;
  final bool hasFailed;
  final VoidCallback onRetry;
  final String title;

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
                  'Could not load more ${widget.title.toLowerCase()}',
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
