//STUDENT NAMES :BONTLE NICO MOTHUDI, MSAWAKHE MLAMBO, UNARINE HANGWANI, TSHIAMO GOMOLEMO GOITSEMODIMO, BENNY HLUNGWANE, Bukamuso Shudufhadzo Luvhengo 
//STUDENT NUMBERS : 224124772, 223059218,224073925, 223059551, 224022767, 224015143
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/application.dart';

class ApplicationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> submitApplication({
    required String userId,
    required int yearOfStudy,
    required Map<String, dynamic> firstModule,
    required Map<String, dynamic>? secondModule,
    required String documentUrl,
    String? additionalNotes,
  }) async {
    try {
      final applicationData = {
        'user_id': userId,
        'year_of_study': yearOfStudy,
        'status': 'pending',
        'document_url': documentUrl,
        'additional_notes': additionalNotes,
        'submitted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final result = await _supabase
          .from('applications')
          .insert(applicationData)
          .select()
          .single();

      final applicationId = result['id'];

      final firstModuleData = {
        'application_id': applicationId,
        'academic_level': firstModule['academic_level'],
        'module_name': firstModule['module_name'],
        'meets_requirements': firstModule['meets_requirements'],
      };

      await _supabase.from('module_applications').insert(firstModuleData);

      if (secondModule != null) {
        final secondModuleData = {
          'application_id': applicationId,
          'academic_level': secondModule['academic_level'],
          'module_name': secondModule['module_name'],
          'meets_requirements': secondModule['meets_requirements'],
        };

        await _supabase.from('module_applications').insert(secondModuleData);
      }

      return true;
    } catch (e) {
      print('Error submitting application: $e');
      return false;
    }
  }

  Future<List<Application>> getMyApplications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('applications')
          .select('*')
          .eq('user_id', userId)
          .order('submitted_at', ascending: false);

      final List<Application> applications = [];
      for (var app in response) {
        final application = Application.fromJson(app);

        final modulesResponse = await _supabase
            .from('module_applications')
            .select('*')
            .eq('application_id', application.id);

        application.modules.addAll(
          modulesResponse.map((m) => ModuleApplication.fromJson(m)),
        );
        applications.add(application);
      }

      return applications;
    } catch (e) {
      print('Error in getMyApplications: $e');
      return [];
    }
  }

  Future<List<Application>> getAllApplications() async {
    try {
      final applicationsData = await _supabase
          .from('applications')
          .select('*')
          .order('submitted_at', ascending: false);

      if (applicationsData.isEmpty) {
        return [];
      }

      final profilesData = await _supabase.from('profiles').select('*');

      final Map<String, Map<String, dynamic>> profileMap = {};
      for (var profile in profilesData) {
        profileMap[profile['id']] = profile;
      }

      List<Application> applications = [];

      for (var appData in applicationsData) {
        final application = Application.fromJson(appData);

        final profile = profileMap[application.userId];
        if (profile != null) {
          application.studentName = profile['full_name'] ?? 'Unknown';
          application.studentNumber =
              profile['student_number']?.toString() ?? 'N/A';
          application.studentEmail = profile['email'] ?? 'No email';
        } else {
          application.studentName =
              'User ${application.userId.substring(0, 8)}...';
          application.studentNumber = 'N/A';
          application.studentEmail = 'Profile missing';
        }

        final modulesResponse = await _supabase
            .from('module_applications')
            .select('*')
            .eq('application_id', application.id);

        application.modules.addAll(
          modulesResponse.map((m) => ModuleApplication.fromJson(m)),
        );

        applications.add(application);
      }

      return applications;
    } catch (e) {
      print('ERROR in getAllApplications: $e');
      return [];
    }
  }

  Future<void> updateApplicationStatus(
    String applicationId,
    String newStatus,
  ) async {
    try {
      await _supabase
          .from('applications')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', applicationId);
    } catch (e) {
      print('Error updating status: $e');
      rethrow;
    }
  }

  Future<void> deleteApplication(String applicationId) async {
    try {
      await _supabase
          .from('module_applications')
          .delete()
          .eq('application_id', applicationId);

      await _supabase.from('applications').delete().eq('id', applicationId);
    } catch (e) {
      print('Error deleting application: $e');
      rethrow;
    }
  }

  Future<List<Module>> getAllModules() async {
    try {
      final response = await _supabase
          .from('modules')
          .select('*')
          .order('academic_level', ascending: true)
          .order('module_code', ascending: true);

      return response.map((m) => Module.fromJson(m)).toList();
    } catch (e) {
      print('Error getting modules: $e');
      return [];
    }
  }
}
