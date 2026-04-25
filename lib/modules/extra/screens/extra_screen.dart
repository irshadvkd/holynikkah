import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/modules/reels/screens/reels_screen.dart';

class ExtraScreen extends StatelessWidget {
  const ExtraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReelsScreen(isBackArrowEnabled: true),
                      ),
                    );
                  },
                  child: Image.asset(
                    "assets/icons/extra/wedding.png",
                    width: 250.w,
                  ),
                ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReelsScreen(isBackArrowEnabled: true),
                      ),
                    );
                  },
                  child: Image.asset(
                    "assets/icons/extra/mehandi.png",
                    width: 250.w,
                  ),
                ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReelsScreen(isBackArrowEnabled: true),
                      ),
                    );
                  },
                  child: Image.asset(
                    "assets/icons/extra/invitation.png",
                    width: 250.w,
                  ),
                ),
                SizedBox(height: 20.h),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReelsScreen(isBackArrowEnabled: true),
                      ),
                    );
                  },
                  child: Image.asset(
                    "assets/icons/extra/styles.png",
                    width: 250.w,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
