//BONTLE NICO MOTHUDI 224124772
// MSAWAKHE MLAMBO 223059218
//UNARINE HANGWANI 223059218
//TSHIAMO GOMOLEMO GOITSEMODIMO 223059551
//BENNY HLUNGWANE 224022767
//Bukamuso Shudufhadzo Luvhengo 224015143

class Application {
  final String id;
  final String userId;
  final int yearOfStudy;
  final String status;
  final String documentUrl;
  final String? storagePath;
  final String? originalFilename;
  final int? fileSize;
  final String? additionalNotes;
  final DateTime submittedAt;
  final DateTime updatedAt;
  final List<ModuleApplication> modules;

  // For admin view - student info
  final String? studentName;
  final String? studentNumber;
  final String? studentEmail;

  Application({
    required this.id,
    required this.userId,
    required this.yearOfStudy,
    required this.status,
    required this.documentUrl,
    this.storagePath,
    this.originalFilename,
    this.fileSize,
    this.additionalNotes,
    required this.submittedAt,
    required this.updatedAt,
    this.modules = const [],
    this.studentName,
    this.studentNumber,
    this.studentEmail,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'],
      userId: json['user_id'],
      yearOfStudy: json['year_of_study'],
      status: json['status'],
      documentUrl: json['document_url'],
      storagePath: json['storage_path'],
      originalFilename: json['original_filename'],
      fileSize: json['file_size'],
      additionalNotes: json['additional_notes'],
      submittedAt: DateTime.parse(json['submitted_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      modules: [],
      studentName: json['profiles'] != null
          ? json['profiles']['full_name']
          : null,
      studentNumber: json['profiles'] != null
          ? json['profiles']['student_number']
          : null,
      studentEmail: json['profiles'] != null ? json['profiles']['email'] : null,
    );
  }
}

class ModuleApplication {
  final String id;
  final String applicationId;
  final int academicLevel;
  final String moduleName;
  final bool meetsRequirements;

  ModuleApplication({
    required this.id,
    required this.applicationId,
    required this.academicLevel,
    required this.moduleName,
    required this.meetsRequirements,
  });

  factory ModuleApplication.fromJson(Map<String, dynamic> json) {
    return ModuleApplication(
      id: json['id'],
      applicationId: json['application_id'],
      academicLevel: json['academic_level'],
      moduleName: json['module_name'],
      meetsRequirements: json['meets_requirements'],
    );
  }
}

class Module {
  final String id;
  final int academicLevel;
  final String moduleCode;
  final String moduleName;
  final String? description;

  Module({
    required this.id,
    required this.academicLevel,
    required this.moduleCode,
    required this.moduleName,
    this.description,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'],
      academicLevel: json['academic_level'],
      moduleCode: json['module_code'],
      moduleName: json['module_name'],
      description: json['description'],
    );
  }
}
