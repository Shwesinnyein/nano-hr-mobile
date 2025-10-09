import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/services/location_service.dart';

class CheckInConfirmationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> employeeData;
  final bool isCheckOut;

  const CheckInConfirmationScreen({
    super.key,
    required this.employeeData,
    this.isCheckOut = false,
  });

  @override
  ConsumerState<CheckInConfirmationScreen> createState() =>
      _CheckInConfirmationScreenState();
}

class _CheckInConfirmationScreenState
    extends ConsumerState<CheckInConfirmationScreen> {
  final LocationService _locationService = LocationService();
  
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  
  Map<String, dynamic>? _locationData;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locationData = await _locationService.getCurrentLocationWithAddress();
      
      if (mounted) {
        setState(() {
          _locationData = locationData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmCheckIn() async {
    if (_locationData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location data not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Return location data to previous screen
      Navigator.pop(context, {
        'confirmed': true,
        'latitude': _locationData!['latitude'],
        'longitude': _locationData!['longitude'],
        'address': _locationData!['address'],
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.kNanoGold,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isCheckOut ? 'Confirm Check Out' : 'Confirm Check In',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildConfirmationContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
          ),
          const SizedBox(height: 24),
          Text(
            'Getting your location...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            const Text(
              'Location Access Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to get location',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _getLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.kNanoGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () async {
                await _locationService.openLocationSettings();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.kNanoGold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationContent() {
    if (_locationData == null) return const SizedBox.shrink();

    final latitude = _locationData!['latitude'] as double;
    final longitude = _locationData!['longitude'] as double;
    final address = _locationData!['address'] as String;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    widget.isCheckOut ? Icons.logout : Icons.login,
                    size: 60,
                    color: AppTheme.kNanoGold,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isCheckOut
                        ? 'Confirm Check Out'
                        : 'Confirm Check In',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please verify your location',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Employee Info
            _buildInfoSection(
              title: 'Employee Information',
              children: [
                _buildInfoRow(
                  Icons.person,
                  'Name',
                  widget.employeeData['fullName'] ?? 'N/A',
                ),
                _buildInfoRow(
                  Icons.business,
                  'Company',
                  widget.employeeData['companyName'] ?? 'N/A',
                ),
                _buildInfoRow(
                  Icons.location_city,
                  'Branch',
                  widget.employeeData['branchName'] ?? 'N/A',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Location Info
            _buildInfoSection(
              title: 'Current Location',
              children: [
                _buildInfoRow(
                  Icons.location_on,
                  'Address',
                  address,
                ),
                _buildInfoRow(
                  Icons.my_location,
                  'Coordinates',
                  '${latitude.toStringAsFixed(6)}°, ${longitude.toStringAsFixed(6)}°',
                ),
                _buildInfoRow(
                  Icons.access_time,
                  'Time',
                  _formatCurrentTime(),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Confirm Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.kNanoGold, AppTheme.kNanoGoldDark],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kNanoGold.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _confirmCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isCheckOut ? Icons.logout : Icons.check_circle,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.isCheckOut ? 'Confirm Check Out' : 'Confirm Check In',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Cancel Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppTheme.kNanoGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppTheme.kNanoGold,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.kNanoGold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.kNanoGold.withOpacity(0.7),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }
}

