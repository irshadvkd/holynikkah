import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:holynikkah/models/video_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  PageController pageController = PageController();
  List<VideoModel> videos = [];
  int currentIndex = 0;
  Map<int, VideoPlayerController> controllers = {};

  @override
  void initState() {
    super.initState();
    // Configure audio session for video playback
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    loadVideos();
  }

  void loadVideos() {
    const jsonData = '''
{
  "categories": [
    {
      "name": "Movies",
      "videos": [
        {
          "description": "Sample test video 1",
          "sources": [
            "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4"
          ],
          "subtitle": "SampleLib",
          "thumb": "https://picsum.photos/400/600",
          "title": "Sample Video 1"
        },
        {
          "description": "Sample test video 2",
          "sources": [
            "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4"
          ],
          "subtitle": "SampleLib",
          "thumb": "https://picsum.photos/401/600",
          "title": "Sample Video 2"
        },
        {
          "description": "Sample test video 3",
          "sources": [
            "https://sample-videos.com/zip/10/mp4/SampleVideo_360x240_1mb.mp4"
          ],
          "subtitle": "SampleLib",
          "thumb": "https://picsum.photos/402/600",
          "title": "Sample Video 3"
        }
      ]
    }
  ]
}
''';

    final data = json.decode(jsonData);
    final categories = (data['categories'] as List)
        .map((cat) => CategoryModel.fromJson(cat))
        .toList();

    setState(() {
      videos = categories.first.videos;
    });
    preloadVideos();
  }

  void preloadVideos() {
    for (int i = 0; i < videos.length && i < 3; i++) {
      if (!controllers.containsKey(i) && videos[i].sources.isNotEmpty) {
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(videos[i].sources.first),
        );
        controllers[i] = controller;
        controller.initialize().then((_) {
          if (mounted) {
            controller.setVolume(1.0);
            controller.setLooping(true);
            // Only auto-play the first video after proper initialization
            if (i == 0) {
              setState(() {}); // Trigger rebuild to show video
              controller.play();
            }
          }
        }).catchError((error) {
          print('Video error: $error');
        });
      }
    }
  }

  @override
  void dispose() {
    controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: pageController,
        scrollDirection: Axis.vertical,
        itemCount: videos.length,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
          // Preload next videos
          for (int i = index; i < index + 2 && i < videos.length; i++) {
            if (!controllers.containsKey(i) && videos[i].sources.isNotEmpty) {
              final controller = VideoPlayerController.networkUrl(
                Uri.parse(videos[i].sources.first),
              );
              controllers[i] = controller;
              controller.initialize().then((_) {
                if (mounted) {
                  controller.setVolume(1.0);
                  controller.setLooping(true);
                }
              });
            }
          }
        },
        itemBuilder: (context, index) {
          return ReelItem(
            video: videos[index],
            isActive: index == currentIndex,
            controller: controllers[index],
          );
        },
      ),
    );
  }
}

class ReelItem extends StatefulWidget {
  final VideoModel video;
  final bool isActive;
  final VideoPlayerController? controller;

  const ReelItem({super.key, required this.video, required this.isActive, this.controller});

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    // Remove auto-play from initState - let it be handled by didUpdateWidget
  }

  @override
  void didUpdateWidget(ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller!.value.isInitialized) {
      if (widget.isActive && !oldWidget.isActive) {
        widget.controller!.setVolume(1.0);
        widget.controller!.play();
        widget.controller!.setLooping(true);
      } else if (!widget.isActive && oldWidget.isActive) {
        widget.controller!.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background thumbnail
        if (widget.video.thumb.isNotEmpty)
          Image.network(
            widget.video.thumb,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.white),
                ),
              );
            },
          ),

        // Video player overlay
        if (widget.controller != null && widget.controller!.value.isInitialized)
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
        else if (widget.controller != null)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

        // Tap to play/pause
        GestureDetector(
          onTap: () {
            if (widget.controller != null && widget.controller!.value.isInitialized) {
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

        // Bottom content area
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isLiked = !isLiked;
                              });
                            },
                            child: SvgPicture.asset(
                              'assets/icons/like.svg',
                              width: 32,
                              height: 32,
                              colorFilter: ColorFilter.mode(
                                isLiked ? Colors.red : Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '1.2K',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => Container(
                                  height: 300,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Comments',
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text('No comments yet'),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: SvgPicture.asset(
                              'assets/icons/comment.svg',
                              width: 32,
                              height: 32,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '89',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Share.share('Check out this video!');
                            },
                            child: SvgPicture.asset(
                              'assets/icons/share.svg',
                              width: 32,
                              height: 32,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '45',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Play/pause overlay
        if (widget.controller != null &&
            widget.controller!.value.isInitialized &&
            !widget.controller!.value.isPlaying)
          Center(child: Icon(Icons.play_arrow, color: Colors.white, size: 80)),
      ],
    );
  }
}