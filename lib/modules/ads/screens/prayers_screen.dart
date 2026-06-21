import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/models/prayer_model.dart';
import 'package:holynikkah/modules/ads/services/prayers_service.dart';
import 'package:holynikkah/modules/reels/screens/reels_screen.dart';
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
    final response = await PrayersService.instance.fetchFeed(page: nextPage);

    if (!mounted) return;

    if (response.success && response.data != null) {
      final feed = response.data!;
      final previousLength = _prayers.length;
      setState(() {
        _prayers = [..._prayers, ...feed.prayers];
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
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          _PrayerOverlay(
            currentIndex: 0,
            totalCount: 0,
            showSwipeHint: false,
            showProgress: false,
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
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white54, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => _loadPrayers(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          const _PrayerOverlay(
            currentIndex: 0,
            totalCount: 0,
            showSwipeHint: false,
            showProgress: false,
          ),
        ],
      );
    }

    if (_prayers.isEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No prayers available',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _loadPrayers(refresh: true),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
          const _PrayerOverlay(
            currentIndex: 0,
            totalCount: 0,
            showSwipeHint: false,
            showProgress: false,
          ),
        ],
      );
    }

    final canSwipeNext =
        _currentIndex < _prayers.length - 1 || _hasMore;

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
        _PrayerOverlay(
          currentIndex: _currentIndex,
          totalCount: _prayers.length,
          showSwipeHint: _showSwipeHint && canSwipeNext,
          showProgress: true,
        ),
      ],
    );
  }
}

/// Floating chrome — no solid AppBar (Stories / Reels pattern).
class _PrayerOverlay extends StatelessWidget {
  const _PrayerOverlay({
    required this.currentIndex,
    required this.totalCount,
    required this.showSwipeHint,
    required this.showProgress,
  });

  final int currentIndex;
  final int totalCount;
  final bool showSwipeHint;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return IgnorePointer(
      ignoring: false,
      child: Stack(
        children: [
          /// Top gradient scrim — keeps controls readable on any image.
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
              child: SizedBox(height: topPadding + 96),
            ),
          ),

          /// Bottom gradient scrim for swipe hint.
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
                child: SizedBox(height: bottomPadding + 72),
              ),
            ),

          /// Top controls
          Positioned(
            top: topPadding + 8,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showProgress && totalCount > 0) ...[
                  _PrayerProgressIndicator(
                    total: totalCount,
                    currentIndex: currentIndex,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    const CustomBackButton(),
                    const SizedBox(width: 12),
                    const Text(
                      'Prayers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    if (showProgress && totalCount > 0)
                      Text(
                        '${currentIndex + 1} / $totalCount',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          /// Swipe hint
          if (showSwipeHint)
            Positioned(
              bottom: bottomPadding + 24,
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
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Swipe up for next',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
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

/// Progress indicator — segments for small feeds, single bar for large feeds.
class _PrayerProgressIndicator extends StatelessWidget {
  const _PrayerProgressIndicator({
    required this.total,
    required this.currentIndex,
  });

  final int total;
  final int currentIndex;

  /// Stories-style segments only make sense for short sequences.
  static const int _segmentThreshold = 12;

  @override
  Widget build(BuildContext context) {
    if (total <= _segmentThreshold) {
      return _SegmentProgressBar(
        total: total,
        currentIndex: currentIndex,
      );
    }

    final progress = total > 1 ? (currentIndex + 1) / total : 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 2.5,
        backgroundColor: Colors.white.withValues(alpha: 0.35),
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}

/// Stories-style segment progress — one bar per prayer (≤12 only).
class _SegmentProgressBar extends StatelessWidget {
  const _SegmentProgressBar({
    required this.total,
    required this.currentIndex,
  });

  final int total;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isPast = i < currentIndex;
        final isCurrent = i == currentIndex;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2.5,
              decoration: BoxDecoration(
                color: isPast || isCurrent
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PrayerItem extends StatelessWidget {
  const _PrayerItem({required this.prayer});

  final PrayerModel prayer;

  @override
  Widget build(BuildContext context) {
    if (prayer.imageUrl.isEmpty) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Icon(Icons.image_not_supported, color: Colors.white54, size: 48),
        ),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: CachedNetworkImage(
        imageUrl: prayer.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[850]!,
          highlightColor: Colors.grey[700]!,
          child: const ColoredBox(color: Colors.black),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
        ),
      ),
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
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: widget.hasFailed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white54, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load more prayers',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: widget.onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
