//BONTLE NICO MOTHUDI 224124772
// MSAWAKHE MLAMBO 223059218
//UNARINE HANGWANI 223059218
//TSHIAMO GOMOLEMO GOITSEMODIMO 223059551
//BENNY HLUNGWANE 224022767
//Bukamuso Shudufhadzo Luvhengo 224015143
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? studentNumber;
  final int? yearOfStudy;
  final String role;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.studentNumber,
    this.yearOfStudy,
    required this.role,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      studentNumber: json['student_number'],
      yearOfStudy: json['year_of_study'],
      role: json['role'] ?? 'student',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'student_number': studentNumber,
      'year_of_study': yearOfStudy,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
