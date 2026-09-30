import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:holynikkah/core/theme/app_colors.dart';
import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:holynikkah/core/widgets/widgets.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/partner/models/phone_request_model.dart';
import 'package:holynikkah/modules/partner/services/phone_requests_service.dart';

const Color _approveGreen = AppColors.success;
const Color _rejectRed = AppColors.error;
const Color _pendingAmber = AppColors.primary;

/// Phone-visibility requests hub (Request), opened from the profile menu.
class PhoneRequestsScreen extends StatefulWidget {
  final bool? initialIsIncoming;
  final bool? initialIsVip;

  const PhoneRequestsScreen({
    super.key,
    this.initialIsIncoming,
    this.initialIsVip,
  });

  @override
  State<PhoneRequestsScreen> createState() => _PhoneRequestsScreenState();
}

class _PhoneRequestsScreenState extends State<PhoneRequestsScreen> {
  late bool _isVip;
  late bool _isIncoming;

  @override
  void initState() {
    super.initState();
    _isVip = widget.initialIsVip ?? true;
    _isIncoming = widget.initialIsIncoming ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hasVip = auth.isVipLoggedIn;
    final hasNormal = auth.isNormalLoggedIn;

    // Keep the selected tier valid for whatever the user is signed into.
    if (_isVip && !hasVip && hasNormal) _isVip = false;
    if (!_isVip && !hasNormal && hasVip) _isVip = true;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.darkGreenGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.goldLight, size: 20.sp),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Phone Requests',
            style: AppTypography.cormorantGaramond(
              color: AppColors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: (!hasVip && !hasNormal)
            ? const _EmptyMessage(
                icon: Icons.lock_person_outlined,
                message: 'Sign in to view requests',
              )
            : SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                  child: Column(
                    children: [
                      if (hasVip && hasNormal) ...[
                        _Segmented(
                          leftLabel: 'VIP',
                          rightLabel: 'Normal',
                          leftSelected: _isVip,
                          onLeft: () => setState(() => _isVip = true),
                          onRight: () => setState(() => _isVip = false),
                        ),
                        SizedBox(height: 12.h),
                      ],
                      _Segmented(
                        leftLabel: 'Received',
                        rightLabel: 'Sent',
                        leftSelected: _isIncoming,
                        onLeft: () => setState(() => _isIncoming = true),
                        onRight: () => setState(() => _isIncoming = false),
                      ),
                      SizedBox(height: 16.h),
                      Expanded(
                        child: _PhoneRequestList(
                          key: ValueKey('$_isVip-$_isIncoming'),
                          isVip: _isVip,
                          isIncoming: _isIncoming,
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

/// Two-option segmented toggle with primary gold selection.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.onLeft,
    required this.onRight,
  });

  final String leftLabel;
  final String rightLabel;
  final bool leftSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _segment(leftLabel, leftSelected, onLeft)),
          SizedBox(width: 8.w),
          Expanded(child: _segment(rightLabel, !leftSelected, onRight)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          gradient: selected
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                )
              : null,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: selected
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
          label,
          style: AppTypography.cormorantGaramond(
            color: selected ? AppColors.onPrimary : AppColors.textSecondary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PhoneRequestList extends StatefulWidget {
  const _PhoneRequestList({
    super.key,
    required this.isVip,
    required this.isIncoming,
  });

  final bool isVip;
  final bool isIncoming;

  @override
  State<_PhoneRequestList> createState() => _PhoneRequestListState();
}

class _PhoneRequestListState extends State<_PhoneRequestList> {
  static const List<_StatusFilter> _filters = [
    _StatusFilter(label: 'All', value: null),
    _StatusFilter(label: 'Pending', value: 'pending'),
    _StatusFilter(label: 'Approved', value: 'approved'),
    _StatusFilter(label: 'Rejected', value: 'rejected'),
  ];

  final ScrollController _scrollController = ScrollController();

  String? _status;

  List<PhoneRequestModel> _requests = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _ensureToken() async {
    await context.read<AuthProvider>().ensureApiTokenFor(isVip: widget.isVip);
  }

  Future<_ListResult> _fetch(int page) async {
    await _ensureToken();
    final service = PhoneRequestsService.instance;
    final response = widget.isIncoming
        ? await service.fetchIncoming(
            isVip: widget.isVip,
            status: _status,
            page: page,
          )
        : await service.fetchOutgoing(
            isVip: widget.isVip,
            status: _status,
            page: page,
          );
    return _ListResult(
      success: response.success,
      result: response.data,
      message: response.message,
    );
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _fetch(1);
    if (!mounted) return;

    if (result.success && result.result != null) {
      final feed = result.result!;
      setState(() {
        _requests = feed.requests;
        _currentPage = feed.currentPage;
        _hasMore = feed.hasMore;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = result.message ?? 'Failed to load requests';
    });
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;
    setState(() => _isLoadingMore = true);

    final result = await _fetch(_currentPage + 1);
    if (!mounted) return;

    if (result.success && result.result != null) {
      final feed = result.result!;
      setState(() {
        _requests = [..._requests, ...feed.requests];
        _currentPage = feed.currentPage;
        _hasMore = feed.hasMore;
        _isLoadingMore = false;
      });
      return;
    }

    setState(() => _isLoadingMore = false);
  }

  Future<void> _changeStatus(String? value) async {
    if (_status == value) return;
    setState(() => _status = value);
    await _load();
  }

  Future<void> _respond(PhoneRequestModel request, bool approve) async {
    if (_busyIds.contains(request.id)) return;
    setState(() => _busyIds.add(request.id));

    await _ensureToken();
    final response = await PhoneRequestsService.instance.respond(
      isVip: widget.isVip,
      requestId: request.id,
      approve: approve,
    );

    if (!mounted) return;
    setState(() => _busyIds.remove(request.id));

    if (!response.success) {
      CommonSnackBar.showError(
        context,
        response.message ?? 'Could not update the request',
      );
      return;
    }

    final newStatus = approve ? 'approved' : 'rejected';
    setState(() {
      if (_status != null && _status != newStatus) {
        _requests = _requests.where((r) => r.id != request.id).toList();
      } else {
        _requests = [
          for (final r in _requests)
            if (r.id == request.id) r.copyWith(status: newStatus) else r,
        ];
      }
    });

    CommonSnackBar.showSuccess(
      context,
      approve ? 'Request approved' : 'Request rejected',
    );
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone.trim());
    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        CommonSnackBar.showError(context, 'Could not open the dialer');
      }
    } catch (_) {
      if (mounted) CommonSnackBar.showError(context, 'Could not open the dialer');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        SizedBox(height: 12.h),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = _status == filter.value;
          return GestureDetector(
            onTap: () => _changeStatus(filter.value),
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.inputBackground,
                gradient: selected
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      )
                    : null,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: selected ? Colors.transparent : AppColors.inputBorder,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                filter.label,
                style: AppTypography.cormorantGaramond(
                  color: selected ? AppColors.onPrimary : AppColors.textSecondary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage != null) {
      return _EmptyMessage(
        icon: Icons.wifi_off,
        message: _errorMessage!,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }

    if (_requests.isEmpty) {
      return _EmptyMessage(
        icon: widget.isIncoming
            ? Icons.inbox_outlined
            : Icons.outbox_outlined,
        message: widget.isIncoming
            ? 'No requests received'
            : 'No requests sent',
        actionLabel: 'Refresh',
        onAction: _load,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.secondary,
      onRefresh: _load,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 24.h),
        itemCount: _requests.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          if (index >= _requests.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          return _RequestCard(
            request: _requests[index],
            isIncoming: widget.isIncoming,
            busy: _busyIds.contains(_requests[index].id),
            onApprove: () => _respond(_requests[index], true),
            onReject: () => _respond(_requests[index], false),
            onCall: _call,
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.isIncoming,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onCall,
  });

  final PhoneRequestModel request;
  final bool isIncoming;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final void Function(String? phone) onCall;

  @override
  Widget build(BuildContext context) {
    final party = isIncoming ? request.requester : request.target;
    final name = (party?.name?.isNotEmpty ?? false) ? party!.name! : 'Member';
    final place = party?.place;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(imageUrl: party?.imageUrl ?? ''),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cormorantGaramond(
                        color: AppColors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (place != null && place.isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 13.sp,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              place,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.cormorantGaramond(
                                color: AppColors.textSecondary,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _StatusBadge(status: request.status),
            ],
          ),
          SizedBox(height: 14.h),
          _buildAction(),
        ],
      ),
    );
  }

  Widget _buildAction() {
    if (isIncoming) {
      if (!request.isPending) {
        return _ResultLine(
          approved: request.isApproved,
          text: request.isApproved
              ? 'You approved this request'
              : 'You rejected this request',
        );
      }
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: busy ? null : onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: _rejectRed,
                side: BorderSide(color: _rejectRed.withValues(alpha: 0.6)),
                padding: EdgeInsets.symmetric(vertical: 11.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Reject',
                style: AppTypography.cormorantGaramond(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _rejectRed,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton(
              onPressed: busy ? null : onApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 11.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: busy
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Text(
                      'Approve',
                      style: AppTypography.cormorantGaramond(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
            ),
          ),
        ],
      );
    }

    // Outgoing.
    if (request.isApproved && (request.target?.hasPhone ?? false)) {
      final phone = request.target!.phone;
      return Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton.icon(
          onPressed: () => onCall(phone),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
            minimumSize: Size(0, 36.h),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const StadiumBorder(),
          ),
          icon: Icon(Icons.call, size: 15.sp, color: AppColors.onPrimary),
          label: Text(
            'Call',
            style: AppTypography.cormorantGaramond(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      );
    }

    return _ResultLine(
      approved: request.isApproved,
      neutral: request.isPending,
      text: request.isApproved
          ? 'Approved — number unavailable'
          : request.isRejected
              ? 'Your request was rejected'
              : 'Waiting for approval',
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: SizedBox(
        width: 50.w,
        height: 50.w,
        child: imageUrl.isEmpty
            ? Container(
                color: AppColors.inputBackground,
                child: Icon(Icons.person, color: AppColors.textTertiary, size: 24.sp),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.inputBackground),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.inputBackground,
                  child: Icon(
                    Icons.person,
                    color: AppColors.textTertiary,
                    size: 24.sp,
                  ),
                ),
              ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    switch (status) {
      case 'approved':
        color = _approveGreen;
        label = 'Approved';
        break;
      case 'rejected':
        color = _rejectRed;
        label = 'Rejected';
        break;
      default:
        color = _pendingAmber;
        label = 'Pending';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTypography.cormorantGaramond(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({
    required this.approved,
    required this.text,
    this.neutral = false,
  });

  final bool approved;
  final String text;
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final color = neutral
        ? AppColors.textTertiary
        : approved
            ? _approveGreen
            : _rejectRed;
    final icon = neutral
        ? Icons.hourglass_empty
        : approved
            ? Icons.check_circle_outline
            : Icons.cancel_outlined;

    return Row(
      children: [
        Icon(icon, size: 16.sp, color: color),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: AppTypography.cormorantGaramond(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textSecondary.withValues(alpha: 0.4), size: 46.sp),
            SizedBox(height: 14.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.cormorantGaramond(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: AppTypography.cormorantGaramond(
                    color: AppColors.onPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusFilter {
  const _StatusFilter({required this.label, required this.value});

  final String label;
  final String? value;
}

/// Lightweight wrapper so list/load helpers stay tier-agnostic.
class _ListResult {
  const _ListResult({required this.success, this.result, this.message});

  final bool success;
  final PhoneRequestsResult? result;
  final String? message;
}
