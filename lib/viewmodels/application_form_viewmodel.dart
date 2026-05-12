//BONTLE NICO MOTHUDI 224124772
// MSAWAKHE MLAMBO 223059218
//UNARINE HANGWANI 223059218
//TSHIAMO GOMOLEMO GOITSEMODIMO 223059551
//BENNY HLUNGWANE 224022767
//BUKAMUSO SHUDUFHADZO LUVHENGO 224015143
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/application.dart';
import '../services/application_service.dart';

class ApplicationFormViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ApplicationService _applicationService = ApplicationService();
  
  bool _isLoading = false;
  bool _isEditing = false;
  String? _editingApplicationId;
  String? _errorMessage;
  List<Module> _availableModules = [];

  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  String? get errorMessage => _errorMessage;
  List<Module> get availableModules => _availableModules;

  Future<void> loadModules() async {
    _availableModules = await _applicationService.getAllModules();
    notifyListeners();
  }

  Future<String?> uploadFile({
    required File file,
    required String userId,
    required String applicationId,
  }) async {
    try {
      final fileExtension = file.path.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${applicationId}_$timestamp.$fileExtension';
      final storagePath = '$userId/$fileName';
      
      final fileBytes = await file.readAsBytes();
      
      await _supabase.storage
          .from('application_documents')
          .uploadBinary(storagePath, fileBytes);
      
      final publicUrl = _supabase.storage
          .from('application_documents')
          .getPublicUrl(storagePath);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<bool> submitApplication({
    required int yearOfStudy,
    required Map<String, dynamic> firstModule,
    required Map<String, dynamic>? secondModule,
    required File? document,
    String? additionalNotes,
    String? existingDocumentUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser!.id;
      final applicationId = _editingApplicationId ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      String? documentUrl = existingDocumentUrl;
      
      // Upload new document if provided
      if (document != null) {
        documentUrl = await uploadFile(
          file: document,
          userId: userId,
          applicationId: applicationId,
        );
      }
      
      if (documentUrl == null) {
        throw Exception('Document is required');
      }
      
      // Prepare application data
      final applicationData = {
        if (_editingApplicationId == null) 'id': applicationId,
        'user_id': userId,
        'year_of_study': yearOfStudy,
        'status': 'pending',
        'document_url': documentUrl,
        'additional_notes': additionalNotes,
        'submitted_at': DateTime.now().toIso8601String(),
      };
      
      // Insert or update application
      String finalApplicationId;
      if (_editingApplicationId == null) {
        final result = await _supabase
            .from('applications')
            .insert(applicationData)
            .select('id')
            .single();
        finalApplicationId = result['id'];
      } else {
        await _supabase
            .from('applications')
            .update(applicationData)
            .eq('id', _editingApplicationId!);
        finalApplicationId = _editingApplicationId!;
        
        // Delete old module applications
        await _supabase
            .from('module_applications')
            .delete()
            .eq('application_id', _editingApplicationId!);
      }
      
      // Insert module applications
      final modules = [firstModule];
      if (secondModule != null) {
        modules.add(secondModule);
      }
      
      for (var module in modules) {
        await _supabase.from('module_applications').insert({
          'application_id': finalApplicationId,
          'academic_level': module['academic_level'],
          'module_name': module['module_name'],
          'meets_requirements': module['meets_requirements'],
        });
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setEditingMode(String applicationId) {
    _isEditing = true;
    _editingApplicationId = applicationId;
  }

  void reset() {
    _isLoading = false;
    _isEditing = false;
    _editingApplicationId = null;
    _errorMessage = null;
  }
}