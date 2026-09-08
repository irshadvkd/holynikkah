import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/theme/context_extension.dart';

class CommonDropdown<T> extends StatefulWidget {
  final String hintText;
  final String searchHintText;
  final String noResultsText;
  final ValueNotifier<T?> valueListenable;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabel;
  final String? Function(T?)? validator;
  final bool enabled;
  final bool searchable;
  final int searchThreshold;

  const CommonDropdown({
    super.key,
    required this.hintText,
    required this.valueListenable,
    required this.items,
    required this.onChanged,
    required this.itemLabel,
    this.searchHintText = 'Search...',
    this.noResultsText = 'No results found',
    this.validator,
    this.enabled = true,
    this.searchable = true,
    this.searchThreshold = 5,
  });

  @override
  State<CommonDropdown<T>> createState() => _CommonDropdownState<T>();
}

class _CommonDropdownState<T> extends State<CommonDropdown<T>> {
  static const Color _primary = Color(0xFF032544);

  late final TextEditingController _searchController;

  bool get _isSearchEnabled =>
      widget.searchable && widget.items.length >= widget.searchThreshold;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.enabled && widget.items.isNotEmpty;

    return Opacity(
      opacity: isInteractive ? 1 : 0.65,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50.r),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF303036).withValues(alpha: 0.7),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<T>(
            isExpanded: true,
            hint: _buildHint(),
            selectedItemBuilder: (context) {
              return widget.items
                  .map(
                    (item) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.itemLabel(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.marcellus(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.inputText,
                        ),
                      ),
                    ),
                  )
                  .toList();
            },
            items: widget.items
                .map(
                  (item) => DropdownItem<T>(
                    value: item,
                    height: 48.h,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        widget.itemLabel(item),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.marcellus(
                          fontSize: 15.sp,
                          color: AppColors.inputText,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
            valueListenable: widget.valueListenable,
            onChanged: isInteractive ? widget.onChanged : null,
            buttonStyleData: ButtonStyleData(
              height: 50.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.r),
                color: Colors.white,
              ),
            ),
            iconStyleData: IconStyleData(
              icon: Icon(
                isInteractive
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.lock_outline_rounded,
                size: 24.sp,
              ),
              iconEnabledColor: isInteractive ? _primary : AppColors.inputHint,
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 320.h,
              width: MediaQuery.sizeOf(context).width - 32.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              offset: Offset(0, -4.h),
              scrollbarTheme: ScrollbarThemeData(
                radius: Radius.circular(40.r),
                thickness: WidgetStateProperty.all<double>(4),
                thumbVisibility: WidgetStateProperty.all<bool>(true),
              ),
            ),
            menuItemStyleData: MenuItemStyleData(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              selectedMenuItemBuilder: (context, child) {
                return Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: child,
                );
              },
            ),
            dropdownSearchData: _isSearchEnabled
                ? DropdownSearchData<T>(
                    searchController: _searchController,
                    searchBarWidgetHeight: 52.h,
                    searchBarWidget: _buildSearchBar(),
                    noResultsWidget: _buildNoResults(),
                    searchMatchFn: (item, searchValue) {
                      final query = searchValue.trim().toLowerCase();
                      if (query.isEmpty) return true;
                      final value = item.value;
                      if (value == null) return false;
                      return widget
                          .itemLabel(value)
                          .toLowerCase()
                          .contains(query);
                    },
                  )
                : null,
            onMenuStateChange: (isOpen) {
              if (!isOpen && mounted) {
                _searchController.clear();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Text(
        widget.hintText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.marcellus(
          fontSize: 16.sp,
          color: AppColors.inputHint,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52.h,
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 6.h),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: AppTypography.marcellus(
          fontSize: 15.sp,
          color: AppColors.inputText,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.searchHintText,
          hintStyle: AppTypography.marcellus(
            fontSize: 14.sp,
            color: AppColors.inputHint,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20.sp,
            color: _primary,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(Icons.close_rounded, size: 18.sp),
                color: AppColors.inputHint,
                onPressed: _searchController.clear,
                tooltip: 'Clear search',
              );
            },
          ),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 10.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: _primary, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 28.sp,
            color: AppColors.inputHint,
          ),
          SizedBox(height: 8.h),
          Text(
            widget.noResultsText,
            textAlign: TextAlign.center,
            style: AppTypography.marcellus(
              fontSize: 14.sp,
              color: AppColors.inputHint,
            ),
          ),
        ],
      ),
    );
  }
}
