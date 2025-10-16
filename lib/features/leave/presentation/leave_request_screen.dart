import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/file_utils.dart';
import '../../../core/services/leave_service.dart';
import '../../../core/models/attachment_model.dart';
import '../data/leave_repository.dart';
import '../utils/leave_translations.dart';

class LeaveRequestScreen extends ConsumerStatefulWidget {
  final String leaveType;
  final String leaveTypeName;
  final int maxDays;

  const LeaveRequestScreen({
    super.key,
    required this.leaveType,
    this.leaveTypeName = '',
    this.maxDays = 0,
  });

  @override
  ConsumerState<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends ConsumerState<LeaveRequestScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _selectedDate; // For hourly leave
  String _durationType = 'daily'; // daily or hourly
  String _workingShift = '7am-9pm'; // 7am-9pm or 8am-1pm
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _reason = TextEditingController();
  List<AttachmentModel> _attachments = [];

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final currentEmployeeId = authService.currentEmployeeId;

    if (currentEmployeeId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userId = currentEmployeeId;
    final ctrl = ref.read(leaveControllerProvider(userId).notifier);

    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: Text(
          widget.leaveTypeName.isNotEmpty
              ? '${widget.leaveTypeName} ${LeaveTranslations.leaveRequestTitle(ref)}'
              : '${_capitalizeFirst(widget.leaveType)} ${LeaveTranslations.leaveRequestTitle(ref)}',
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
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLeaveTypeCard(),
                  const SizedBox(height: 24),
                  _buildDurationTypeSelector(),
                  const SizedBox(height: 24),
                  _buildDateFields(),
                  const SizedBox(height: 24),
                  _buildReasonField(),
                  const SizedBox(height: 24),
                  _buildImageUploadSection(),
                  const SizedBox(height: 100), // Extra space for submit button
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.kBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _buildSubmitButton(ctrl),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTypeCard() {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.kNanoWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getLeaveTypeIcon(widget.leaveType),
              color: AppTheme.kNanoWhite,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.leaveTypeName.isNotEmpty
                      ? widget.leaveTypeName
                      : _capitalizeFirst(widget.leaveType),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kNanoWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LeaveTranslations.leaveRequestTitle(ref),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.kNanoWhite.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LeaveTranslations.durationType(ref),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.kOnBackground,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDurationOption(
                'daily',
                LeaveTranslations.daily(ref),
                Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDurationOption(
                'hourly',
                LeaveTranslations.hourly(ref),
                Icons.access_time,
              ),
            ),
          ],
        ),
        if (_durationType == 'hourly') ...[
          const SizedBox(height: 16),
          _buildWorkingShiftSelector(),
        ],
      ],
    );
  }

  Widget _buildWorkingShiftSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LeaveTranslations.workingShift(ref),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.kOnBackground,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildShiftOption('7am-9pm', '7:00 AM - 9:00 PM')),
            const SizedBox(width: 12),
            Expanded(child: _buildShiftOption('8am-1pm', '8:00 AM - 1:00 PM')),
          ],
        ),
      ],
    );
  }

  Widget _buildShiftOption(String value, String label) {
    final isSelected = _workingShift == value;
    return GestureDetector(
      onTap: () => setState(() => _workingShift = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.kNanoGold.withOpacity(0.1)
              : AppTheme.kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.kNanoGold
                : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.kNanoGold : AppTheme.kOnSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationOption(String value, String label, IconData icon) {
    final isSelected = _durationType == value;
    return GestureDetector(
      onTap: () => setState(() => _durationType = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.kNanoGold.withOpacity(0.1)
              : AppTheme.kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.kNanoGold
                : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.kNanoGold : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.kNanoGold : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _durationType == 'daily'
              ? LeaveTranslations.leavePeriod(ref)
              : LeaveTranslations.leaveDate(ref),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.kOnBackground,
          ),
        ),
        const SizedBox(height: 16),
        if (_durationType == 'daily') ...[
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  LeaveTranslations.fromDateField(ref),
                  _fromDate,
                  Icons.calendar_today,
                  () => _selectFromDate(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  LeaveTranslations.toDateField(ref),
                  _toDate,
                  Icons.event,
                  () => _selectToDate(),
                ),
              ),
            ],
          ),
        ] else ...[
          _buildDateField(
            LeaveTranslations.date(ref),
            _selectedDate,
            Icons.calendar_today,
            () => _selectDate(),
          ),
          const SizedBox(height: 16),
          _buildTimeFields(),
        ],
      ],
    );
  }

  Widget _buildTimeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LeaveTranslations.timePeriod(ref),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.kOnBackground,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTimeField(
                LeaveTranslations.startTime(ref),
                _startTime,
                Icons.access_time,
                () => _selectStartTime(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeField(
                LeaveTranslations.endTime(ref),
                _endTime,
                Icons.schedule,
                () => _selectEndTime(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeField(
    String label,
    TimeOfDay? time,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.kNanoGold, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.kOnSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time != null
                        ? time.format(context)
                        : LeaveTranslations.selectTime(ref),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: time != null
                          ? AppTheme.kOnSurface
                          : AppTheme.kOnSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? date,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.kNanoGold, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.kOnSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : LeaveTranslations.selectDate(ref),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: date != null ? AppTheme.kOnSurface : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LeaveTranslations.reasonField(ref),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.kOnBackground,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: TextField(
            controller: _reason,
            maxLines: 4,
            onChanged: (value) =>
                setState(() {}), // Trigger rebuild when text changes
            decoration: InputDecoration(
              hintText: LeaveTranslations.reasonHint(ref),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: Icon(Icons.edit_note, color: AppTheme.kNanoGold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LeaveTranslations.supportingImage(ref),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.kOnBackground,
              ),
            ),
            Text(
              '${_attachments.length}/1',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Image upload buttons
        Row(
          children: [
            Expanded(
              child: _buildUploadButton(
                icon: Icons.camera_alt,
                label: LeaveTranslations.takePhoto(ref),
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUploadButton(
                icon: Icons.photo_library,
                label: LeaveTranslations.gallery(ref),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),

        // Attachments list
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._attachments.map((attachment) => _buildAttachmentItem(attachment)),
        ],
      ],
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _attachments.isNotEmpty ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: _attachments.isNotEmpty ? Colors.grey[100] : AppTheme.kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _attachments.isNotEmpty
                ? Colors.grey.withOpacity(0.3)
                : AppTheme.kNanoGold.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: _attachments.isNotEmpty
                  ? Colors.grey[400]
                  : AppTheme.kNanoGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _attachments.isNotEmpty
                    ? Colors.grey[400]
                    : AppTheme.kNanoGold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(AttachmentModel attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Image preview or file icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child:
                attachment.localPath.isNotEmpty &&
                    attachment.fileType.toLowerCase().contains('image')
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(attachment.localPath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[100],
                          child: Icon(
                            Icons.image,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: Text(
                        attachment.fileIcon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.kOnSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  attachment.formattedSize,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeAttachment(attachment.id),
            icon: Icon(Icons.close, color: AppTheme.errorColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(LeaveController ctrl) {
    final isValid = _durationType == 'daily'
        ? _fromDate != null && _toDate != null && _reason.text.trim().isNotEmpty
        : _selectedDate != null &&
              _startTime != null &&
              _endTime != null &&
              _reason.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid ? () => _submitRequest(ctrl) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.kNanoGold,
          foregroundColor: AppTheme.kNanoWhite,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          disabledBackgroundColor: AppTheme.kNanoGold.withOpacity(0.5),
          disabledForegroundColor: AppTheme.kNanoWhite.withOpacity(0.7),
        ),
        child: Text(
          isValid
              ? LeaveTranslations.submitLeaveRequest(ref)
              : LeaveTranslations.fillAllRequiredFields(ref),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _selectFromDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _fromDate = date;
        if (_toDate != null && _toDate!.isBefore(date)) {
          _toDate = null;
        }
      });
    }
  }

  void _selectToDate() async {
    if (_fromDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LeaveTranslations.pleaseSelectFromDateFirst(ref)),
        ),
      );
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate!,
      firstDate: _fromDate!,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _toDate = date);
    }
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _startTime = time);
    }
  }

  void _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _endTime = time);
    }
  }

  void _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final File file = File(pickedFile.path);

        await _addAttachment(file);
      } else {
        print('📸 No file selected');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${LeaveTranslations.errorPickingImage(ref)}: $e'),
        ),
      );
    }
  }

  Future<void> _addAttachment(File file) async {
    try {
      // Check file size (max 10MB)
      final double fileSizeMB = FileUtils.getFileSizeInMB(file);
      if (fileSizeMB > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LeaveTranslations.fileSizeTooLarge(ref))),
        );
        return;
      }

      // Create attachment model for local storage
      final AttachmentModel attachment = AttachmentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: file.path.split('/').last,
        localPath: file.path,
        fileType: FileUtils.getFileExtension(file.path.split('/').last),
        fileSizeMB: fileSizeMB,
        createdAt: DateTime.now(),
        isUploaded: false,
      );

      setState(() {
        _attachments.add(attachment);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${LeaveTranslations.imageAdded(ref)}: ${attachment.fileName}',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${LeaveTranslations.errorAddingImage(ref)}: ${e.toString()}',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _removeAttachment(String attachmentId) {
    setState(() {
      _attachments.removeWhere((attachment) => attachment.id == attachmentId);
    });
  }

  void _submitRequest(LeaveController ctrl) async {
    // Validate based on duration type
    if (_durationType == 'daily') {
      if (_fromDate == null || _toDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LeaveTranslations.pleaseSelectDates(ref))),
        );
        return;
      }
    } else {
      if (_selectedDate == null || _startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LeaveTranslations.pleaseSelectDateTime(ref))),
        );
        return;
      }

      // Validate time range
      if (_startTime!.hour > _endTime!.hour ||
          (_startTime!.hour == _endTime!.hour &&
              _startTime!.minute >= _endTime!.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LeaveTranslations.endTimeMustBeAfterStartTime(ref)),
          ),
        );
        return;
      }
    }

    if (_reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LeaveTranslations.pleaseProvideReason(ref))),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get current employee ID, name, and position
      final authService = ref.read(authServiceProvider);
      final currentEmployeeId = authService.currentEmployeeId;
      final currentEmployeeName = authService.currentEmployeeName;
      final currentEmployeeFirstName = authService.currentEmployeeFirstName;
      final currentEmployeeLastName = authService.currentEmployeeLastName;
      final currentPositionName = authService.currentPositionName;

      if (currentEmployeeId == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LeaveTranslations.employeeNotFound(ref))),
        );
        return;
      }

      // Generate unique ID for leave request (for future use)
      // final leaveId = 'LR-${DateTime.now().millisecondsSinceEpoch}';

      // Determine approval workflow based on position
      final approvalWorkflow = _getApprovalWorkflow(currentPositionName ?? '');

      final requestData = {
        'employeeId': currentEmployeeId,
        'employeeName':
            currentEmployeeName ?? LeaveTranslations.unknownEmployee(ref),
        'firstName': currentEmployeeFirstName ?? '',
        'lastName': currentEmployeeLastName ?? '',
        'positionName': currentPositionName ?? '',
        'leaveType': widget.leaveType, // Use the actual leave type ID from API
        'leaveTypeName': widget.leaveTypeName.isNotEmpty
            ? widget.leaveTypeName
            : _getLeaveTypeName(
                widget.leaveType,
              ), // Use provided name or fallback
        'requestType': _durationType, // Use 'daily' or 'hourly'
        'reason': _reason.text.trim(),
        'isHalfDay': false,
        'halfDayType': 'morning', // Default value
        'attachments': [], // Will be populated with uploaded file URLs
        // Add approval workflow fields
        'approvalLevel': approvalWorkflow['level'],
        'currentApprover': approvalWorkflow['currentApprover'],
        'approvalWorkflow': approvalWorkflow['workflow'],
      };

      // Add daily leave specific fields
      if (_durationType == 'daily') {
        requestData['fromDate'] =
            '${_fromDate!.year}-${_fromDate!.month.toString().padLeft(2, '0')}-${_fromDate!.day.toString().padLeft(2, '0')}';
        requestData['toDate'] =
            '${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}';
      }

      // Add hourly leave specific fields (treat as half day)
      if (_durationType == 'hourly') {
        final selectedDate = _selectedDate!;
        requestData['fromDate'] =
            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        requestData['toDate'] =
            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
        requestData['isHalfDay'] = true;
        requestData['halfDayType'] = _startTime!.hour < 12
            ? 'morning'
            : 'afternoon';
      }

      // Convert attachments to File list
      final List<File> attachmentFiles = _attachments
          .map((attachment) => File(attachment.localPath))
          .toList();

      final leaveService = LeaveService();
      final response = await leaveService.createLeaveRequestWithAttachments(
        requestData,
        attachmentFiles,
      );

      if (response['success'] == true) {
        if (response['leaveRequest']?['attachment'] != null) {
          final attachment = response['leaveRequest']['attachment'];
          if (attachment['files'] != null) {
            for (var file in attachment['files']) {
              print('  - ${file['publicUrl']}');
            }
          }
        }
      } else {
        throw Exception(
          response['message'] ?? LeaveTranslations.failedToSubmitRequest(ref),
        );
      }

      // Close loading dialog
      Navigator.pop(context);

      if (context.mounted) {
        Navigator.pop(context); // Close the form
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.leaveTypeName.isNotEmpty ? widget.leaveTypeName : _capitalizeFirst(widget.leaveType)} leave request submitted successfully!',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LeaveTranslations.errorSubmittingRequest(ref)}: ${e.toString()}',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Determine approval workflow based on employee position
  Map<String, String> _getApprovalWorkflow(String positionName) {
    final position = positionName.toLowerCase();

    // Special case: HR requests go directly to approver
    if (position.contains('hr') || position.contains('human resource')) {
      return {
        'level': 'approver',
        'currentApprover': 'approver',
        'workflow': 'hr -> approver',
      };
    }

    // Special case: Manager requests go directly to HR
    if (position.contains('manager') ||
        position.contains('supervisor') ||
        position.contains('lead')) {
      return {
        'level': 'hr',
        'currentApprover': 'hr',
        'workflow': 'manager -> hr -> approver',
      };
    }

    // Special case: Approver requests are self-approved
    if (position.contains('approver') || position.contains('management')) {
      return {
        'level': 'approved',
        'currentApprover': 'self',
        'workflow': 'self-approved',
      };
    }

    // Special case: Programmer requests go to Team Lead first
    if (position.contains('programmer')) {
      return {
        'level': 'team_lead',
        'currentApprover': 'team_lead',
        'workflow': 'programmer -> team_lead -> hr -> approver',
      };
    }

    // Positions that should go through normal flow (Manager -> HR -> Approver)
    final normalFlowPositions = [
      'programmer',
      'developer',
      'software engineer',
      'salesman',
      'sales',
    ];

    // Check if position should use normal flow
    bool useNormalFlow = normalFlowPositions.any(
      (pos) => position.contains(pos),
    );

    if (useNormalFlow) {
      // Normal workflow (employee -> manager -> hr -> approver)
      return {
        'level': 'employee',
        'currentApprover': 'manager',
        'workflow': 'employee -> manager -> hr -> approver',
      };
    } else {
      // Direct to HR workflow (skip manager for all other positions)
      return {
        'level': 'hr',
        'currentApprover': 'hr',
        'workflow': 'employee -> hr -> approver',
      };
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _getLeaveTypeName(String type) {
    // Map leave types to their display names
    switch (type.toLowerCase()) {
      case 'vacation':
      case 'annual':
        return 'Sick Leave'; // Using sick leave as general leave
      case 'sick':
        return 'Sick Leave';
      case 'personal':
      case 'casual':
        return 'Leave of absence (paid)';
      case 'maternity':
        return 'Maternity leave';
      case 'paternity':
        return 'Leave of absence (paid)';
      case 'emergency':
        return 'Leave (without pay)';
      case 'study':
        return 'Leave (without pay)';
      case 'compensatory':
        return 'Leave of absence (paid)';
      case 'funeral':
        return 'Leave (for funeral arrangements)';
      case 'marriage':
        return 'Marriage leave';
      case 'sterilization':
        return 'Leave (for sterilization)';
      default:
        return 'Leave of absence (paid)';
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
}
