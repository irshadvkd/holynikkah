import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/utils/app_logger.dart';
import 'package:holynikkah/core/utils/utils.dart';
import 'package:holynikkah/core/widgets/common_button.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/template/models/template_definition.dart';
import 'package:holynikkah/modules/template/models/template_element.dart';
import 'package:holynikkah/modules/template/models/template_field.dart';
import 'package:holynikkah/modules/template/models/template_style.dart';
import 'package:holynikkah/modules/template/providers/template_provider.dart';
import 'package:holynikkah/modules/template/screens/common_image_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

/// Generic, server-driven renderer.
///
/// Builds page 1 (the input form, from [TemplateDefinition.fields]) and page 2
/// (the preview canvas, from [TemplateDefinition.canvas] + `elements`), then
/// exports the canvas as a PNG. A single screen replaces all the hand-coded
/// per-template editors.
class TemplateRendererScreen extends StatefulWidget {
  const TemplateRendererScreen({
    super.key,
    required this.template,
    required this.isVip,
    this.savedTemplateId,
    this.savedName,
    this.initialValues,
    this.initialImageUrl,
    this.initialSlots,
  });

  final TemplateDefinition template;

  /// Tier of the signed-in user — decides the saved-template endpoint prefix.
  final bool isVip;

  /// When set, the editor updates this saved template instead of creating one.
  final String? savedTemplateId;

  /// Pre-existing name when editing a saved template.
  final String? savedName;

  /// Pre-filled field values (field key → value) when editing a saved template.
  final Map<String, String>? initialValues;

  /// Existing preview/slot image URL when editing a saved template.
  final String? initialImageUrl;

  /// Existing per-slot images (slotId → host-less relative path) when editing a
  /// saved template, so each cell rehydrates without re-picking.
  final Map<String, String>? initialSlots;

  @override
  State<TemplateRendererScreen> createState() => _TemplateRendererScreenState();
}

class _TemplateRendererScreenState extends State<TemplateRendererScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Wraps the preview canvas so it can be exported to a PNG for the server.
  final GlobalKey _previewKey = GlobalKey();

  /// One controller per field, keyed by `field.key`.
  final Map<String, TextEditingController> _controllers = {};

  /// Every `imageSlot` declared by the template, in document order (collected
  /// recursively, including those nested inside `box` elements). The form
  /// renders one picker per entry so any template — 1 slot or many — works.
  late final List<TemplateElement> _imageSlots =
      _collectImageSlots(_template.elements);

  /// User-uploaded photo per slot, keyed by the slot element's `id`.
  final Map<String, File> _slotImages = {};

  /// Existing server images retained per slot (slotId → host-less relative
  /// path). An entry is dropped once the user re-picks that slot, so on save it
  /// becomes the authoritative "keep without re-upload" set.
  late final Map<String, String> _retainedSlots = {
    for (final e in (widget.initialSlots ?? const {}).entries)
      if (e.value.isNotEmpty) e.key: e.value,
  };

  TemplateDefinition get _template => widget.template;

  @override
  void initState() {
    super.initState();
    for (final field in _template.fields) {
      final initial =
          widget.initialValues?[field.key] ?? field.defaultValue ?? '';
      _controllers[field.key] = TextEditingController(text: initial);
    }
    // Warm the image cache so the PNG export captures network backgrounds.
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheImages());
  }

  void _precacheImages() {
    if (!mounted) return;
    for (final url in _networkImageUrls()) {
      precacheImage(NetworkImage(url), context).catchError((_) {});
    }
  }

  List<String> _networkImageUrls() {
    final urls = <String>{};
    if (_hasInitialImage) urls.add(widget.initialImageUrl!);
    for (final path in _retainedSlots.values) {
      if (path.isNotEmpty) urls.add(mediaUrl(path));
    }
    final bg = _template.canvas.background;
    if (bg != null && bg.isImage && (bg.source?.isNotEmpty ?? false)) {
      urls.add(bg.source!);
    }
    void walk(List<TemplateElement> els) {
      for (final el in els) {
        final src = el.style?.source;
        if (src != null && src.isNotEmpty) urls.add(src);
        if (el.children.isNotEmpty) walk(el.children);
      }
    }

    walk(_template.elements);
    return urls.toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _value(String key) => _controllers[key]?.text.trim() ?? '';

  /// True when a previously saved image URL is available to fall back on.
  bool get _hasInitialImage => widget.initialImageUrl?.isNotEmpty ?? false;

  /// Legacy single-slot templates persist only a composite preview; when there
  /// is exactly one slot that saved image can stand in for it while editing.
  /// Multi-slot templates have no per-slot persistence, so this stays false.
  bool get _singleSlotWithInitial =>
      _imageSlots.length == 1 && _hasInitialImage;

  bool _slotFilled(String slotId) =>
      _slotImages[slotId] != null ||
      (_retainedSlots[slotId]?.isNotEmpty ?? false) ||
      _singleSlotWithInitial;

  bool get _allSlotsFilled => _imageSlots.every((s) => _slotFilled(s.id));

  static List<TemplateElement> _collectImageSlots(List<TemplateElement> els) {
    final out = <TemplateElement>[];
    for (final el in els) {
      if (el.type == 'imageSlot') out.add(el);
      if (el.children.isNotEmpty) out.addAll(_collectImageSlots(el.children));
    }
    return out;
  }

  // ─── Navigation between form and preview ──────────────────────────────────

  void _goToPreview() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_allSlotsFilled) {
      CommonSnackBar.showError(
        context,
        _imageSlots.length > 1
            ? 'Please upload all ${_imageSlots.length} photos'
            : 'Please upload an image',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToForm() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickImage(TemplateElement slot) async {
    final picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (image == null) return;

    final ratio = slot.aspectRatio;
    final cropped = await CommonImageCropper.cropImage(
      imagePath: image.path,
      ratioX: ratio ?? 3,
      ratioY: ratio != null ? 1 : 4,
    );
    if (cropped == null) return;

    setState(() {
      _slotImages[slot.id] = cropped;
      // A freshly picked photo replaces any retained server image for this cell.
      _retainedSlots.remove(slot.id);
    });
  }

  Future<void> _saveTemplate() async {
    final values = <String, String>{
      for (final field in _template.fields) field.key: _value(field.key),
    };

    String name = widget.savedName ?? _template.name;
    if (widget.savedTemplateId == null) {
      final entered = await _askName(name);
      if (entered == null) return; // user cancelled
      name = entered;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final previewImage = await _capturePreview();

    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final provider = context.read<TemplateProvider>();
    await auth.ensureApiTokenFor(isVip: widget.isVip);

    final slotImages = Map<String, File>.from(_slotImages);
    final retainedSlots = Map<String, String>.from(_retainedSlots);

    final error = widget.savedTemplateId == null
        ? await provider.createSavedTemplate(
            isVip: widget.isVip,
            templateId: _template.id,
            name: name,
            values: values,
            previewImage: previewImage,
            slotImages: slotImages,
            slots: retainedSlots,
          )
        : await provider.updateSavedTemplate(
            isVip: widget.isVip,
            id: widget.savedTemplateId!,
            name: name,
            values: values,
            previewImage: previewImage,
            slotImages: slotImages,
            slots: retainedSlots,
          );

    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loader

    if (error != null) {
      CommonSnackBar.showError(context, error);
      return;
    }

    CommonSnackBar.showSuccess(context, 'Template saved successfully');
    Navigator.of(context).pop(true);
  }

  /// Renders the preview canvas to a temporary PNG file to upload as the
  /// template sample. Returns `null` if capture fails (save still proceeds).
  Future<File?> _capturePreview() async {
    try {
      final boundary = _previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/template_preview_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (e) {
      AppLogger.warning('Preview capture failed: $e', tag: 'TemplateRenderer');
      return null;
    }
  }

  Future<String?> _askName(String initial) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => _TemplateNameDialog(initial: initial),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.darkGreenGradient,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildFormPage(),
              _buildPreviewPage(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Page 1: form ─────────────────────────────────────────────────────────

  Widget _buildFormPage() {
    return SafeArea(
      child: Column(
        children: [
          _header(
            title: 'Create ${_template.name}',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final field in _template.fields) _buildField(field),
                    for (var i = 0; i < _imageSlots.length; i++)
                      _buildImagePicker(_imageSlots[i], i),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: _primaryButton('Preview', _goToPreview),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TemplateField field) {
    final isDropdown = field.inputType == 'dropdown';
    final isDate = field.inputType == 'date';
    final isMultiline = field.inputType == 'multiline';

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: AppTypography.bodyMedium(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          if (isDropdown)
            _dropdownField(field)
          else if (isDate)
            _dateField(field)
          else
            _textField(field, multiline: isMultiline),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(TemplateField field) {
    return InputDecoration(
      hintText: field.hint ?? 'Enter ${field.label}',
      hintStyle: AppTypography.bodyMedium(
        color: AppColors.textTertiary,
      ),
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: AppColors.error, width: 1.4),
      ),
    );
  }

  Widget _textField(TemplateField field, {bool multiline = false}) {
    return TextFormField(
      controller: _controllers[field.key],
      keyboardType: _keyboardType(field, multiline: multiline),
      inputFormatters: _inputFormatters(field),
      maxLength: field.maxLength,
      maxLines: multiline ? 4 : 1,
      validator: (value) => _validate(field, value),
      style: AppTypography.bodyMedium(color: AppColors.white),
      decoration: _inputDecoration(field).copyWith(counterText: ''),
    );
  }

  Widget _dropdownField(TemplateField field) {
    final controller = _controllers[field.key]!;
    final current = controller.text.isEmpty ? null : controller.text;
    return DropdownButtonFormField<String>(
      initialValue: field.options.contains(current) ? current : null,
      isExpanded: true,
      dropdownColor: AppColors.secondary,
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
      style: AppTypography.bodyMedium(color: AppColors.white),
      items: field.options
          .map((o) => DropdownMenuItem(
                value: o,
                child: Text(
                  o,
                  style: AppTypography.marcellus(
                    fontSize: 14.sp,
                    color: AppColors.white,
                  ),
                ),
              ))
          .toList(),
      onChanged: (value) => controller.text = value ?? '',
      validator: (value) => _validate(field, value),
      decoration: _inputDecoration(field),
    );
  }

  Widget _dateField(TemplateField field) {
    final controller = _controllers[field.key]!;
    return TextFormField(
      controller: controller,
      readOnly: true,
      validator: (value) => _validate(field, value),
      style: AppTypography.bodyMedium(color: AppColors.white),
      decoration: _inputDecoration(field).copyWith(
        suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
      ),
      onTap: () async {
        FocusScope.of(context).unfocus();
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(now.year - 100),
          lastDate: DateTime(now.year + 100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.primary,
                  onPrimary: AppColors.onPrimary,
                  surface: AppColors.secondary,
                  onSurface: AppColors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          controller.text =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }

  Widget _buildImagePicker(TemplateElement slot, int index) {
    final label = _imageSlots.length > 1 ? 'Photo ${index + 1}' : 'Image';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Text(
          label,
          style: AppTypography.bodyMedium(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _pickImage(slot),
          child: Container(
            width: double.infinity,
            height: 180.h,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: _buildImagePickerContent(slot.id),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerContent(String slotId) {
    final file = _slotImages[slotId];
    if (file != null) {
      return _imagePreviewWithBadge(
        ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      );
    }

    final retained = _retainedSlots[slotId];
    final networkUrl = (retained != null && retained.isNotEmpty)
        ? mediaUrl(retained)
        : (_singleSlotWithInitial ? widget.initialImageUrl : null);
    if (networkUrl != null) {
      return _imagePreviewWithBadge(
        ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Image.network(
            networkUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _uploadPlaceholder(),
          ),
        ),
      );
    }
    return _uploadPlaceholder();
  }

  Widget _uploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload_outlined, size: 40.sp, color: AppColors.primary),
        SizedBox(height: 8.h),
        Text(
          'Upload Image',
          style: AppTypography.bodyMedium(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Overlays a "Change" pill on an existing image so the user knows it's
  /// editable.
  Widget _imagePreviewWithBadge(Widget image) {
    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        Positioned(
          right: 8.w,
          bottom: 8.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 13.sp, color: AppColors.primary),
                SizedBox(width: 4.w),
                Text(
                  'Change',
                  style: AppTypography.caption(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Page 2: preview ──────────────────────────────────────────────────────

  Widget _buildPreviewPage() {
    return SafeArea(
      child: Column(
        children: [
          _header(title: 'Preview', onBack: _goToForm),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: RepaintBoundary(
                  key: _previewKey,
                  child: AspectRatio(
                    aspectRatio: _template.canvas.aspectRatio,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        return Stack(
                          children: [
                            _buildBackground(),
                            for (final el in _template.elements)
                              _positioned(el, w, h),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          _previewControls(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    final bg = _template.canvas.background;
    if (bg == null) {
      return Positioned.fill(child: Container(color: Colors.white));
    }
    if (bg.isImage && (bg.source?.isNotEmpty ?? false)) {
      return Positioned.fill(
        child: Image.network(
          bg.source!,
          fit: _boxFit(bg.fit),
          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
        ),
      );
    }
    return Positioned.fill(child: Container(color: _color(bg.color)));
  }

  /// Parses template colors. The admin panel emits 8-digit hex as
  /// `#RRGGBBAA` (e.g. `#000000DE` = black at 87% opacity), whereas Flutter's
  /// [Color] expects `#AARRGGBB`. We reorder the alpha so 8-digit colors render
  /// correctly; 3/6-digit and `null` fall back to the shared [hexToColor].
  Color _color(String? hex) {
    if (hex == null) return hexToColor(hex);
    final h = hex.replaceFirst('#', '').trim();
    if (h.length == 8) {
      final reordered = '#${h.substring(6, 8)}${h.substring(0, 6)}';
      return hexToColor(reordered);
    }
    return hexToColor(hex);
  }

  Widget _positioned(TemplateElement el, double canvasW, double canvasH) {
    final rect = el.rect;
    if (rect == null) {
      // No rect → treat as a full-canvas element (e.g. background imageSlot).
      return Positioned.fill(child: _element(el));
    }
    return Positioned(
      left: rect.x * canvasW,
      top: rect.y * canvasH,
      width: rect.w * canvasW,
      height: rect.h * canvasH,
      child: _element(el),
    );
  }

  Widget _element(TemplateElement el) {
    switch (el.type) {
      case 'imageSlot':
        return _imageSlot(el);
      case 'image':
        return _staticImage(el.style);
      case 'box':
        return _box(el);
      case 'text':
        return _text(el);
      case 'boundField':
        return _boundField(el);
      case 'boundRow':
        return _boundRow(el);
      default:
        // Forward-compatible: ignore unknown element types.
        return const SizedBox.shrink();
    }
  }

  Widget _imageSlot(TemplateElement el) {
    final style = el.style;
    final fit = _boxFit(style?.fit);
    final radius = (style?.borderRadius ?? 0).r;
    final file = _slotImages[el.id];

    Widget image;
    if (file != null) {
      image = Image.file(
        file,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      final retained = _retainedSlots[el.id];
      final networkUrl = (retained != null && retained.isNotEmpty)
          ? mediaUrl(retained)
          : (_singleSlotWithInitial ? widget.initialImageUrl : null);
      if (networkUrl != null) {
        image = Image.network(
          networkUrl,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _imageSlotPlaceholder(),
        );
      } else {
        image = _imageSlotPlaceholder();
      }
    }

    if (radius > 0) {
      return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
    }
    return image;
  }

  Widget _imageSlotPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 32.sp),
    );
  }

  Widget _staticImage(TemplateStyle? style) {
    final src = style?.source;
    if (src == null || src.isEmpty) return const SizedBox.shrink();
    return Image.network(
      src,
      fit: _boxFit(style?.fit),
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  Widget _box(TemplateElement el) {
    final style = el.style;
    final hasPositionedChildren =
        el.children.any((c) => c.rect != null);

    final Widget content;
    if (el.children.isEmpty) {
      content = const SizedBox.shrink();
    } else if (hasPositionedChildren) {
      content = LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              for (final child in el.children)
                _positioned(child, constraints.maxWidth, constraints.maxHeight),
            ],
          );
        },
      );
    } else {
      // Stack children vertically; scale down when they exceed the box rect
      // so long field values don't overflow the template bounds. The
      // LayoutBuilder + SizedBox give the column a finite width so children
      // that use Expanded/stretch (e.g. boundRow) get valid constraints
      // instead of the infinite width FittedBox would otherwise impose.
      content = LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final child in el.children) _element(child)],
              ),
            ),
          );
        },
      );
    }

    return Opacity(
      opacity: style?.opacity ?? 1.0,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: _padding(style),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: style?.backgroundColor != null
              ? _color(style!.backgroundColor)
              : null,
          borderRadius: BorderRadius.circular((style?.borderRadius ?? 0).r),
        ),
        alignment: Alignment.topCenter,
        child: content,
      ),
    );
  }

  Widget _text(TemplateElement el) {
    final text = el.text ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      textAlign: _textAlign(el.style?.align),
      style: _textStyle(el.style, defaultWeight: FontWeight.w400),
    );
  }

  Widget _boundField(TemplateElement el) {
    final value = el.field == null ? '' : _value(el.field!);
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(
        value,
        textAlign: _textAlign(el.style?.align),
        style: _textStyle(el.style, defaultWeight: FontWeight.w700),
      ),
    );
  }

  Widget _boundRow(TemplateElement el) {
    final value = el.field == null ? '' : _value(el.field!);
    if (value.isEmpty) return const SizedBox.shrink();
    final label = el.label ?? '';
    final base = _textStyle(el.style, defaultWeight: FontWeight.w400);
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Text('$label : ', style: base.copyWith(fontWeight: FontWeight.w700)),
          Expanded(child: Text(value, style: base)),
        ],
      ),
    );
  }

  Widget _previewControls() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: const Border(top: BorderSide(color: AppColors.inputBorder)),
      ),
      child: Row(
        children: [
          Expanded(child: _secondaryButton('Edit', _goToForm)),
          SizedBox(width: 12.w),
          Expanded(
            child: _primaryButton('Save', _saveTemplate),
          ),
        ],
      ),
    );
  }

  // ─── Shared widgets ───────────────────────────────────────────────────────

  Widget _header({required String title, required VoidCallback onBack}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
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
              title,
              textAlign: TextAlign.center,
              style: AppTypography.headline(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 40.w),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap, {Color? color, Color? textColor}) {
    return CommonButton(
      title: label,
      onTap: onTap,
      backgroundColor: color,
      textColor: textColor,
    );
  }

  Widget _secondaryButton(String label, VoidCallback onTap) {
    return CommonButton(
      title: label,
      onTap: onTap,
      backgroundColor: AppColors.inputBackground,
      textColor: AppColors.white,
    );
  }

  // ─── Style / validation helpers ───────────────────────────────────────────

  TextStyle _textStyle(TemplateStyle? style, {required FontWeight defaultWeight}) {
    final base = TextStyle(
      fontSize: (style?.fontSize ?? 13).sp,
      fontWeight: _fontWeight(style?.fontWeight) ?? defaultWeight,
      color: style?.color != null ? _color(style!.color) : Colors.black87,
      height: style?.lineHeight,
    );
    switch ((style?.fontFamily ?? '').toLowerCase()) {
      case 'inter':
        return GoogleFonts.inter(textStyle: base);
      case 'poppins':
        return GoogleFonts.poppins(textStyle: base);
      case 'notosansmalayalam':
        return GoogleFonts.notoSansMalayalam(textStyle: base);
      case 'marcellus':
      default:
        return GoogleFonts.marcellus(textStyle: base);
    }
  }

  FontWeight? _fontWeight(int? weight) {
    if (weight == null) return null;
    final index = ((weight ~/ 100) - 1).clamp(0, 8);
    return FontWeight.values[index];
  }

  TextAlign _textAlign(String? align) {
    switch (align) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
      default:
        return TextAlign.center;
    }
  }

  BoxFit _boxFit(String? fit) {
    switch (fit) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'cover':
      default:
        return BoxFit.cover;
    }
  }

  EdgeInsets _padding(TemplateStyle? style) {
    if (style?.paddingLTRB != null && style!.paddingLTRB!.length == 4) {
      final p = style.paddingLTRB!;
      return EdgeInsets.fromLTRB(p[0].w, p[1].h, p[2].w, p[3].h);
    }
    final pad = style?.padding ?? 0;
    return EdgeInsets.symmetric(horizontal: pad.w, vertical: pad.h);
  }

  TextInputType? _keyboardType(TemplateField field, {bool multiline = false}) {
    if (multiline) return TextInputType.multiline;
    switch (field.keyboard) {
      case 'number':
        return TextInputType.number;
      case 'phone':
        return TextInputType.phone;
      case 'email':
        return TextInputType.emailAddress;
      case 'text':
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter>? _inputFormatters(TemplateField field) {
    if (field.inputType == 'number' || field.keyboard == 'number') {
      return [FilteringTextInputFormatter.digitsOnly];
    }
    return null;
  }

  String? _validate(TemplateField field, String? raw) {
    final value = (raw ?? '').trim();
    final rules = field.validation;

    if (field.required && value.isEmpty) {
      return rules?.errorMessage ?? 'Required';
    }
    if (value.isEmpty) return null;

    if (field.inputType == 'email') {
      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailRegex.hasMatch(value)) {
        return rules?.errorMessage ?? 'Enter a valid email';
      }
    }

    if (rules == null) return null;

    if (rules.minLength != null && value.length < rules.minLength!) {
      return rules.errorMessage ?? 'Minimum ${rules.minLength} characters';
    }
    if (rules.maxLength != null && value.length > rules.maxLength!) {
      return rules.errorMessage ?? 'Maximum ${rules.maxLength} characters';
    }
    if (rules.min != null || rules.max != null) {
      final number = num.tryParse(value);
      if (number == null) {
        return rules.errorMessage ?? 'Enter a valid number';
      }
      if (rules.min != null && number < rules.min!) {
        return rules.errorMessage ?? 'Minimum ${rules.min}';
      }
      if (rules.max != null && number > rules.max!) {
        return rules.errorMessage ?? 'Maximum ${rules.max}';
      }
    }
    if (rules.regex != null && rules.regex!.isNotEmpty) {
      try {
        if (!RegExp(rules.regex!).hasMatch(value)) {
          return rules.errorMessage ?? 'Invalid ${field.label}';
        }
      } catch (_) {
        // Ignore malformed server regex rather than crashing.
      }
    }
    return null;
  }
}

class _TemplateNameDialog extends StatefulWidget {
  const _TemplateNameDialog({required this.initial});

  final String initial;

  @override
  State<_TemplateNameDialog> createState() => _TemplateNameDialogState();
}

class _TemplateNameDialogState extends State<_TemplateNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final name = _controller.text.trim();
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.pop(context, name);
    }
  }

  void _cancel() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_added_outlined,
                color: AppColors.primary,
                size: 24.sp,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Save template',
              style: AppTypography.title(
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Give this template a name so you can find it later.',
              style: AppTypography.bodySmall(
                color: AppColors.textSecondary,
              ).copyWith(height: 1.4),
            ),
            SizedBox(height: 18.h),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                style: AppTypography.bodyMedium(color: AppColors.white),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Please enter a name'
                    : null,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Template name',
                  hintStyle: AppTypography.bodyMedium(
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: AppColors.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(color: AppColors.error, width: 1.4),
                  ),
                ),
              ),
            ),
            SizedBox(height: 22.h),
            Row(
              children: [
                Expanded(
                  child: _actionButton('Cancel', _cancel),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _actionButton('Save', _submit, filled: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap, {bool filled = false}) {
    return SizedBox(
      height: 46.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: filled ? AppColors.primary : AppColors.inputBackground,
          foregroundColor: filled ? AppColors.onPrimary : AppColors.textSecondary,
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
            color: filled ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
