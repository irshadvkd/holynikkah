import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:holynikkah/core/theme/context_extension.dart';

class CustomNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;

  const CustomNetworkImage({
    super.key,
    required this.url,
    this.fit,
    this.errorWidget,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      // height: height,
      fit: fit ?? BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 1000),
      placeholder: (context, url) {
        return Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHighlight,
          child: Container(color: Colors.grey),
        );
      },
      errorWidget: (context, url, error) {
        return errorWidget ??
            Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
      },
    );
  }
}
