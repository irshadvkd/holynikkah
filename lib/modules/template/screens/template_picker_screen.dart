import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
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
        child: CircularProgressIndicator(color: AppColors.primary),
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
      backgroundColor: AppColors.secondary,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.secondaryLight,
                AppColors.secondary,
                AppColors.background,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Column(
                children: [
                  _header(),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: Consumer<TemplateProvider>(
                      builder: (context, provider, _) => _body(provider),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
              size: 18.sp,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            'Choose a Template',
            style: AppTypography.headline(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 40.w),
      ],
    );
  }

  Widget _body(TemplateProvider provider) {
    switch (provider.listStatus) {
      case TemplateLoadStatus.loading:
      case TemplateLoadStatus.idle:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
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
          Icon(Icons.cloud_off, size: 48.sp, color: AppColors.textSecondary),
          SizedBox(height: 12.h),
          Text(
            provider.listError ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(color: AppColors.textSecondary),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => provider.loadTemplates(forceReload: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Retry',
              style: AppTypography.button(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
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
        style: AppTypography.bodyMedium(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _grid(List<TemplateSummary> templates) {
    return GridView.builder(
      itemCount: templates.length,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 24.h),
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
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
            color: AppColors.black.withValues(alpha: 0.35),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.r),
        child: Stack(
          children: [
            Positioned.fill(
              child: (template.thumbnail?.isNotEmpty ?? false)
                  ? CustomNetworkImage(
                      url: template.thumbnail!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppColors.inputBackground,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_outlined,
                        color: AppColors.textSecondary.withValues(alpha: 0.4),
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
                      AppColors.background.withValues(alpha: 0.95),
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
                height: 40.h,
                child: ElevatedButton(
                  onPressed: () => _openTemplate(template),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Use Now',
                    style: AppTypography.button(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
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
