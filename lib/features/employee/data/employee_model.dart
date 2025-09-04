class Employee {
  final String id;
  final String? uid;
  final String? authId;
  final String? nickname;
  final String firstName;
  final String lastName;
  final String email;
  final String? primaryNumber;
  final String? company;
  final String? companyName;
  final String? location;
  final String? locationName;
  final String? branch;
  final String? branchName;
  final String? position;
  final String? positionName;
  final String? status;
  final String? role;
  final String? roleName;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankHolderName;
  final String? profileImage;
  final bool has2FA;
  final String? joinDate;
  final String? maritalStatus;
  final String? dateOfBirth;
  final String? gender;
  final String? salary;
  final String? idAddress;
  final String? subDistrict;
  final String? district;
  final String? province;
  final String? postalCode;
  final String? idType;
  final String? idCardNumber;
  final String? nationality;
  final String? title;
  final String? department;
  final String? password;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Employee({
    required this.id,
    this.uid,
    this.authId,
    this.nickname,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.primaryNumber,
    this.company,
    this.companyName,
    this.location,
    this.locationName,
    this.branch,
    this.branchName,
    this.position,
    this.positionName,
    this.status,
    this.role,
    this.roleName,
    this.bankName,
    this.bankAccountNumber,
    this.bankHolderName,
    this.profileImage,
    this.has2FA = false,
    this.joinDate,
    this.maritalStatus,
    this.dateOfBirth,
    this.gender,
    this.salary,
    this.idAddress,
    this.subDistrict,
    this.district,
    this.province,
    this.postalCode,
    this.idType,
    this.idCardNumber,
    this.nationality,
    this.title,
    this.department,
    this.password,
    this.createdAt,
    this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? json['_id'] ?? '',
      uid: json['uid'],
      authId: json['authId'],
      nickname: json['nickname'],
      firstName: json['firstName'] ?? json['first_name'] ?? '',
      lastName: json['lastName'] ?? json['last_name'] ?? '',
      email: json['email'] ?? '',
      primaryNumber: json['primaryNumber'] ?? json['primary_number'],
      company: json['company'],
      companyName: json['companyName'],
      location: json['location'],
      locationName: json['locationName'],
      branch: json['branch'],
      branchName: json['branchName'],
      position: json['position'],
      positionName: json['positionName'],
      status: json['status'],
      role: json['role'],
      roleName: json['roleName'],
      bankName: json['bankName'],
      bankAccountNumber: json['bankAccountNumber'],
      bankHolderName: json['bankHolderName'],
      profileImage: json['profileImage'] ?? json['profile_image'],
      has2FA: json['has2FA'] ?? false,
      joinDate: json['joinDate'],
      maritalStatus: json['maritalStatus'],
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      salary: json['salary'],
      idAddress: json['idAddress'],
      subDistrict: json['subDistrict'],
      district: json['district'],
      province: json['province'],
      postalCode: json['postalCode'],
      idType: json['idType'],
      idCardNumber: json['idCardNumber'],
      nationality: json['nationality'],
      title: json['title'],
      department: json['department'],
      password: json['password'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'authId': authId,
      'nickname': nickname,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'primaryNumber': primaryNumber,
      'company': company,
      'companyName': companyName,
      'location': location,
      'locationName': locationName,
      'branch': branch,
      'branchName': branchName,
      'position': position,
      'positionName': positionName,
      'status': status,
      'role': role,
      'roleName': roleName,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'bankHolderName': bankHolderName,
      'profileImage': profileImage,
      'has2FA': has2FA,
      'joinDate': joinDate,
      'maritalStatus': maritalStatus,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'salary': salary,
      'idAddress': idAddress,
      'subDistrict': subDistrict,
      'district': district,
      'province': province,
      'postalCode': postalCode,
      'idType': idType,
      'idCardNumber': idCardNumber,
      'nationality': nationality,
      'title': title,
      'department': department,
      'password': password,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Employee copyWithPassword(String newPassword) {
    return Employee(
      id: id,
      uid: uid,
      authId: authId,
      nickname: nickname,
      firstName: firstName,
      lastName: lastName,
      email: email,
      primaryNumber: primaryNumber,
      company: company,
      companyName: companyName,
      location: location,
      locationName: locationName,
      branch: branch,
      branchName: branchName,
      position: position,
      positionName: positionName,
      status: status,
      role: role,
      roleName: roleName,
      bankName: bankName,
      bankAccountNumber: bankAccountNumber,
      bankHolderName: bankHolderName,
      profileImage: profileImage,
      has2FA: has2FA,
      joinDate: joinDate,
      maritalStatus: maritalStatus,
      dateOfBirth: dateOfBirth,
      gender: gender,
      salary: salary,
      idAddress: idAddress,
      subDistrict: subDistrict,
      district: district,
      province: province,
      postalCode: postalCode,
      idType: idType,
      idCardNumber: idCardNumber,
      nationality: nationality,
      title: title,
      department: department,
      password: newPassword,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get fullName => '$firstName $lastName';
}
