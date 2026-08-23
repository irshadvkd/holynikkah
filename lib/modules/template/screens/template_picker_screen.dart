import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/core/widgets/custom_network_image.dart';
import 'package:holynikkah/modules/template/models/template_summary.dart';
import 'package:holynikkah/modules/template/providers/template_provider.dart';
import 'package:holynikkah/modules/template/screens/template_renderer_screen.dart';
import 'package:provider/provider.dart';

/// Catalog of published templates for the signed-in user's tier. Picking one
/// opens the renderer to fill + save it. Pops `true` once a template is saved.
class TemplatePickerScreen extends StatefulWidget {
  const TemplatePickerScreen({super.key, required this.isVip});

  final bool isVip;

  @override
  State<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends State<TemplatePickerScreen> {
  static const Color _primary = Color(0xFF032544);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<TemplateProvider>()
          .selectType(widget.isVip ? 'vip' : 'normal', forceReload: true);
    });
  }

  Future<void> _openTemplate(TemplateSummary summary) async {
    final provider = context.read<TemplateProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _primary),
      ),
    );

    final definition = await provider.loadTemplate(summary.id);

    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loader

    if (definition == null) {
      CommonSnackBar.showError(
        context,
        provider.detailError ?? 'Could not open template',
      );
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TemplateRendererScreen(
          template: definition,
          isVip: widget.isVip,
        ),
      ),
    );

    if (!mounted) return;
    if (saved == true) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: _primary),
        ),
        title: Text(
          'Choose a Template',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Consumer<TemplateProvider>(
          builder: (context, provider, _) => _body(provider),
        ),
      ),
    );
  }

  Widget _body(TemplateProvider provider) {
    switch (provider.listStatus) {
      case TemplateLoadStatus.loading:
      case TemplateLoadStatus.idle:
        return const Center(
          child: CircularProgressIndicator(color: _primary),
        );
      case TemplateLoadStatus.error:
        return _errorState(provider);
      case TemplateLoadStatus.success:
        if (provider.templates.isEmpty) return _emptyState();
        return _grid(provider.templates);
    }
  }

  Widget _errorState(TemplateProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 48.sp, color: Colors.grey),
          SizedBox(height: 12.h),
          Text(
            provider.listError ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black54),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => provider.loadTemplates(forceReload: true),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: Text(
              'Retry',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Text(
        'No templates available',
        style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black54),
      ),
    );
  }

  Widget _grid(List<TemplateSummary> templates) {
    return GridView.builder(
      itemCount: templates.length,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) => _templateCard(templates[index]),
    );
  }

  Widget _templateCard(TemplateSummary template) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            Positioned.fill(
              child: (template.thumbnail?.isNotEmpty ?? false)
                  ? CustomNetworkImage(
                      url: template.thumbnail!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_outlined,
                        color: Colors.grey.shade400,
                        size: 32.sp,
                      ),
                    ),
            ),
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
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12.w,
              right: 12.w,
              bottom: 12.h,
              child: SizedBox(
                height: 42.h,
                child: ElevatedButton(
                  onPressed: () => _openTemplate(template),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Use Now',
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
  }
}
