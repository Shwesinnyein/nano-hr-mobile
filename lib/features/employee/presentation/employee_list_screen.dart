import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/skeleton_loading.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/animated_fade_in.dart';
import '../data/employee_repository.dart';
import 'employee_detail_screen.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalCount = 0;
  bool _hasMoreData = true;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreEmployees();
    }
  }

  Future<void> _loadEmployees({bool isRefresh = false}) async {
    try {
      setState(() {
        _isLoading = true;
        if (isRefresh) {
          _currentPage = 1;
          _employees.clear();
          _filteredEmployees.clear();
        }
      });

      final employeeRepository = ref.read(employeeRepositoryProvider);
      final employees = await employeeRepository.getEmployees(
        page: _currentPage,
        limit: 20, // Load 20 employees per page
      );

      setState(() {
        if (isRefresh) {
          _employees = employees;
          _filteredEmployees = employees;
        } else {
          _employees.addAll(employees);
          _filteredEmployees.addAll(employees);
        }
        _isLoading = false;
        _hasMoreData = employees.length == 20; // If we got 20, there might be more
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load employees. Please try again.'),
            backgroundColor: AppTheme.errorColor,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadEmployees(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadMoreEmployees() async {
    if (_isLoadingMore || !_hasMoreData || _isLoading) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final employeeRepository = ref.read(employeeRepositoryProvider);
      final employees = await employeeRepository.getEmployees(
        page: _currentPage,
        limit: 20,
      );

      setState(() {
        _employees.addAll(employees);
        _filteredEmployees.addAll(employees);
        _isLoadingMore = false;
        _hasMoreData = employees.length == 20;
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _filterEmployees(String query) {
    _searchTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _filteredEmployees = _employees;
      });
      return;
    }

    // Debounce search to avoid excessive filtering
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    final searchLower = query.toLowerCase();

    final filtered = _employees.where((employee) {
      return employee.name.toLowerCase().contains(searchLower) ||
          employee.firstName?.toLowerCase().contains(searchLower) == true ||
          employee.lastName?.toLowerCase().contains(searchLower) == true ||
          employee.email?.toLowerCase().contains(searchLower) == true ||
          employee.positionName?.toLowerCase().contains(searchLower) == true ||
          employee.companyName.toLowerCase().contains(searchLower) ||
          employee.locationName.toLowerCase().contains(searchLower);
    }).toList();

    setState(() {
      _filteredEmployees = filtered;
    });
  }

  Future<void> _refresh() async {
    await _loadEmployees(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        title: const Text(
          'Employee List',
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
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildEmployeeCount(),
          Expanded(
            child: _isLoading
                ? _buildSkeletonLoading()
                : _filteredEmployees.isEmpty
                ? _buildEmptyState()
                : _buildEmployeeList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterEmployees,
        decoration: InputDecoration(
          hintText: 'Search employees...',
          prefixIcon: Icon(Icons.search, color: AppTheme.kNanoGold),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCount() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '${_filteredEmployees.length} employee${_filteredEmployees.length != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.kOnBackground,
            ),
          ),
          const Spacer(),
          if (_hasMoreData && !_isLoading && _searchController.text.isEmpty)
            Text(
              'Scroll for more',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.kNanoGold,
                fontStyle: FontStyle.italic,
              ),
            ),
          if (_searchController.text.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                _filterEmployees('');
              },
              child: Text('Clear', style: TextStyle(color: AppTheme.kNanoGold)),
            ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8, // Show 8 skeleton items
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
            child: Row(
              children: [
                const SkeletonLoading(
                  width: 50,
                  height: 50,
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonLoading(height: 16, width: 150),
                      const SizedBox(height: 8),
                      const SkeletonLoading(height: 14, width: 100),
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
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      message: _searchController.text.isNotEmpty
          ? 'No employees found. Try adjusting your search terms.'
          : 'No employees available.',
      icon: Icons.people_outline,
    );
  }

  Widget _buildEmployeeList() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _filteredEmployees.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredEmployees.length) {
            return _buildLoadingIndicator();
          }
          final employee = _filteredEmployees[index];
          return AnimatedFadeIn(
            delay: Duration(milliseconds: index * 50),
            child: _buildEmployeeCard(employee),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToEmployeeDetail(employee),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildProfileAvatar(employee),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${employee.firstName ?? ''} ${employee.lastName ?? ''}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.kOnSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          employee.positionName ?? 'Employee',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.kOnSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          employee.primary_number ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.kNanoGold,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusBadge(employee.status),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(Employee employee) {
    // Check if employee has a profile image URL
    if (employee.profileImage != null && employee.profileImage!.isNotEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.kNanoGold.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: Image.network(
            employee.profileImage!,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to initials if image fails to load
              return _buildInitialsAvatar(employee);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingAvatar();
            },
          ),
        ),
      );
    }

    // Fallback to initials if no profile image
    return _buildInitialsAvatar(employee);
  }

  Widget _buildInitialsAvatar(Employee employee) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.kNanoGold, AppTheme.kNanoGoldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(employee),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.withOpacity(0.3),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.kNanoGold),
          ),
        ),
      ),
    );
  }

  String _getInitials(Employee employee) {
    String initials = '';

    // Try to get initials from firstName and lastName
    if (employee.firstName != null && employee.firstName!.isNotEmpty) {
      initials += employee.firstName![0].toUpperCase();
    }
    if (employee.lastName != null && employee.lastName!.isNotEmpty) {
      initials += employee.lastName![0].toUpperCase();
    }

    // Fallback to name field
    if (initials.isEmpty && employee.name.isNotEmpty) {
      initials = employee.name[0].toUpperCase();
    }

    // Final fallback
    if (initials.isEmpty) {
      initials = '?';
    }

    return initials;
  }

  Widget _buildStatusBadge(String? status) {
    Color statusColor;
    String statusText;

    switch (status?.toLowerCase()) {
      case 'active':
        statusColor = AppTheme.successColor;
        statusText = 'Active';
      case 'resigned  ':
        statusColor = AppTheme.errorColor;
        statusText = 'Inactive';
      case ' ':
        statusColor = AppTheme.warningColor;
        statusText = 'Pending';

      default:
        statusColor = Colors.grey;
        statusText = status ?? 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }

  void _navigateToEmployeeDetail(Employee employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDetailScreen(employee: employee),
      ),
    );
  }
}
