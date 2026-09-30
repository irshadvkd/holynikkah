import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:holynikkah/core/theme/app_typography.dart';
import 'package:holynikkah/core/widgets/widgets.dart';
import 'package:holynikkah/modules/login/providers/auth_provider.dart';
import 'package:holynikkah/modules/notifications/services/notification_api.dart';
import 'package:holynikkah/modules/partner/models/match_model.dart';
import 'package:holynikkah/modules/partner/services/matches_service.dart';
import 'package:holynikkah/modules/partner/services/phone_requests_service.dart';

/// Vertical (Reels-style) matrimony feed.
///
/// Loads matches from `/{tier}-users/matches` for the signed-in user's tier and
/// renders each match full-screen with infinite pagination. Normal users see
/// active female normal users via their default saved-template preview; VIP
/// users see active female VIP users.
class PartnerFullScreenView extends StatefulWidget {
  const PartnerFullScreenView({super.key, required this.isVip});

  /// Whether to load the VIP feed (`/vip-users/matches`) or the normal feed
  /// (`/normal-users/matches`).
  final bool isVip;

  @override
  State<PartnerFullScreenView> createState() => _PartnerFullScreenViewState();
}

class _PartnerFullScreenViewState extends State<PartnerFullScreenView> {
  final PageController _pageController = PageController();

  List<MatchModel> _matches = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _loadMoreFailed = false;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await context.read<AuthProvider>().ensureApiTokenFor(isVip: widget.isVip);

    final response = await MatchesService.instance.fetchMatches(
      isVip: widget.isVip,
      page: 1,
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      final feed = response.data!;
      setState(() {
        _matches = feed.matches;
        _currentPage = feed.currentPage;
        _hasMore = feed.hasMore;
        _isLoading = false;
      });
      _recordProfileView(0);
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = response.message ?? 'Failed to load matches';
    });
  }

  void _recordProfileView(int index) {
    if (index >= 0 && index < _matches.length) {
      final targetId = int.tryParse(_matches[index].id);
      if (targetId != null) {
        NotificationApi.instance.recordProfileView(
          isVip: widget.isVip,
          targetId: targetId,
        );
      }
    }
  }

  Future<void> _loadMoreMatches() async {
    if (!_hasMore || _isLoadingMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreFailed = false;
    });

    await context.read<AuthProvider>().ensureApiTokenFor(isVip: widget.isVip);

    final response = await MatchesService.instance.fetchMatches(
      isVip: widget.isVip,
      page: _currentPage + 1,
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      final feed = response.data!;
      setState(() {
        _matches = [..._matches, ...feed.matches];
        _currentPage = feed.currentPage;
        _hasMore = feed.hasMore;
        _isLoadingMore = false;
      });
      return;
    }

    setState(() {
      _isLoadingMore = false;
      _loadMoreFailed = true;
    });
  }

  void _onPageChanged(int index) {
    _recordProfileView(index);
    if (index >= _matches.length) {
      _loadMoreMatches();
      return;
    }
    if (index == _matches.length - 1) {
      _loadMoreMatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildBody(),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).padding.top,
              child: const ColoredBox(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_errorMessage != null) {
      return _MatchesMessage(
        icon: Icons.wifi_off,
        message: _errorMessage!,
        actionLabel: 'Retry',
        onAction: () => _loadMatches(refresh: true),
      );
    }

    if (_matches.isEmpty) {
      return _MatchesMessage(
        icon: Icons.favorite_border,
        message: 'No matches yet',
        actionLabel: 'Refresh',
        onAction: () => _loadMatches(refresh: true),
      );
    }

    return SafeArea(
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _matches.length + (_hasMore ? 1 : 0),
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          if (index >= _matches.length) {
            return _NextPageLoader(
              isLoading: _isLoadingMore,
              hasFailed: _loadMoreFailed,
              onRetry: _loadMoreMatches,
            );
          }
          return _MatchItem(match: _matches[index], isVip: widget.isVip);
        },
      ),
    );
  }
}

class _MatchItem extends StatefulWidget {
  const _MatchItem({required this.match, required this.isVip});

  final MatchModel match;
  final bool isVip;

  @override
  State<_MatchItem> createState() => _MatchItemState();
}

class _MatchItemState extends State<_MatchItem> {
  late MatchModel _match = widget.match;
  bool _requesting = false;

  @override
  void didUpdateWidget(covariant _MatchItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.id != widget.match.id) {
      _match = widget.match;
      _requesting = false;
    }
  }

  Future<void> _callContact() async {
    final phone = _match.phone;
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

  Future<void> _requestContact() async {
    if (_requesting) return;

    final targetId = int.tryParse(_match.id);
    if (targetId == null) {
      CommonSnackBar.showError(context, 'Could not send the request');
      return;
    }

    setState(() => _requesting = true);

    await context.read<AuthProvider>().ensureApiTokenFor(isVip: widget.isVip);

    final response = await PhoneRequestsService.instance.createRequest(
      isVip: widget.isVip,
      targetId: targetId,
    );

    if (!mounted) return;
    setState(() => _requesting = false);

    if (!response.success) {
      CommonSnackBar.showError(
        context,
        response.message ?? 'Could not send the request',
      );
      return;
    }

    if (response.data != null) {
      setState(() => _match = _match.copyWith(phone: response.data));
      CommonSnackBar.showSuccess(context, 'Contact info unlocked');
      return;
    }

    setState(() => _match = _match.copyWith(phoneAccess: 'pending'));
    CommonSnackBar.showSuccess(
      context,
      response.message ?? "Request sent — you'll be notified once approved",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _match.hasImage
              ? CachedNetworkImage(
                  imageUrl: _match.imageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[850]!,
                    highlightColor: Colors.grey[700]!,
                    child: const ColoredBox(color: Colors.black),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
        ),
        _buildBottomOverlay(),
      ],
    );
  }

  Widget _buildBottomOverlay() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xE6101012),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 18),
      child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_match.name?.isNotEmpty ?? false)
                    Text(
                      (_match.age?.isNotEmpty ?? false)
                          ? '${_match.name}, ${_match.age}'
                          : _match.name!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.marcellus(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (_match.place?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white60,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _match.place!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.marcellus(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildContactAction(),
          ],
        ),
    );
  }

  Widget _buildContactAction() {
    if (_match.hasPhone) {
      return FilledButton.icon(
        onPressed: _callContact,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF25A35A),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(0, 38),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const StadiumBorder(),
        ),
        icon: const Icon(Icons.call, size: 18),
        label: Text(
          'Call',
          style: AppTypography.marcellus(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      );
    }

    if (_match.isRequestPending) {
      return FilledButton.icon(
        onPressed: null,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white24,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.white24,
          disabledForegroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(0, 38),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const StadiumBorder(),
        ),
        icon: const Icon(Icons.check, size: 18),
        label: Text(
          'Sent',
          style: AppTypography.marcellus(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: _requesting ? null : _requestContact,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        disabledBackgroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(0, 38),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
      ),
      icon: _requesting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black54,
              ),
            )
          : const Icon(Icons.lock_outline, size: 18),
      label: Text(
        _requesting ? 'Sending…' : 'Request',
        style: AppTypography.marcellus(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MatchesMessage extends StatelessWidget {
  const _MatchesMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.marcellus(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: AppTypography.marcellus(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextPageLoader extends StatefulWidget {
  const _NextPageLoader({
    required this.isLoading,
    required this.hasFailed,
    required this.onRetry,
  });

  final bool isLoading;
  final bool hasFailed;
  final VoidCallback onRetry;

  @override
  State<_NextPageLoader> createState() => _NextPageLoaderState();
}

class _NextPageLoaderState extends State<_NextPageLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isLoading) widget.onRetry();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: widget.hasFailed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white54, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load more matches',
                    style: AppTypography.marcellus(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: widget.onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
