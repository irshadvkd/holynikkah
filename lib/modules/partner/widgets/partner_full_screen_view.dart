import 'package:flutter/material.dart';

class PartnerFullScreenView extends StatelessWidget {
  final List<String> imageUrls;
  const PartnerFullScreenView({super.key, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      /// 🔥 Vertical swipe (Reels style)
      body: SafeArea(
        child: PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: imageUrls.length,
          itemBuilder: (context, index) {
            return Image.asset(imageUrls[index], fit: BoxFit.fitHeight);
          },
        ),
      ),
    );
  }
}
