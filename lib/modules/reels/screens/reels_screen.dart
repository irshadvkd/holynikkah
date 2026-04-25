import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:holynikkah/models/video_model.dart';
import 'package:flutter/services.dart';

class ReelsScreen extends StatefulWidget {
  final bool isBackArrowEnabled;
  const ReelsScreen({super.key, this.isBackArrowEnabled = false});

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
            "https://raw.githubusercontent.com/irshadvkd/holynikkah/main/assets/sample/reel1.mp4"
          ],
          "subtitle": "SampleLib",
          "thumb": "https://picsum.photos/400/600",
          "title": "Sample Video 1"
        },
        {
          "description": "Sample test video 2",
          "sources": [
            "https://raw.githubusercontent.com/irshadvkd/holynikkah/main/assets/sample/reel2.mp4"
          ],
          "subtitle": "SampleLib",
          "thumb": "https://picsum.photos/401/600",
          "title": "Sample Video 2"
        },
        {
          "description": "Sample test video 3",
          "sources": [
            "https://raw.githubusercontent.com/irshadvkd/holynikkah/main/assets/sample/reel3.mp4"
          ],
          "subtitle": "SampleLib",
          "thumb": "https://picsum.photos/402/600",
          "title": "Sample Video 3"
        },
        {
          "description": "Sample test video 4",
          "sources": [
            "https://raw.githubusercontent.com/irshadvkd/holynikkah/main/assets/sample/reel4.mp4"
          ],
          "subtitle": "SampleLib",
          "thumb": "https://picsum.photos/402/600",
          "title": "Sample Video 4"
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
        controller
            .initialize()
            .then((_) {
              if (mounted) {
                controller.setVolume(1.0);
                controller.setLooping(true);
                if (i == 0) {
                  setState(() {});
                  controller.play();
                }
              }
            })
            .catchError((error) {
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
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: pageController,
        scrollDirection: Axis.vertical,
        itemCount: videos.length,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });

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
            enableBackArrow: widget.isBackArrowEnabled,
          );
        },
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
          color: Colors.black.withOpacity(0.5),
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
  final bool enableBackArrow;

  const ReelItem({
    super.key,
    required this.video,
    required this.isActive,
    this.controller,
    this.enableBackArrow = false,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  bool isLiked = false;

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

        /// 🔥 BACK BUTTON ADDED
        if (widget.enableBackArrow)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: const CustomBackButton(),
          ),

        if (widget.controller != null &&
            widget.controller!.value.isInitialized &&
            !widget.controller!.value.isPlaying)
          Center(child: Icon(Icons.play_arrow, color: Colors.white, size: 80)),
      ],
    );
  }
}
