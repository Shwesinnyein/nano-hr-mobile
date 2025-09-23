import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/leave_service.dart';
import '../data/leave_repository.dart';
import '../data/leave_model.dart';

class LeaveRequestScreen extends ConsumerStatefulWidget {
  final String leaveType;

  const LeaveRequestScreen({super.key, required this.leaveType});

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
  File? _selectedImage;
  // final ImagePicker _picker = ImagePicker();

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
          '${_capitalizeFirst(widget.leaveType)} Leave Request',
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
                  _capitalizeFirst(widget.leaveType),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kNanoWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Leave Request',
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
          'Duration Type',
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
                'Daily',
                Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDurationOption(
                'hourly',
                'Hourly',
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
          'Working Shift',
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
          _durationType == 'daily' ? 'Leave Period' : 'Leave Date',
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
                  'From Date',
                  _fromDate,
                  Icons.calendar_today,
                  () => _selectFromDate(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  'To Date',
                  _toDate,
                  Icons.event,
                  () => _selectToDate(),
                ),
              ),
            ],
          ),
        ] else ...[
          _buildDateField(
            'Date',
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
          'Time Period',
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
                'Start Time',
                _startTime,
                Icons.access_time,
                () => _selectStartTime(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeField(
                'End Time',
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
                    time != null ? time.format(context) : 'Select time',
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
                  : 'Select date',
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
          'Reason',
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
              hintText: 'Please provide a reason for your leave request...',
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
        Text(
          'Supporting Document (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.kOnBackground,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedImage != null
                    ? AppTheme.kNanoGold
                    : Colors.grey.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upload image',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successColor, size: 16),
              const SizedBox(width: 4),
              Text(
                'Image uploaded successfully',
                style: TextStyle(fontSize: 12, color: AppTheme.successColor),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _selectedImage = null),
                child: Icon(Icons.close, color: AppTheme.errorColor, size: 16),
              ),
            ],
          ),
        ],
      ],
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
          isValid ? 'Submit Leave Request' : 'Fill all required fields',
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
        const SnackBar(content: Text('Please select from date first')),
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

  void _pickImage() async {
    // final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    // if (image != null) {
    //   setState(() => _selectedImage = File(image.path));
    // }
    // TODO: Implement image picking when image_picker is re-enabled
  }

  void _submitRequest(LeaveController ctrl) async {
    // Validate based on duration type
    if (_durationType == 'daily') {
      if (_fromDate == null || _toDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select from and to dates')),
        );
        return;
      }
    } else {
      if (_selectedDate == null || _startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select date, start time, and end time'),
          ),
        );
        return;
      }

      // Validate time range
      if (_startTime!.hour > _endTime!.hour ||
          (_startTime!.hour == _endTime!.hour &&
              _startTime!.minute >= _endTime!.minute)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }
    }

    if (_reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for leave')),
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

      // Get current employee ID
      final authService = ref.read(authServiceProvider);
      final currentEmployeeId = authService.currentEmployeeId;

      if (currentEmployeeId == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Employee not found')));
        return;
      }

      // Generate unique ID for leave request
      final leaveId = 'LR-${DateTime.now().millisecondsSinceEpoch}';

      // Prepare request data according to API specification
      final requestData = {
        'employeeId': currentEmployeeId,
        'leaveType': _getLeaveTypeId(widget.leaveType), // Map leave type to ID
        'leaveTypeName': _getLeaveTypeName(
          widget.leaveType,
        ), // Add leave type name
        'requestType': _durationType, // Use 'daily' or 'hourly'
        'reason': _reason.text.trim(),
        'isHalfDay': false,
        'halfDayType': 'morning', // Default value
        'attachments':
            <Map<String, dynamic>>[], // Initialize empty attachments list
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

      // Handle file upload if image is selected
      if (_selectedImage != null) {
        try {
          final leaveService = LeaveService();
          final uploadResult = await leaveService.uploadFile(
            _selectedImage!.path,
          );
          if (uploadResult['success'] == true) {
            (requestData['attachments'] as List<Map<String, dynamic>>).add({
              'name': _selectedImage!.path.split('/').last,
              'url': uploadResult['url'],
              'type': 'image',
            });
          }
        } catch (e) {
          print('⚠️ File upload failed: $e');
          // Continue without attachment
        }
      }

      // Submit leave request using real API with the correct format
      final repository = ref.read(leaveRepositoryProvider);
      await repository.submitRequest(requestData);

      // Close loading dialog
      Navigator.pop(context);

      if (context.mounted) {
        Navigator.pop(context); // Close the form
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_capitalizeFirst(widget.leaveType)} leave request submitted successfully!',
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
            content: Text('Error submitting leave request: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _getLeaveTypeId(String type) {
    // Map leave types to their actual IDs from the leave settings API
    switch (type.toLowerCase()) {
      case 'vacation':
      case 'annual':
        return 'c1cdc61e-80ba-4142-9845-2b1561d1bb98'; // Sick Leave (using as general leave)
      case 'sick':
        return 'c1cdc61e-80ba-4142-9845-2b1561d1bb98'; // Sick Leave
      case 'personal':
      case 'casual':
        return '90a98a14-4664-42cf-be47-437111dbd186'; // Leave of absence (paid)
      case 'maternity':
        return 'f568f575-32c9-406e-883b-59cd991fb1d3'; // Maternity leave
      case 'paternity':
        return '90a98a14-4664-42cf-be47-437111dbd186'; // Leave of absence (paid)
      case 'emergency':
        return '95d7cfc5-ed62-4d69-b53f-b91fa9b941f7'; // Leave (without pay)
      case 'study':
        return '95d7cfc5-ed62-4d69-b53f-b91fa9b941f7'; // Leave (without pay)
      case 'compensatory':
        return '90a98a14-4664-42cf-be47-437111dbd186'; // Leave of absence (paid)
      case 'funeral':
        return 'a2680d55-4964-47b8-9585-c3b1795ceafa'; // Leave (for funeral arrangements)
      case 'marriage':
        return 'acd2e4a5-d52d-4ff5-8490-aa59c2bfc5f0'; // Marriage leave
      case 'sterilization':
        return '43d27e1a-267b-41af-95eb-f438fdaf29cb'; // Leave (for sterilization)
      default:
        return '90a98a14-4664-42cf-be47-437111dbd186'; // Default to Leave of absence (paid)
    }
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
