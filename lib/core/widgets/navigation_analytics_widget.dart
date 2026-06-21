import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:holynikkah/core/services/navigation_logger.dart';
import 'package:holynikkah/core/services/user_journey_tracker.dart';
import 'package:holynikkah/core/theme/context_extension.dart';
import 'package:holynikkah/core/widgets/common_snackbar.dart';

/// 📊 Navigation Analytics Widget
/// 
/// Shows navigation analytics and issues for debugging
class NavigationAnalyticsWidget extends StatefulWidget {
  const NavigationAnalyticsWidget({super.key});

  @override
  State<NavigationAnalyticsWidget> createState() => _NavigationAnalyticsWidgetState();
}

class _NavigationAnalyticsWidgetState extends State<NavigationAnalyticsWidget> {
  final NavigationLogger _navLogger = NavigationLogger();
  final UserJourneyTracker _journeyTracker = UserJourneyTracker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Navigation Analytics',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: _clearData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSessionAnalytics(),
            SizedBox(height: 20.h),
            _buildNavigationIssues(),
            SizedBox(height: 20.h),
            _buildNavigationHistory(),
            SizedBox(height: 20.h),
            _buildJourneyAnalytics(),
            SizedBox(height: 20.h),
            _buildExportSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionAnalytics() {
    final analytics = _navLogger.getSessionAnalytics();
    
    return _buildSection(
      title: 'Session Analytics',
      child: Column(
        children: [
          _buildAnalyticsRow('Duration', '${analytics.sessionDuration.inMinutes}m ${analytics.sessionDuration.inSeconds % 60}s'),
          _buildAnalyticsRow('Routes Visited', analytics.routesVisited.length.toString()),
          _buildAnalyticsRow('Total Navigations', analytics.totalNavigations.toString()),
          _buildAnalyticsRow('Errors', analytics.errors.length.toString()),
          _buildAnalyticsRow('Registration Steps', analytics.registrationSteps.length.toString()),
        ],
      ),
    );
  }

  Widget _buildNavigationIssues() {
    final issues = _navLogger.detectIssues();
    
    return _buildSection(
      title: 'Navigation Issues (${issues.length})',
      child: issues.isEmpty
          ? _buildEmptyState('No navigation issues detected')
          : Column(
              children: issues.map((issue) => _buildIssueCard(issue)).toList(),
            ),
    );
  }

  Widget _buildNavigationHistory() {
    final history = _navLogger.getNavigationHistory();
    
    return _buildSection(
      title: 'Navigation History (${history.length})',
      child: history.isEmpty
          ? _buildEmptyState('No navigation history')
          : Column(
              children: history.reversed.take(10).map((event) => _buildHistoryCard(event)).toList(),
            ),
    );
  }

  Widget _buildJourneyAnalytics() {
    final analytics = _journeyTracker.getCurrentJourneyAnalytics();
    
    return _buildSection(
      title: 'Current Journey',
      child: analytics == null
          ? _buildEmptyState('No active journey')
          : Column(
              children: [
                _buildAnalyticsRow('Type', analytics.type.name.toUpperCase()),
                _buildAnalyticsRow('Duration', '${analytics.duration.inMinutes}m ${analytics.duration.inSeconds % 60}s'),
                _buildAnalyticsRow('Progress', '${analytics.stepsCompleted}/${analytics.totalSteps} (${analytics.completionPercentage.toStringAsFixed(1)}%)'),
                _buildAnalyticsRow('Current Step', analytics.currentStep ?? 'Unknown'),
                if (analytics.dropOffPoints.isNotEmpty)
                  _buildAnalyticsRow('Drop-off Points', analytics.dropOffPoints.join(', ')),
              ],
            ),
    );
  }

  Widget _buildExportSection() {
    return _buildSection(
      title: 'Export Data',
      child: Column(
        children: [
          _buildActionButton(
            'Export Navigation Data',
            Icons.download,
            _exportNavigationData,
          ),
          SizedBox(height: 8.h),
          _buildActionButton(
            'Export Journey Data',
            Icons.analytics,
            _exportJourneyData,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.brandYellow,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.grey[300],
              fontSize: 14.sp,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(NavigationIssue issue) {
    Color issueColor;
    IconData issueIcon;
    
    switch (issue.type) {
      case NavigationIssueType.duplicateNavigation:
        issueColor = Colors.orange;
        issueIcon = Icons.warning;
        break;
      case NavigationIssueType.rapidBackAndForth:
        issueColor = Colors.red;
        issueIcon = Icons.error;
        break;
      case NavigationIssueType.longRegistrationGap:
        issueColor = Colors.yellow;
        issueIcon = Icons.access_time;
        break;
      default:
        issueColor = Colors.grey;
        issueIcon = Icons.info;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: issueColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: issueColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(issueIcon, color: issueColor, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.type.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim(),
                  style: GoogleFonts.inter(
                    color: issueColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  issue.description,
                  style: GoogleFonts.inter(
                    color: Colors.grey[300],
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(NavigationEvent event) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                event.error != null ? Icons.error : Icons.navigation,
                color: event.error != null ? Colors.red : AppColors.brandYellow,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${event.from} → ${event.to}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                _formatTime(event.timestamp),
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
          if (event.trigger != 'unknown')
            Padding(
              padding: EdgeInsets.only(top: 4.h, left: 24.w),
              child: Text(
                'Trigger: ${event.trigger}',
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 10.sp,
                ),
              ),
            ),
          if (event.error != null)
            Padding(
              padding: EdgeInsets.only(top: 4.h, left: 24.w),
              child: Text(
                'Error: ${event.error}',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontSize: 10.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18.sp),
        label: Text(
          text,
          style: GoogleFonts.inter(fontSize: 14.sp),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandYellow,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.grey[500],
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }

  Future<void> _exportNavigationData() async {
    try {
      final data = await _navLogger.exportSessionData();
      // In a real app, you would save this to a file or send to analytics
      debugPrint('Navigation Data Exported: ${data.length} characters');
      
      if (mounted) {
        CommonSnackBar.showSuccess(
          context,
          'Navigation data exported (${data.length} chars)',
        );
      }
    } catch (e) {
      if (mounted) {
        CommonSnackBar.showError(context, 'Export failed: $e');
      }
    }
  }

  Future<void> _exportJourneyData() async {
    try {
      final data = await _journeyTracker.exportJourneyData();
      // In a real app, you would save this to a file or send to analytics
      debugPrint('Journey Data Exported: ${data.length} characters');
      
      if (mounted) {
        CommonSnackBar.showSuccess(
          context,
          'Journey data exported (${data.length} chars)',
        );
      }
    } catch (e) {
      if (mounted) {
        CommonSnackBar.showError(context, 'Export failed: $e');
      }
    }
  }

  Future<void> _clearData() async {
    await _navLogger.clearSession();
    setState(() {});
    
    if (mounted) {
      CommonSnackBar.showInfo(context, 'Navigation data cleared');
    }
  }
}