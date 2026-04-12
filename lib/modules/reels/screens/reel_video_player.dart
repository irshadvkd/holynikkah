import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:holynikkah/core/widgets/custom_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

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
  late VideoPlayerController _controller;

  bool _isPlaying = false;
  bool _videoInitialized = false;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeController();
  }

  initializeController() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _controller.setLooping(true); // Set video to loop
          _controller.play();
          _videoInitialized = true;
        });
      });

    _controller.addListener(() {
      if (_controller.value.isPlaying && !_isPlaying) {
        // Video has started playing
        setState(() {
          _isPlaying = true;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App is in the foreground
      _controller.play();
    } else if (state == AppLifecycleState.inactive) {
      // App is partially obscured
      _controller.pause();
    } else if (state == AppLifecycleState.paused) {
      // App is in the background
      _controller.pause();
    } else if (state == AppLifecycleState.detached) {
      // App is terminated
      _controller.dispose();
    }
  }

  @override
  void dispose() {
    if (mounted) {
      _controller.dispose();
    } // Dispose of the controller when done
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (_videoInitialized) {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                    _isPlaying = false;
                  } else {
                    _controller.play();
                    _isPlaying = true;
                  }
                });
              }
            },
            child: Stack(
              alignment: AlignmentDirectional.bottomEnd,
              children: [
                _videoInitialized == false
                    // when the video is not initialized you can set a thumbnail.
                    // to make it simple, I use CircularProgressIndicator
                    ? SizedBox(
                        height: double.infinity,
                        child: (widget.thumbnail.isNotEmpty)
                            ? CustomNetworkImage(
                                url: widget.thumbnail,
                                fit: BoxFit.fitHeight,
                              )
                            : Container(color: Colors.grey[300]),
                      )
                    : VideoPlayer(_controller),
                if (_videoInitialized == false)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  ),
                if (_isPlaying == false)
                  const Center(
                    child: Icon(
                      Icons.play_arrow,
                      size: 50.0,
                      color: Colors.white,
                    ),
                  ),
                if (_videoInitialized == true)
                  VideoProgressIndicator(
                    padding: const EdgeInsets.only(top: 3),
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.black,
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}
