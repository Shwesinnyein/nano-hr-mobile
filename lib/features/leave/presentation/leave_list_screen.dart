import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../app/theme.dart';
import '../../../core/widgets/skeleton_loading.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/animated_fade_in.dart';
import '../../../core/services/auth_service.dart';
import '../data/leave_repository.dart';
import '../data/leave_model.dart';
import '../utils/leave_translations.dart';

class LeaveListScreen extends ConsumerStatefulWidget {
  const LeaveListScreen({super.key});

  @override
  ConsumerState<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends ConsumerState<LeaveListScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    final authService = ref.read(authServiceProvider);
    final currentEmployeeId = authService.currentEmployeeId;
    if (currentEmployeeId != null) {
      ref.invalidate(employeeLeaveListProvider(currentEmployeeId));
    }

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final currentEmployeeId = authService.currentEmployeeId;

    if (currentEmployeeId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final employeeId = currentEmployeeId;
    final leaveAsync = ref.watch(employeeLeaveListProvider(employeeId));

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: Text(
          LeaveTranslations.leaveHistory(ref),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.kOnBackground,
          ),
        ),
        backgroundColor: AppTheme.kBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.kOnBackground),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.kOnBackground),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isRefreshing
          ? _buildSkeletonLoading()
          : leaveAsync.when(
              data: (leaveRequests) => RefreshIndicator(
                onRefresh: _refreshData,
                child: _buildLeaveList(leaveRequests),
              ),
              loading: () => _buildSkeletonLoading(),
              error: (error, stack) => ErrorStateWidget(
                message: LeaveTranslations.errorLoadingLeaveData(ref),
                actionText: LeaveTranslations.retry(ref),
                onAction: _refreshData,
              ),
            ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6, 
      itemBuilder: (context, index) {
        return AnimatedFadeIn(
          delay: Duration(milliseconds: index * 100),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SkeletonLoading(
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SkeletonLoading(height: 16, width: 120),
                          const SizedBox(height: 4),
                          const SkeletonLoading(height: 14, width: 80),
                        ],
                      ),
                    ),
                    const SkeletonLoading(
                      width: 60,
                      height: 24,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const SkeletonLoading(height: 14, width: double.infinity),
                const SizedBox(height: 8),
                const SkeletonLoading(height: 14, width: 200),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaveList(List<LeaveRequest> requests) {
    return Column(
      children: [
        if (requests.isEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No Leave Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You haven\'t submitted any leave requests yet.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        if (requests.isNotEmpty) ...[
          _buildSummaryCard(requests),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return AnimatedFadeIn(
                  delay: Duration(milliseconds: index * 50),
                  child: GestureDetector(
                    onTap: () => _showLeaveDetailsDialog(context, request),
                    child: _buildLeaveRequestCard(request),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(List<LeaveRequest> requests) {
    final totalRequests = requests.length;
    final approvedRequests = requests
        .where((r) => _normalizeStatusForEmployee(r.status) == 'approved')
        .length;
    final pendingRequests = requests
        .where((r) => _normalizeStatusForEmployee(r.status) == 'pending')
        .length;
    final rejectedRequests = requests
        .where((r) => _normalizeStatusForEmployee(r.status) == 'rejected')
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.kNanoGold, AppTheme.kNanoGoldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kNanoGold.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: AppTheme.kNanoWhite, size: 24),
              const SizedBox(width: 8),
              Text(
                LeaveTranslations.leaveHistory(ref),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.kNanoWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                LeaveTranslations.allRequests(ref),
                totalRequests,
                Icons.calendar_today,
              ),
              _buildSummaryItem(
                LeaveTranslations.approved(ref),
                approvedRequests,
                Icons.check_circle,
              ),
              _buildSummaryItem(
                LeaveTranslations.pending(ref),
                pendingRequests,
                Icons.pending,
              ),
              _buildSummaryItem(
                LeaveTranslations.rejected(ref),
                rejectedRequests,
                Icons.cancel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.kNanoWhite, size: 24),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.kNanoWhite,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.kNanoWhite.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveRequestCard(LeaveRequest request) {
    Color statusColor;
    IconData statusIcon;

    switch (request.status) {
      case 'approved':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
      case 'rejected':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel;
      default:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.pending;
    }

    String durationText;
    if (request.startTime != null && request.endTime != null) {
      durationText = '${request.startTime} - ${request.endTime}';
    } else if (request.startDate != null && request.endDate != null) {
      final startDate = DateTime.parse(request.startDate!);
      final endDate = DateTime.parse(request.endDate!);
      final daysDifference = endDate.difference(startDate).inDays + 1;
      durationText =
          '$daysDifference ${daysDifference > 1 ? LeaveTranslations.daysUnit(ref) : LeaveTranslations.dayUnit(ref)}';
    } else {
      durationText = 'N/A';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getLeaveTypeColor(
                        request.leaveType,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getLeaveTypeIcon(request.leaveType),
                      color: _getLeaveTypeColor(request.leaveType),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _capitalizeFirst(request.leaveType),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.kOnSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          durationText,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.kOnSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          request.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (request.requestType == 'daily') ...[
                if (request.startDate != null && request.endDate != null) ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '${LeaveTranslations.fromDate(ref)} ${_formatDate(DateTime.parse(request.startDate!))}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '${LeaveTranslations.toDate(ref)} ${_formatDate(DateTime.parse(request.endDate!))}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ] else if (request.fromDate != null &&
                    request.toDate != null) ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '${LeaveTranslations.fromDate(ref)} ${_formatDate(DateTime.parse(request.fromDate!))}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '${LeaveTranslations.toDate(ref)} ${_formatDate(DateTime.parse(request.toDate!))}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Date information not available',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ] else if (request.requestType == 'hourly' &&
                  request.date != null) ...[
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Date: ${_formatDate(DateTime.parse(request.date!))}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.kOnSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                if (request.startTime != null && request.endTime != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Time: ${request.startTime} - ${request.endTime}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.kOnSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],

              if (request.requestType == 'daily' &&
                  request.totalDays != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${LeaveTranslations.totalDaysLabel(ref)} ${request.totalDays}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.kOnSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],

              if (request.reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.reason,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.kOnSurface.withOpacity(0.8),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              
              if (request.attachments.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildAttachmentsPreview(request.attachments),
              ],

              
              ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${LeaveTranslations.createdLabel(ref)} ${request.createdAt}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.kOnSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildAttachmentsPreview(List<Map<String, dynamic>> attachments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file, size: 16, color: AppTheme.kNanoGold),
            const SizedBox(width: 8),
            Text(
              '${LeaveTranslations.attachmentsLabel(ref)} (${attachments.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.kNanoGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: attachments.asMap().entries.map((entry) {
            final index = entry.key;
            final attachment = entry.value;
            final url = attachment['publicUrl'] ?? attachment['url'] ?? attachment['firebaseUrl'] ?? '';
            final fileName =
                attachment['originalName'] ??
                attachment['fileName'] ??
                attachment['name'] ??
                url.split('/').last;
            final fileType = attachment['fileType'] ?? attachment['type'] ?? '';
            final contentType = attachment['contentType'] ?? attachment['mimeType'] ?? '';

            // Check if it's an image by multiple methods
            final isImage = _isImageFile(fileName, url) || 
                           (fileType.toString().toLowerCase().contains('image')) ||
                           (contentType.toString().toLowerCase().startsWith('image/'));

            return GestureDetector(
              onTap: () => _openAttachment(url, allAttachments: attachments, initialIndex: index),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.kNanoGold.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isImage && url.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFD4A574).withOpacity(0.3),
                              child: Icon(
                                Icons.image,
                                color: AppTheme.kNanoGold,
                                size: 32,
                              ),
                            );
                          },
                          loadingBuilder:
                              (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: const Color(0xFFD4A574).withOpacity(0.3),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value:
                                          loadingProgress
                                                  .expectedTotalBytes !=
                                              null
                                          ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                          : null,
                                      color: AppTheme.kNanoGold,
                                    ),
                                  ),
                                );
                              },
                        ),
                      )
                    : Container(
                        color: const Color(0xFFD4A574).withOpacity(0.3),
                        child: Center(
                          child: Icon(
                            _getFileIcon(fileName),
                            color: AppTheme.kNanoGold,
                            size: 32,
                          ),
                        ),
                      ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _isImageFile(String fileName, [String? url]) {
    // Check filename extension
    if (fileName.contains('.')) {
      final extension = fileName.toLowerCase().split('.').last;
      if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif'].contains(extension)) {
        return true;
      }
    }
    
    // Check URL if provided
    if (url != null && url.isNotEmpty) {
      final urlLower = url.toLowerCase();
      // Check if URL contains image extensions
      if (urlLower.contains('.jpg') || 
          urlLower.contains('.jpeg') || 
          urlLower.contains('.png') || 
          urlLower.contains('.gif') || 
          urlLower.contains('.bmp') || 
          urlLower.contains('.webp') ||
          urlLower.contains('.heic') ||
          urlLower.contains('.heif')) {
        return true;
      }
      // Check if it's a Firebase Storage URL with image content type
      if (urlLower.contains('firebasestorage') || urlLower.contains('storage.googleapis.com')) {
        // Assume it's an image if we can't determine otherwise (common for Firebase URLs)
        // But also check for common non-image patterns
        if (!urlLower.contains('.pdf') && 
            !urlLower.contains('.doc') && 
            !urlLower.contains('.xls') &&
            !urlLower.contains('.zip')) {
          return true; // Likely an image
        }
      }
    }
    
    return false;
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.attach_file;
    }
  }

  Color _getLeaveTypeColor(String type) {
    switch (type) {
      case 'annual':
        return AppTheme.primaryColor;
      case 'sick':
        return AppTheme.errorColor;
      case 'casual':
        return AppTheme.secondaryColor;
      case 'maternity':
        return const Color(0xFFE91E63);
      case 'paternity':
        return const Color(0xFF9C27B0);
      case 'emergency':
        return const Color(0xFFFF5722);
      case 'study':
        return const Color(0xFF607D8B);
      case 'compensatory':
        return const Color(0xFF795548);
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getLeaveTypeIcon(String type) {
    switch (type) {
      case 'annual':
        return Icons.beach_access;
      case 'sick':
        return Icons.health_and_safety;
      case 'casual':
        return Icons.event_available;
      case 'maternity':
        return Icons.child_care;
      case 'paternity':
        return Icons.family_restroom;
      case 'emergency':
        return Icons.emergency;
      case 'study':
        return Icons.school;
      case 'compensatory':
        return Icons.work_off;
      default:
        return Icons.calendar_today;
    }
  }

  void _showLeaveDetailsDialog(BuildContext context, LeaveRequest request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.98,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getLeaveTypeColor(
                              request.leaveType,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getLeaveTypeIcon(request.leaveType),
                            color: _getLeaveTypeColor(request.leaveType),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _capitalizeFirst(request.leaveType),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.kOnSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    request.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _normalizeStatusForEmployee(
                                    request.status,
                                  ).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(request.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),


                    _buildDetailRow(
                      LeaveTranslations.requestType(ref),
                      request.requestType?.toUpperCase() ?? 'N/A',
                      Icons.category,
                    ),

                    if (request.requestType == 'daily') ...[
                      _buildDetailRow(
                        LeaveTranslations.fromDateField(ref),
                        request.fromDate ?? 'N/A',
                        Icons.calendar_today,
                      ),
                      _buildDetailRow(
                        LeaveTranslations.toDateField(ref),
                        request.toDate ?? 'N/A',
                        Icons.calendar_today,
                      ),
                      if (request.totalDays != null)
                        _buildDetailRow(
                          LeaveTranslations.totalDaysLabel(
                            ref,
                          ).replaceAll(':', ''),
                          '${request.totalDays}',
                          Icons.calendar_view_week,
                        ),
                    ],

                    if (request.requestType == 'hourly') ...[
                      _buildDetailRow(
                        'Date',
                        request.date ?? 'N/A',
                        Icons.calendar_today,
                      ),
                      if (request.workingShift != null)
                        _buildDetailRow(
                          'Working Shift',
                          request.workingShift!,
                          Icons.access_time,
                        ),
                      if (request.startTime != null && request.endTime != null)
                        _buildDetailRow(
                          'Time',
                          '${request.startTime} - ${request.endTime}',
                          Icons.schedule,
                        ),
                    ],

                    _buildDetailRow(
                      LeaveTranslations.reason(ref),
                      request.reason.isNotEmpty
                          ? request.reason
                          : 'No reason provided',
                      Icons.note,
                      isMultiline: true,
                    ),

                    if (request.status.toLowerCase() == 'rejected' && 
                        request.rejectReason != null && 
                        request.rejectReason!.isNotEmpty)
                      _buildDetailRow(
                        LeaveTranslations.rejectionReason(ref),
                        request.rejectReason!,
                        Icons.cancel,
                        isMultiline: true,
                      ),

                    if (request.attachments.isNotEmpty)
                      _buildAttachmentsSection(request.attachments),

                    // _buildDetailRow(
                    //   'Created',
                    //   request.createdAt,
                    //   Icons.schedule,
                    // ),

                    // _buildDetailRow(
                    //   'Last Updated',
                    //   request.updatedAt,
                    //   Icons.update,
                    // ),
                    const SizedBox(height: 24),

                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.kNanoGold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentsSection(List<Map<String, dynamic>> attachments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.attach_file, size: 20, color: AppTheme.kNanoGold),
            const SizedBox(width: 8),
            Text(
              '${LeaveTranslations.attachmentsLabel(ref)} (${attachments.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.kOnSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: attachments.length,
          itemBuilder: (context, index) {
            final attachment = attachments[index];
            final url = attachment['publicUrl'] ?? attachment['url'] ?? attachment['firebaseUrl'] ?? '';
            final fileName =
                attachment['originalName'] ??
                attachment['fileName'] ??
                attachment['name'] ??
                url.split('/').last;
            final fileType = attachment['fileType'] ?? attachment['type'] ?? '';
            final contentType = attachment['contentType'] ?? attachment['mimeType'] ?? '';

            // Check if it's an image by multiple methods
            final isImage = _isImageFile(fileName, url) || 
                           (fileType.toString().toLowerCase().contains('image')) ||
                           (contentType.toString().toLowerCase().startsWith('image/'));

            return GestureDetector(
              onTap: () => _openAttachment(url, allAttachments: attachments, initialIndex: index),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.kNanoGold.withOpacity(0.3),
                  ),
                ),
                child: isImage && url.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[100],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    color: Colors.grey[400],
                                    size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Error',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[100],
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getFileIcon(fileName),
                              color: AppTheme.kNanoGold,
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fileName.split('.').last.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.kNanoGold,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.kOnSurface,
                  ),
                  maxLines: isMultiline ? null : 1,
                  overflow: isMultiline ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  String _normalizeStatusForEmployee(String status) {
    final statusLower = status.toLowerCase();

    
    if (statusLower == 'approved' || statusLower == 'rejected') {
      return statusLower;
    }

    
    if (statusLower.contains('rejected')) {
      return 'rejected';
    }

    
    if (statusLower.contains('approved')) {
      return 'approved';
    }

    
    return 'pending';
  }

  Color _getStatusColor(String status) {
    
    final normalizedStatus = _normalizeStatusForEmployee(status);

    switch (normalizedStatus) {
      case 'approved':
        return AppTheme.successColor;
      case 'rejected':
        return AppTheme.errorColor;
      default: 
        return AppTheme.warningColor;
    }
  }

  Future<void> _openAttachment(String url, {List<Map<String, dynamic>>? allAttachments, int? initialIndex}) async {
    try {
      if (url.isEmpty) {
        _showErrorSnackBar('Invalid attachment URL');
        return;
      }

      // Get attachment info if available
      Map<String, dynamic>? currentAttachment;
      if (allAttachments != null && initialIndex != null && initialIndex < allAttachments.length) {
        currentAttachment = allAttachments[initialIndex];
      } else if (allAttachments != null) {
        currentAttachment = allAttachments.firstWhere(
          (att) => (att['publicUrl'] ?? att['url'] ?? att['firebaseUrl'] ?? '') == url,
          orElse: () => <String, dynamic>{},
        );
      }

      final fileName = currentAttachment != null
          ? (currentAttachment['originalName'] ?? 
             currentAttachment['fileName'] ?? 
             currentAttachment['name'] ?? 
             url.split('/').last)
          : url.split('/').last;
      
      final fileType = currentAttachment?['fileType'] ?? currentAttachment?['type'] ?? '';
      final contentType = currentAttachment?['contentType'] ?? currentAttachment?['mimeType'] ?? '';

      // Use improved image detection
      final isImage = _isImageFile(fileName, url) || 
                     (fileType.toString().toLowerCase().contains('image')) ||
                     (contentType.toString().toLowerCase().startsWith('image/'));

      if (isImage) {
        // If we have all attachments, show full-screen viewer with navigation
        if (allAttachments != null && allAttachments.isNotEmpty) {
          final List<String> imageUrls = allAttachments
              .where((att) {
                final attUrl = att['publicUrl'] ?? att['url'] ?? att['firebaseUrl'] ?? '';
                if (attUrl.isEmpty) return false;
                
                final attFileName = att['originalName'] ?? 
                                   att['fileName'] ?? 
                                   att['name'] ?? 
                                   attUrl.toString().split('/').last;
                final attFileType = att['fileType'] ?? att['type'] ?? '';
                final attContentType = att['contentType'] ?? att['mimeType'] ?? '';
                
                return _isImageFile(attFileName.toString(), attUrl.toString()) ||
                       (attFileType.toString().toLowerCase().contains('image')) ||
                       (attContentType.toString().toLowerCase().startsWith('image/'));
              })
              .map<String>((att) {
                final attUrl = att['publicUrl'] ?? att['url'] ?? att['firebaseUrl'] ?? '';
                return attUrl.toString();
              })
              .where((url) => url.isNotEmpty)
              .toList();
          
          if (imageUrls.isNotEmpty) {
            final idx = initialIndex ?? imageUrls.indexWhere((u) => u == url);
            _showFullScreenImageViewer(imageUrls, idx >= 0 ? idx : 0);
            return;
          }
        }
        // Fallback to single image viewer (always show in-app, never in browser)
        _showFullScreenImageViewer([url], 0);
      } else {
        // For non-image files, open in external browser
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showErrorSnackBar('Could not open attachment');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error opening attachment: $e');
    }
  }

  void _showFullScreenImageViewer(List<String> imageUrls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _showImageViewer(String imageUrl) {
    _showFullScreenImageViewer([imageUrl], 0);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveImage(String imageUrl) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final dio = Dio();
        final response = await dio.get(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );

        Navigator.pop(context); // Close loading dialog

        final directory = await getTemporaryDirectory();
        final fileName = imageUrl.split('/').last;
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.data);

        await Share.shareXFiles([XFile(filePath)]);
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView for images
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final imageUrl = widget.imageUrls[index];
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        padding: const EdgeInsets.all(50),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading image...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(50),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Top bar with close button, page indicator, and share button
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button (X)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // Page indicator (1 of 2)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} of ${widget.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Share/Save button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () => _saveImage(widget.imageUrls[_currentIndex]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
