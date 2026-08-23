import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
  static const Color _primary = Color(0xFF032544);

  bool? _isVipSelected;

  bool get _isVip =>
      _isVipSelected ?? (widget.gateIsVip ?? context.read<AuthProvider>().isVipLoggedIn);

  @override
  void initState() {
    super.initState();
    _isVipSelected = widget.gateIsVip ?? context.read<AuthProvider>().isVipLoggedIn;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSaved());
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
        child: CircularProgressIndicator(color: _primary),
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
        backgroundColor: Colors.white,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
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
                    color: Colors.red.shade400, size: 24.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                'Delete template',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Delete $name? This action cannot be undone.',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: Colors.black54,
                  height: 1.4,
                ),
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
                      color: Colors.red.shade400,
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
          backgroundColor: filled ? color : Colors.grey.shade100,
          foregroundColor: filled ? Colors.white : _primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: !widget.isGate,
        leading: widget.isGate
            ? null
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: _primary),
              ),
        title: Text(
          widget.isGate ? 'Choose Your Template' : 'My Templates',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTemplate,
        backgroundColor: _primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Template',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleVip(true),
                    child: Container(
                      height: 48.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _isVip
                            ? _primary
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: _isVip
                              ? _primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        "VIP Template",
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: _isVip ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleVip(false),
                    child: Container(
                      height: 48.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !_isVip
                            ? _primary
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: !_isVip
                              ? _primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        "Template",
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: !_isVip ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: Consumer<TemplateProvider>(
                builder: (context, provider, _) => _body(provider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(TemplateProvider provider) {
    switch (provider.savedStatus) {
      case TemplateLoadStatus.loading:
      case TemplateLoadStatus.idle:
        return const Center(
          child: CircularProgressIndicator(color: _primary),
        );
      case TemplateLoadStatus.error:
        return _errorState(provider);
      case TemplateLoadStatus.success:
        if (provider.savedTemplates.isEmpty) return _emptyState();
        return RefreshIndicator(
          color: _primary,
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
          Icon(Icons.cloud_off, size: 48.sp, color: Colors.grey),
          SizedBox(height: 12.h),
          Text(
            provider.savedError ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black54),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _loadSaved,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_border, size: 56.sp, color: Colors.grey),
          SizedBox(height: 12.h),
          Text(
            'No saved templates yet',
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            widget.isGate
                ? 'Tap "Add Template" to create one, then set it as\ndefault to continue.'
                : 'Tap "Add Template" to create your first one.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _gateHint(List<SavedTemplate> templates) {
    final hasDefault = templates.any((t) => t.isDefault);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(
            hasDefault ? Icons.check_circle : Icons.info_outline,
            size: 18.sp,
            color: _primary,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              hasDefault
                  ? 'Default template set. Open Matches from the menu below.'
                  : 'Set a template as default (⋮ menu) to continue.',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: _primary,
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
                          Icons.description_outlined,
                          color: Colors.grey.shade400,
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
                        Colors.black.withValues(alpha: 0.75),
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
                      color: _primary,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Default',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 2.w,
                top: 2.h,
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
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14.sp,
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
      icon: const Icon(Icons.more_vert, color: Colors.white),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
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
              color: _primary,
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          height: 44.h,
          child: _menuRow(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: Colors.red.shade400,
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
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
