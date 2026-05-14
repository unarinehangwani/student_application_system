//STUDENT NAMES :BONTLE NICO MOTHUDI, MSAWAKHE MLAMBO, UNARINE HANGWANI, TSHIAMO GOMOLEMO GOITSEMODIMO, BENNY HLUNGWANE, Bukamuso Shudufhadzo Luvhengo 
//STUDENT NUMBERS : 224124772, 223059218,224073925, 223059551, 224022767, 224015143

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
  List<ModuleApplication> modules;
  
  // For admin view - student info
  String? studentName;
  String? studentNumber;
  String? studentEmail;

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
      status: json['status'] ?? 'pending',
      documentUrl: json['document_url'] ?? '',
      storagePath: json['storage_path'],
      originalFilename: json['original_filename'],
      fileSize: json['file_size'],
      additionalNotes: json['additional_notes'],
      submittedAt: json['submitted_at'] != null 
          ? DateTime.parse(json['submitted_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      modules: [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'year_of_study': yearOfStudy,
      'status': status,
      'document_url': documentUrl,
      'storage_path': storagePath,
      'original_filename': originalFilename,
      'file_size': fileSize,
      'additional_notes': additionalNotes,
      'submitted_at': submittedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
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
      meetsRequirements: json['meets_requirements'] ?? false,
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
