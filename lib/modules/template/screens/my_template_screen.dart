import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/core/widgets/custom_network_image.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/template/models/saved_template.dart';
import 'package:holynikkah/modules/template/providers/template_provider.dart';
import 'package:holynikkah/modules/template/screens/template_picker_screen.dart';
import 'package:holynikkah/modules/template/screens/template_renderer_screen.dart';
import 'package:provider/provider.dart';

class MyTemplateScreen extends StatefulWidget {
  const MyTemplateScreen({
    super.key,
    this.isGate = false,
    this.gateIsVip,
  });

  /// When true the screen is used as the post-category selection gate (a tab
  /// body) instead of a pushed page: the back button is hidden and the user
  /// must set a default template to proceed.
  final bool isGate;

  /// Explicit tier when used as a gate (avoids ambiguity if both tiers are
  /// logged in). Falls back to the VIP login flag when null.
  final bool? gateIsVip;

  @override
  State<MyTemplateScreen> createState() => _MyTemplateScreenState();
}

class _MyTemplateScreenState extends State<MyTemplateScreen> {
  bool? _isVipSelected;

  bool get _isVip {
    if (widget.gateIsVip != null) return widget.gateIsVip!;
    final auth = context.read<AuthProvider>();
    if (auth.isVipLoggedIn && !auth.isNormalLoggedIn) return true;
    if (auth.isNormalLoggedIn && !auth.isVipLoggedIn) return false;
    return _isVipSelected ?? auth.isVipLoggedIn;
  }

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (widget.gateIsVip != null) {
      _isVipSelected = widget.gateIsVip;
    } else if (auth.isVipLoggedIn && !auth.isNormalLoggedIn) {
      _isVipSelected = true;
    } else if (auth.isNormalLoggedIn && !auth.isVipLoggedIn) {
      _isVipSelected = false;
    } else {
      _isVipSelected = auth.isVipLoggedIn;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSaved());
  }

  @override
  void didUpdateWidget(covariant MyTemplateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gateIsVip != oldWidget.gateIsVip) {
      final auth = context.read<AuthProvider>();
      if (widget.gateIsVip != null) {
        _isVipSelected = widget.gateIsVip;
      } else if (auth.isVipLoggedIn && !auth.isNormalLoggedIn) {
        _isVipSelected = true;
      } else if (auth.isNormalLoggedIn && !auth.isVipLoggedIn) {
        _isVipSelected = false;
      } else {
        _isVipSelected = auth.isVipLoggedIn;
      }
      _loadSaved();
    }
  }

  void _toggleVip(bool isVip) {
    if (_isVipSelected == isVip) return;
    setState(() {
      _isVipSelected = isVip;
    });
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final auth = context.read<AuthProvider>();
    await auth.ensureApiTokenFor(isVip: _isVip);
    if (!mounted) return;
    await context
        .read<TemplateProvider>()
        .loadSavedTemplates(isVip: _isVip);
  }

  Future<void> _addTemplate() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TemplatePickerScreen(isVip: _isVip),
      ),
    );
    if (!mounted) return;
    if (saved != true) return;

    await _loadSaved();
    if (!mounted) return;

    // In the onboarding gate, a freshly created template is auto-selected on
    // the server + session so we jump straight to Matches.
    if (widget.isGate) await _autoSelectAfterCreate();
  }

  /// Picks the newly created (default) saved template, persists the selection
  /// on the server + session, then lets the home gate advance to Matches.
  Future<void> _autoSelectAfterCreate() async {
    final isVip = _isVip;
    final provider = context.read<TemplateProvider>();
    final auth = context.read<AuthProvider>();

    final templates = provider.savedTemplates;
    if (templates.isEmpty) return;

    final chosen = templates.firstWhere(
      (t) => t.isDefault,
      orElse: () => templates.first,
    );

    await auth.ensureApiTokenFor(isVip: isVip);
    if (chosen.templateId.isNotEmpty) {
      await provider.selectTemplate(isVip: isVip, templateId: chosen.templateId);
      if (!mounted) return;
    }

    isVip
        ? await auth.updateStoredVipTemplateSelected(true)
        : await auth.updateStoredNormalTemplateSelected(true);
    await provider.markTemplateSelected(isVip: isVip);
  }

  Future<void> _openSaved(SavedTemplate saved) async {
    final provider = context.read<TemplateProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final detail = await provider.openSavedTemplate(
      isVip: _isVip,
      id: saved.id,
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loader

    if (detail == null) {
      CommonSnackBar.showError(
        context,
        provider.detailError ?? 'Could not open template',
      );
      return;
    }

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TemplateRendererScreen(
          template: detail.definition,
          isVip: _isVip,
          savedTemplateId: detail.id,
          savedName: detail.name,
          initialValues: detail.values,
          initialImageUrl: detail.previewImage ?? saved.thumbnail,
          initialSlots: detail.slots,
        ),
      ),
    );

    if (!mounted) return;
    if (updated == true) _loadSaved();
  }

  Future<void> _makeDefault(SavedTemplate saved) async {
    final isVip = _isVip;
    final provider = context.read<TemplateProvider>();
    final auth = context.read<AuthProvider>();

    final ok =
        await provider.makeSavedTemplateDefault(isVip: isVip, id: saved.id);
    if (!mounted) return;
    if (!ok) {
      CommonSnackBar.showError(context, 'Could not set default');
      return;
    }

    // Persist the chosen template on the server (best-effort).
    if (saved.templateId.isNotEmpty) {
      await auth.ensureApiTokenFor(isVip: isVip);
      await provider.selectTemplate(isVip: isVip, templateId: saved.templateId);
      if (!mounted) return;
    }

    // Mark the tier selected + persist on the stored user so any gate
    // watching this flag advances straight to Matches.
    isVip
        ? await auth.updateStoredVipTemplateSelected(true)
        : await auth.updateStoredNormalTemplateSelected(true);
    await provider.markTemplateSelected(isVip: isVip);

    if (!mounted) return;
    if (!widget.isGate) {
      CommonSnackBar.showSuccess(context, 'Set as default');
    }
  }

  Future<void> _delete(SavedTemplate saved) async {
    final name = saved.name.isEmpty ? 'this template' : '"${saved.name}"';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
          side: const BorderSide(color: AppColors.inputBorder),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: const BoxDecoration(
                  color: Color(0x1AEF5350),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline,
                    color: AppColors.error, size: 24.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                'Delete template',
                style: AppTypography.headline(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Delete $name? This action cannot be undone.',
                style: AppTypography.bodySmall(
                  color: AppColors.textSecondary,
                ).copyWith(height: 1.4),
              ),
              SizedBox(height: 22.h),
              Row(
                children: [
                  Expanded(
                    child: _dialogButton('Cancel', () => Navigator.pop(ctx, false)),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _dialogButton(
                      'Delete',
                      () => Navigator.pop(ctx, true),
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true || !mounted) return;

    final ok = await context
        .read<TemplateProvider>()
        .deleteSavedTemplate(isVip: _isVip, id: saved.id);
    if (!mounted) return;
    ok
        ? CommonSnackBar.showSuccess(context, 'Template deleted')
        : CommonSnackBar.showError(context, 'Could not delete template');
  }

  Widget _dialogButton(String label, VoidCallback onTap, {Color? color}) {
    final filled = color != null;
    return SizedBox(
      height: 46.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: filled ? color : AppColors.inputBackground,
          foregroundColor: filled ? AppColors.white : AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
            side: BorderSide(
              color: filled ? Colors.transparent : AppColors.inputBorder,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.button(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final showTabs = !widget.isGate && auth.isVipLoggedIn && auth.isNormalLoggedIn;

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
                  if (showTabs) ...[
                    _tabSelector(),
                    SizedBox(height: 18.h),
                  ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTemplate,
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: AppColors.onPrimary),
        label: Text(
          'Add Template',
          style: AppTypography.button(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        if (!widget.isGate) ...[
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
        ],
        Expanded(
          child: Text(
            widget.isGate ? 'Choose Your Template' : 'My Templates',
            style: AppTypography.headline(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
            textAlign: widget.isGate ? TextAlign.center : TextAlign.left,
          ),
        ),
        if (!widget.isGate) SizedBox(width: 40.w),
      ],
    );
  }

  Widget _tabSelector() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleVip(true),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 42.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: _isVip
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: _isVip
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  "VIP Template",
                  style: AppTypography.bodyMedium(
                    fontWeight: FontWeight.w700,
                    color: _isVip ? AppColors.onPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleVip(false),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 42.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: !_isVip
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: !_isVip
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  "Template",
                  style: AppTypography.bodyMedium(
                    fontWeight: FontWeight.w700,
                    color: !_isVip ? AppColors.onPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(TemplateProvider provider) {
    switch (provider.savedStatus) {
      case TemplateLoadStatus.loading:
      case TemplateLoadStatus.idle:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      case TemplateLoadStatus.error:
        return _errorState(provider);
      case TemplateLoadStatus.success:
        if (provider.savedTemplates.isEmpty) return _emptyState();
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.secondary,
          onRefresh: _loadSaved,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isGate) _gateHint(provider.savedTemplates),
              Expanded(child: _grid(provider.savedTemplates)),
            ],
          ),
        );
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
            provider.savedError ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(color: AppColors.textSecondary),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _loadSaved,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 56.sp,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          SizedBox(height: 12.h),
          Text(
            'No saved templates yet',
            style: AppTypography.subTitle(
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            widget.isGate
                ? 'Tap "Add Template" to create one, then set it as\ndefault to continue.'
                : 'Tap "Add Template" to create your first one.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _gateHint(List<SavedTemplate> templates) {
    final hasDefault = templates.any((t) => t.isDefault);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: hasDefault
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.inputBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasDefault ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 20.sp,
            color: hasDefault ? AppColors.primary : AppColors.textTertiary,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              hasDefault
                  ? 'Default template set. Open Matches from the menu below.'
                  : 'Set a template as default (⋮ menu) to continue.',
              style: AppTypography.bodySmall(
                fontWeight: FontWeight.w500,
                color: hasDefault ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(List<SavedTemplate> templates) {
    return GridView.builder(
      itemCount: templates.length,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.only(bottom: 80.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) => _savedCard(templates[index]),
    );
  }

  Widget _savedCard(SavedTemplate template) {
    return GestureDetector(
      onTap: () => _openSaved(template),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: template.isDefault ? AppColors.primary : AppColors.inputBorder,
            width: template.isDefault ? 1.5 : 1,
          ),
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
                          Icons.description_outlined,
                          color: AppColors.textSecondary.withValues(alpha: 0.4),
                          size: 36.sp,
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
              if (template.isDefault)
                Positioned(
                  left: 10.w,
                  top: 10.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      'Default',
                      style: AppTypography.caption(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 4.w,
                top: 4.h,
                child: _menu(template),
              ),
              Positioned(
                left: 12.w,
                right: 12.w,
                bottom: 12.h,
                child: Text(
                  template.name.isEmpty ? 'Untitled' : template.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menu(SavedTemplate template) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.65),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_vert_rounded, color: AppColors.primary),
      ),
      color: AppColors.secondary,
      surfaceTintColor: AppColors.secondary,
      elevation: 8,
      shadowColor: AppColors.black.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: const BorderSide(color: AppColors.inputBorder),
      ),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        switch (value) {
          case 'default':
            _makeDefault(template);
            break;
          case 'delete':
            _delete(template);
            break;
        }
      },
      itemBuilder: (_) => [
        if (!template.isDefault)
          PopupMenuItem(
            value: 'default',
            height: 44.h,
            child: _menuRow(
              icon: Icons.push_pin_outlined,
              label: 'Set as default',
              color: AppColors.primary,
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          height: 44.h,
          child: _menuRow(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: color),
        SizedBox(width: 10.w),
        Text(
          label,
          style: AppTypography.bodySmall(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
