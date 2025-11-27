import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/employee_service.dart';

class Employee {
  final String id;
  final String? uid;
  final String? authId;
  final String name; 

  final String companyName;
  final String locationName;
  final bool has2FA;
  final DateTime updatedAt;
  final DateTime? createdAt;
  final String? firstName;
  final String? lastName;
  final String? company;
  final String? location;
  final String? branch;
  final String? nickname;
  final String? branchName;
  final String? status;
  final String? position;
  final String? positionName;
  final DateTime? joinDate;
  final String? maritalStatus;
  final String? profileImage;
  final String? role;
  final String? dateOfBirth;
  final String? primary_number;
  final String? email;
  final String? department;
  final String? managerId;
  final String? managerName;
  final Map<String, dynamic>? additionalInfo;

  Employee({
    required this.id,
    this.uid,
    this.authId,
    required this.name,

    required this.companyName,
    required this.locationName,
    required this.has2FA,
    required this.updatedAt,
    this.createdAt,
    this.firstName,
    this.nickname,
    this.lastName,
    this.company,
    this.primary_number,
    this.status,
    this.location,
    this.branch,
    this.branchName,
    this.dateOfBirth,
    this.position,
    this.positionName,
    this.joinDate,
    this.maritalStatus,
    this.profileImage,
    this.role,
    this.email,
    this.department,
    this.managerId,
    this.managerName,
    this.additionalInfo,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
   
    DateTime? parseDateTime(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is Map && timestamp.containsKey('_seconds')) {
        return DateTime.fromMillisecondsSinceEpoch(
          (timestamp['_seconds'] as int) * 1000,
        );
      }
      if (timestamp is String) {
        return DateTime.parse(timestamp);
      }
      return null;
    }

    return Employee(
      id: json['id'] ?? '',
      uid: json['uid'],
      authId: json['authId'],
      name: json['nickname'] ?? json['name'] ?? 'Unknown',
      primary_number: json['primary_number'] ?? json['primary_number'] ?? '',
      companyName: json['companyName'] ?? 'Unknown Company',
      locationName: json['locationName'] ?? 'Unknown Location',
      has2FA: json['has2FA'] ?? false,
      updatedAt: parseDateTime(json['updatedAt']) ?? DateTime.now(),
      createdAt: parseDateTime(json['createdAt']),
      firstName: json['firstName'],
      lastName: json['lastName'],
      nickname: json['nickname'],
      dateOfBirth: json['dateOfBirth'],
      company: json['company'],
      location: json['location'],
      branch: json['branch'],
      branchName: json['branchName'],
      status: json['status'],
      position: json['position'],
      positionName: json['positionName'],
      joinDate: parseDateTime(json['joinDate']),
      maritalStatus: json['maritalStatus'],
      profileImage: json['profileImage'],
      role: json['role'],
      email: json['email'],
      department: json['department'],
      managerId: json['managerId'],
      managerName: json['managerName'],
      additionalInfo: json['additionalInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'authId': authId,
      'nickname': nickname,
      'primaryNumber': primary_number,
      'companyName': companyName,
      'locationName': locationName,
      'has2FA': has2FA,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'firstName': firstName,
      'lastName': lastName,
      'company': company,
      'location': location,
      'branch': branch,
      'branchName': branchName,
      'dateOfBirth': dateOfBirth,
      'status': status,
      'position': position,
      'positionName': positionName,
      'joinDate': joinDate?.toIso8601String(),
      'maritalStatus': maritalStatus,
      'profileImage': profileImage,
      'role': role,
      'email': email,
      'department': department,
      'managerId': managerId,
      'managerName': managerName,
      'additionalInfo': additionalInfo,
    };
  }
}

class EmployeeRepository {
  final EmployeeService _employeeService;

  EmployeeRepository(this._employeeService);

  Future<List<Employee>> getEmployees({int page = 1, int limit = 50}) async {
    final response = await _employeeService.getEmployees(
      page: page,
      limit: limit,
    );
    return response.map((json) => Employee.fromJson(json)).toList();
  }

  Future<Employee> getEmployeeById(String id) async {
    final response = await _employeeService.getEmployeeById(id);
    return Employee.fromJson(response['data']);
  }
}

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  final employeeService = ref.watch(employeeServiceProvider);
  return EmployeeRepository(employeeService);
});
