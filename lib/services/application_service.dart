//Group Members
//BONTLE NICO MOTHUDI 224124772
// MSAWAKHE MLAMBO 223059218
//UNARINE HANGWANI 223059218
//TSHIAMO GOMOLEMO GOITSEMODIMO 223059551
//BENNY HLUNGWANE 224022767
//BUKAMUSO SHUDUFHADZO LUVHENGO 224015143

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/application.dart';

class ApplicationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all applications for current student
  Future<List<Application>> getMyApplications() async {
    final userId = _supabase.auth.currentUser!.id;
    
    final response = await _supabase
        .from('applications')
        .select('*')
        .eq('user_id', userId)
        .order('submitted_at', ascending: false);
    
    final List<Application> applications = [];
    for (var app in response) {
      final application = Application.fromJson(app);
      // Fetch modules for this application
      final modulesResponse = await _supabase
          .from('module_applications')
          .select('*')
          .eq('application_id', application.id);
      
      application.modules.addAll(
        modulesResponse.map((m) => ModuleApplication.fromJson(m))
      );
      applications.add(application);
    }
    
    return applications;
  }

  // Get all applications for admin
  Future<List<Application>> getAllApplications({String? statusFilter}) async {
    var query = _supabase
        .from('applications')
        .select('*, profiles(full_name, student_number, email)');
    
    if (statusFilter != null && statusFilter != 'all') {
      query = query.eq('status', statusFilter);
    }
    
    final response = await query.order('submitted_at', ascending: false);
    
    final List<Application> applications = [];
    for (var app in response) {
      final application = Application.fromJson(app);
      // Fetch modules
      final modulesResponse = await _supabase
          .from('module_applications')
          .select('*')
          .eq('application_id', application.id);
      
      application.modules.addAll(
        modulesResponse.map((m) => ModuleApplication.fromJson(m))
      );
      applications.add(application);
    }
    
    return applications;
  }

  // Get single application with details
  Future<Application?> getApplicationById(String applicationId) async {
    final response = await _supabase
        .from('applications')
        .select('*, profiles(full_name, student_number, email)')
        .eq('id', applicationId)
        .single();
    
    final application = Application.fromJson(response);
    
    final modulesResponse = await _supabase
        .from('module_applications')
        .select('*')
        .eq('application_id', application.id);
    
    application.modules.addAll(
      modulesResponse.map((m) => ModuleApplication.fromJson(m))
    );
    
    return application;
  }

  // Check if user already has an application
  Future<bool> hasActiveApplication() async {
    final userId = _supabase.auth.currentUser!.id;
    
    final response = await _supabase
        .from('applications')
        .select('id')
        .eq('user_id', userId)
        .neq('status', 'rejected')
        .limit(1);
    
    return response.isNotEmpty;
  }

  // Get available modules
  Future<List<Module>> getModulesByLevel(int level) async {
    final response = await _supabase
        .from('modules')
        .select('*')
        .eq('academic_level', level)
        .order('module_code');
    
    return response.map((m) => Module.fromJson(m)).toList();
  }

  // Get all modules
  Future<List<Module>> getAllModules() async {
    final response = await _supabase
        .from('modules')
        .select('*')
        .order('academic_level, module_code');
    
    return response.map((m) => Module.fromJson(m)).toList();
  }

  // Update application status (admin only)
  Future<void> updateApplicationStatus(String applicationId, String newStatus) async {
    await _supabase
        .from('applications')
        .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', applicationId);
  }

  // Delete application (admin or student with pending status)
  Future<void> deleteApplication(String applicationId) async {
    await _supabase
        .from('applications')
        .delete()
        .eq('id', applicationId);
  }
}