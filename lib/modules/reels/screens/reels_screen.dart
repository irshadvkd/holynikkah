import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/models/video_model.dart';
import 'package:holynikkah/modules/reels/services/reel_video_loader.dart';
import 'package:holynikkah/modules/reels/services/reels_service.dart';
import 'package:video_player/video_player.dart';

class ReelsScreen extends StatefulWidget {
  final bool isBackArrowEnabled;
  final bool isActive;

  const ReelsScreen({
    super.key,
    this.isBackArrowEnabled = false,
    this.isActive = true,
  });

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with WidgetsBindingObserver {
  final PageController pageController = PageController();
  List<VideoModel> videos = [];
  int currentIndex = 0;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  int? _lastActiveIndex;
  final Map<int, VideoPlayerController> controllers = {};
  final Set<int> _preparingIndexes = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAppInForeground = true;
  bool _isMuted = false;

  double get _activeVolume => _isMuted ? 0.0 : 1.0;

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    final controller = controllers[currentIndex];
    if (controller != null && controller.value.isInitialized) {
      controller.setVolume(_activeVolume);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    loadVideos();
  }

  @override
  void didUpdateWidget(covariant ReelsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (!widget.isActive) {
        _pauseAllControllers();
      } else {
        _syncPlaybackState(playCurrent: true);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        if (widget.isActive) {
          _syncPlaybackState(playCurrent: true);
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        _pauseAllControllers();
    }
  }

  void _pauseAllControllers() {
    for (final controller in controllers.values) {
      if (controller.value.isInitialized) {
        controller
          ..pause()
          ..setVolume(0.0);
      }
    }
  }

  void _syncPlaybackState({bool playCurrent = false}) {
    for (final entry in controllers.entries) {
      final controller = entry.value;
      if (!controller.value.isInitialized) continue;

      final isCurrent = entry.key == currentIndex;

      if (isCurrent && playCurrent && _isAppInForeground && widget.isActive) {
        controller
          ..setVolume(_activeVolume)
          ..setLooping(true)
          ..play();
      } else if (!isCurrent || !widget.isActive) {
        controller
          ..pause()
          ..setVolume(0.0);
      } else if (isCurrent && !_isAppInForeground) {
        controller.pause();
      }
    }
  }

  @override
  void deactivate() {
    _pauseAllControllers();
    super.deactivate();
  }

  Future<void> loadVideos({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _loadMoreFailed = false;
      _lastActiveIndex = null;
      for (final controller in controllers.values) {
        await controller.dispose();
      }
      controllers.clear();
      await ReelVideoLoader.clearCache();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ReelsService.instance.fetchFeed(page: 1);

    if (!mounted) return;

    if (response.success && response.data != null) {
      final feed = response.data!;
      setState(() {
        videos = feed.reels;
        _currentPage = feed.currentPage;
        _hasMore = feed.hasMore;
        _isLoading = false;
      });
      preloadVideos();
      _onPageChanged(0);
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = response.message ?? 'Failed to load reels';
    });
  }

  Future<void> _loadMoreVideos() async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreFailed = false;
    });

    final nextPage = _currentPage + 1;
    final currentIds = videos.map((v) => v.id).whereType<int>();
    final response = await ReelsService.instance.fetchFeed(
      page: nextPage,
      excludeIds: currentIds,
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      final feed = response.data!;
      final existingIds = videos.map((v) => v.id).whereType<int>().toSet();
      final newReels = feed.reels
          .where((r) => r.id == null || !existingIds.contains(r.id))
          .toList();

      final previousLength = videos.length;
      setState(() {
        videos = [...videos, ...newReels];
        _currentPage = feed.currentPage;
        _hasMore = feed.hasMore && newReels.isNotEmpty;
        _isLoadingMore = false;
        _loadMoreFailed = false;
      });
      if (newReels.isNotEmpty) {
        _preloadUpcomingVideos(fromIndex: previousLength, count: 2);
        _prepareActiveReelAfterLoad(previousLength);
      }
      return;
    }

    setState(() {
      _isLoadingMore = false;
      _loadMoreFailed = true;
    });
    AppLogger.warning(
      'Failed to load more reels: ${response.message}',
      tag: 'ReelsScreen',
    );
  }

  void _prepareActiveReelAfterLoad(int previousLength) {
    if (currentIndex < previousLength || currentIndex >= videos.length) return;

    _prepareController(currentIndex);
    _recordViewIfNeeded(currentIndex);
  }

  void _ensureNextPageLoaded(int index) {
    if (!_hasMore || _isLoadingMore) return;
    _loadMoreVideos();
  }

  void _maybeLoadMore(int index) {
    if (!_hasMore || _isLoadingMore || videos.isEmpty) return;

    final isLastReel = index == videos.length - 1;
    if (isLastReel) {
      _loadMoreVideos();
    }
  }

  void _preloadUpcomingVideos({required int fromIndex, int count = 2}) {
    for (int i = fromIndex; i < fromIndex + count && i < videos.length; i++) {
      _prepareController(i);
    }
  }

  void _cleanupDistantControllers(int activeIndex) {
    final keysToRemove = <int>[];
    for (final index in controllers.keys) {
      if (index < activeIndex - 1 || index > activeIndex + 2) {
        keysToRemove.add(index);
      }
    }

    for (final index in keysToRemove) {
      final controller = controllers.remove(index);
      if (controller != null) {
        controller.pause();
        controller.dispose();
      }
      _preparingIndexes.remove(index);
    }
  }

  void _onPageChanged(int index) {
    setState(() => currentIndex = index);
    _syncPlaybackState();

    if (index >= videos.length) {
      _ensureNextPageLoaded(index);
      return;
    }

    _prepareController(index);
    if (index + 1 < videos.length) {
      _prepareController(index + 1);
    }
    if (index - 1 >= 0) {
      _prepareController(index - 1);
    }

    _cleanupDistantControllers(index);

    _maybeLoadMore(index);
    _recordViewIfNeeded(index);
    _syncPlaybackState(playCurrent: true);
  }

  void _recordViewIfNeeded(int index) {
    if (index < 0 || index >= videos.length) return;
    if (_lastActiveIndex == index) return;

    _lastActiveIndex = index;

    final reel = videos[index];
    final reelId = reel.id;
    if (reelId == null || reel.isWatched) return;

    ReelsService.instance.recordView(
      reelId: reelId,
      isWatched: reel.isWatched,
    );
  }

  void preloadVideos() {
    for (int i = 0; i < videos.length && i < 3; i++) {
      _prepareController(i);
    }
  }

  Future<void> _prepareController(int index) async {
    if (controllers.containsKey(index) ||
        _preparingIndexes.contains(index) ||
        index < 0 ||
        index >= videos.length ||
        videos[index].sources.isEmpty) {
      return;
    }

    _preparingIndexes.add(index);

    try {
      final controller = await ReelVideoLoader.createController(videos[index]);
      if (!mounted) {
        await controller.dispose();
        return;
      }

      if (controllers.containsKey(index)) {
        await controller.dispose();
        return;
      }

      controllers[index] = controller;
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        controllers.remove(index);
        return;
      }

      controller.setLooping(true);
      _syncPlaybackState(playCurrent: index == currentIndex);
      setState(() {});
    } catch (error, stackTrace) {
      AppLogger.error(
        'Video playback error for reel ${videos[index].id ?? index}',
        tag: 'ReelsScreen',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _preparingIndexes.remove(index);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pauseAllControllers();
    pageController.dispose();
    for (final controller in controllers.values) {
      controller.dispose();
    }
    controllers.clear();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
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
                  style: AppTypography.marcellus(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => loadVideos(refresh: true),
                  child: Text('Retry', style: AppTypography.marcellus()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (videos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No reels available',
                style: AppTypography.marcellus(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => loadVideos(refresh: true),
                child: Text('Refresh', style: AppTypography.marcellus()),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            scrollDirection: Axis.vertical,
            itemCount: videos.length + (_hasMore ? 1 : 0),
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              if (index >= videos.length) {
                return _NextPageLoaderReel(
                  isLoading: _isLoadingMore,
                  hasFailed: _loadMoreFailed,
                  onRetry: _loadMoreVideos,
                  enableBackArrow: widget.isBackArrowEnabled,
                );
              }

              return ReelItem(
                video: videos[index],
                isActive: index == currentIndex,
                controller: controllers[index],
                isLoading: !controllers.containsKey(index) &&
                    videos[index].sources.isNotEmpty,
                enableBackArrow: widget.isBackArrowEnabled,
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _MuteButton(
              isMuted: _isMuted,
              onTap: _toggleMute,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPageLoaderReel extends StatefulWidget {
  final bool isLoading;
  final bool hasFailed;
  final VoidCallback onRetry;
  final bool enableBackArrow;

  const _NextPageLoaderReel({
    required this.isLoading,
    required this.hasFailed,
    required this.onRetry,
    required this.enableBackArrow,
  });

  @override
  State<_NextPageLoaderReel> createState() => _NextPageLoaderReelState();
}

class _NextPageLoaderReelState extends State<_NextPageLoaderReel> {
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: widget.hasFailed
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white54, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load more reels',
                        style: AppTypography.marcellus(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: widget.onRetry,
                        child: Text('Retry', style: AppTypography.marcellus()),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(color: Colors.white),
          ),
          if (widget.enableBackArrow)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              child: const CustomBackButton(),
            ),
        ],
      ),
    );
  }
}

/// Mute toggle for reel playback.
class _MuteButton extends StatelessWidget {
  final bool isMuted;
  final VoidCallback onTap;

  const _MuteButton({
    required this.isMuted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isMuted ? Icons.volume_off : Icons.volume_up,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

/// 🔥 BACK BUTTON (Reusable)
class CustomBackButton extends StatelessWidget {
  const CustomBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
      ),
    );
  }
}

class ReelItem extends StatefulWidget {
  final VideoModel video;
  final bool isActive;
  final VideoPlayerController? controller;
  final bool isLoading;
  final bool enableBackArrow;

  const ReelItem({
    super.key,
    required this.video,
    required this.isActive,
    this.controller,
    this.isLoading = false,
    this.enableBackArrow = false,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  bool isLiked = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final screenAspect = screenWidth / (screenHeight > 0 ? screenHeight : 1);
        final isWideScreen = screenAspect > 0.62; // Phones are ~0.56. Tablets / iPads are > 0.65

        final isInitialized =
            widget.controller != null && widget.controller!.value.isInitialized;
        final videoSize = isInitialized ? widget.controller!.value.size : null;
        final videoAspect = (videoSize != null && videoSize.height > 0)
            ? videoSize.width / videoSize.height
            : 9 / 16;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Ambient Background Layer (for tablets/iPads or letterboxing)
            if (isWideScreen) ...[
              if (widget.video.thumb.isNotEmpty)
                Image.network(
                  widget.video.thumb,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
                )
              else if (isInitialized)
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: widget.controller!.value.size.width,
                      height: widget.controller!.value.size.height,
                      child: VideoPlayer(widget.controller!),
                    ),
                  ),
                )
              else
                const ColoredBox(color: Colors.black),

              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ] else ...[
              // Standard phone background thumbnail while video loads
              if (widget.video.thumb.isNotEmpty && !isInitialized)
                Image.network(
                  widget.video.thumb,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
                ),
            ],

            // 2. Video Foreground Layer
            if (isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: isWideScreen ? videoAspect : screenAspect,
                  child: FittedBox(
                    fit: isWideScreen ? BoxFit.contain : BoxFit.cover,
                    child: SizedBox(
                      width: widget.controller!.value.size.width,
                      height: widget.controller!.value.size.height,
                      child: VideoPlayer(widget.controller!),
                    ),
                  ),
                ),
              )
            else if (widget.isLoading || widget.controller != null)
              Container(
                color: isWideScreen ? Colors.transparent : Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),

            // Tap detector for play/pause
            GestureDetector(
              onTap: () {
                if (widget.controller != null &&
                    widget.controller!.value.isInitialized) {
                  if (widget.controller!.value.isPlaying) {
                    widget.controller!.pause();
                  } else {
                    widget.controller!.play();
                  }
                  setState(() {});
                }
              },
              child: Container(color: Colors.transparent),
            ),

            /// 🔥 BACK BUTTON
            if (widget.enableBackArrow)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                child: const CustomBackButton(),
              ),

            if (widget.controller != null &&
                widget.controller!.value.isInitialized &&
                !widget.controller!.value.isPlaying)
              const Center(
                child: Icon(Icons.play_arrow, color: Colors.white, size: 80),
              ),
          ],
        );
      },
    );
  }
}
