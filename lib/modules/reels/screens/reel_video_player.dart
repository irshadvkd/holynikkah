import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/widgets/custom_network_image.dart';
import 'package:holynikkah/modules/reels/services/reel_video_loader.dart';
import 'package:video_player/video_player.dart';

class ReelVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnail;
  const ReelVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.thumbnail,
  });

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;

  bool _isPlaying = false;
  bool _videoInitialized = false;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeController();
  }

  Future<void> initializeController() async {
    try {
      final file = await ReelVideoLoader.getCachedFile(widget.videoUrl);
      if (!mounted) return;

      final controller = VideoPlayerController.file(file);
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;
      await controller.setLooping(true);
      await controller.play();

      controller.addListener(() {
        if (!mounted || _controller == null) return;
        if (_controller!.value.isPlaying && !_isPlaying) {
          setState(() {
            _isPlaying = true;
          });
        }
      });

      if (mounted) {
        setState(() {
          _videoInitialized = true;
          _isPlaying = controller.value.isPlaying;
        });
      }
    } catch (e, stack) {
      AppLogger.error(
        'Failed to initialize video player for ${widget.videoUrl}: $e',
        tag: 'ReelVideoPlayer',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_videoInitialized || _controller == null) return;
    if (state == AppLifecycleState.resumed) {
      _controller?.play();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller?.pause();
    } else if (state == AppLifecycleState.detached) {
      _controller?.dispose();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_videoInitialized && _controller != null) {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final screenAspect = screenWidth / (screenHeight > 0 ? screenHeight : 1);
        final isWideScreen = screenAspect > 0.62;

        final isInit = _videoInitialized && _controller != null;
        final videoSize = isInit ? _controller!.value.size : null;
        final videoAspect = (videoSize != null && videoSize.height > 0)
            ? videoSize.width / videoSize.height
            : 9 / 16;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Ambient Background Layer (tablets/iPads or wide screens)
            if (isWideScreen) ...[
              if (widget.thumbnail.isNotEmpty)
                CustomNetworkImage(
                  url: widget.thumbnail,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              else if (isInit)
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
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
              // Standard phone placeholder
              if (!isInit && widget.thumbnail.isNotEmpty)
                CustomNetworkImage(
                  url: widget.thumbnail,
                  fit: BoxFit.cover,
                ),
            ],

            // 2. Main video / thumbnail in foreground
            GestureDetector(
              onTap: () {
                if (isInit) {
                  setState(() {
                    if (_controller!.value.isPlaying) {
                      _controller!.pause();
                      _isPlaying = false;
                    } else {
                      _controller!.play();
                      _isPlaying = true;
                    }
                  });
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Stack(
                alignment: AlignmentDirectional.bottomEnd,
                children: [
                  if (!isInit)
                    if (widget.thumbnail.isNotEmpty)
                      Center(
                        child: AspectRatio(
                          aspectRatio: isWideScreen ? videoAspect : screenAspect,
                          child: CustomNetworkImage(
                            url: widget.thumbnail,
                            fit: isWideScreen ? BoxFit.contain : BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(color: isWideScreen ? Colors.transparent : Colors.black)
                  else
                    Center(
                      child: AspectRatio(
                        aspectRatio: isWideScreen ? videoAspect : screenAspect,
                        child: FittedBox(
                          fit: isWideScreen ? BoxFit.contain : BoxFit.cover,
                          child: SizedBox(
                            width: _controller!.value.size.width,
                            height: _controller!.value.size.height,
                            child: VideoPlayer(_controller!),
                          ),
                        ),
                      ),
                    ),

                  if (!isInit)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    ),

                  if (isInit && !_isPlaying)
                    const Center(
                      child: Icon(
                        Icons.play_arrow,
                        size: 60.0,
                        color: Colors.white,
                      ),
                    ),

                  if (isInit)
                    VideoProgressIndicator(
                      padding: const EdgeInsets.only(top: 3),
                      _controller!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.amber,
                        bufferedColor: Colors.white30,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
