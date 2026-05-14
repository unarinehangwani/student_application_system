//STUDENT NUMBERS :BONTLE NICO MOTHUDI, MSAWAKHE MLAMBO, UNARINE HANGWANI, TSHIAMO GOMOLEMO GOITSEMODIMO, BENNY HLUNGWANE, Bukamuso Shudufhadzo Luvhengo 
//STUDENT NAMES : 224124772, 223059218,224073925, 223059551, 224022767, 224015143
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    required String userId,
    String? applicationId,
    File? mobileFile,
    Uint8List? webBytes,
    String? fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final folderName = applicationId ?? 'temp_${userId}_$timestamp';
      
      String storagePath;
      
      if (kIsWeb && webBytes != null && fileName != null) {
        final safeFileName = '${timestamp}_$fileName';
        storagePath = '$folderName/$safeFileName';
        
        await _supabase.storage
            .from('application_documents')
            .uploadBinary(storagePath, webBytes);
            
      } else if (mobileFile != null) {
        final fileExtension = mobileFile.path.split('.').last;
        final safeFileName = '${timestamp}_$timestamp.$fileExtension';
        storagePath = '$folderName/$safeFileName';
        
        final fileBytes = await mobileFile.readAsBytes();
        
        await _supabase.storage
            .from('application_documents')
            .uploadBinary(storagePath, fileBytes);
      } else {
        throw Exception('No file provided');
      }
      
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
    File? mobileFile,
    Uint8List? webFileBytes,
    String? webFileName,
    String? additionalNotes,
    String? existingDocumentUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser!.id;
      
      String? documentUrl = existingDocumentUrl;
      
      if (kIsWeb && webFileBytes != null && webFileName != null) {
        documentUrl = await uploadFile(
          userId: userId,
          applicationId: null,
          webBytes: webFileBytes,
          fileName: webFileName,
        );
      } else if (mobileFile != null) {
        documentUrl = await uploadFile(
          userId: userId,
          applicationId: null,
          mobileFile: mobileFile,
        );
      }
      
      if (documentUrl == null && existingDocumentUrl == null) {
        throw Exception('Document is required');
      }
      
      final applicationData = {
        'user_id': userId,
        'year_of_study': yearOfStudy,
        'status': 'pending',
        'document_url': documentUrl ?? existingDocumentUrl,
        'additional_notes': additionalNotes,
        'submitted_at': DateTime.now().toIso8601String(),
      };
      
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
        
        await _supabase
            .from('module_applications')
            .delete()
            .eq('application_id', _editingApplicationId!);
      }
      
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
