import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/modules/template/screens/vip_template_1.dart';
import 'package:holynikkah/modules/template/screens/vip_template_2.dart';

class MyTemplateScreen extends StatefulWidget {
  const MyTemplateScreen({super.key});

  @override
  State<MyTemplateScreen> createState() => _MyTemplateScreenState();
}

class _MyTemplateScreenState extends State<MyTemplateScreen> {
  bool isVipSelected = true;

  /// VIP Templates
  final List vipTemplates = [
    {"id": "1", "image": "assets/sample/template/vip_1_template.png"},
    {"id": "2", "image": "assets/sample/template/vip_2_template.png"},
  ];

  /// Normal Templates
  final List normalTemplates = [
    {"id": "1", "image": "assets/sample/template/vip_1_template.png"},
  ];

  @override
  Widget build(BuildContext context) {
    /// Selected list
    final templates = isVipSelected ? vipTemplates : normalTemplates;

    return Scaffold(
      backgroundColor: Colors.white,

      /// App Bar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF032544)),
        ),
        title: Text(
          "My Templates",
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF032544),
          ),
        ),
      ),

      /// Body
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            /// Top Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isVipSelected = true;
                      });
                    },
                    child: Container(
                      height: 48.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isVipSelected
                            ? const Color(0xFF032544)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isVipSelected
                              ? const Color(0xFF032544)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        "VIP Template",
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: isVipSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 14.w),

                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isVipSelected = false;
                      });
                    },
                    child: Container(
                      height: 48.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !isVipSelected
                            ? const Color(0xFF032544)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: !isVipSelected
                              ? const Color(0xFF032544)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        "Template",
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: !isVipSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            /// Templates Grid
            Expanded(
              child: GridView.builder(
                itemCount: templates.length,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                          color: Colors.black.withOpacity(0.08),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Stack(
                        children: [
                          /// Template Image
                          Positioned.fill(
                            child: Image.asset(
                              templates[index]['image'],
                              fit: BoxFit.cover,
                            ),
                          ),

                          /// Bottom Gradient
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: 90.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          /// Use Now Button
                          Positioned(
                            left: 12.w,
                            right: 12.w,
                            bottom: 12.h,
                            child: SizedBox(
                              height: 42.h,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (templates[index]['id'] == "1") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            VipTemplateOneScreen(),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            VipTemplateTwoScreen(),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF032544),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Text(
                                  "Use Now",
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
