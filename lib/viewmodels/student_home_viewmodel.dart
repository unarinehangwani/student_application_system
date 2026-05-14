//STUDENT NAMES :BONTLE NICO MOTHUDI, MSAWAKHE MLAMBO, UNARINE HANGWANI, TSHIAMO GOMOLEMO GOITSEMODIMO, BENNY HLUNGWANE, Bukamuso Shudufhadzo Luvhengo 
//STUDENT NUMBERS : 224124772, 223059218,224073925, 223059551, 224022767, 224015143
import 'package:flutter/material.dart';
import '../models/application.dart';
import '../services/application_service.dart';

class StudentHomeViewModel extends ChangeNotifier {
  final ApplicationService _applicationService = ApplicationService();
  
  List<Application> _applications = [];
  bool _isLoading = true;
  bool _hasActiveApplication = false;
  String? _errorMessage;

  List<Application> get applications => _applications;
  bool get isLoading => _isLoading;
  bool get hasActiveApplication => _hasActiveApplication;
  String? get errorMessage => _errorMessage;

  Future<void> loadApplications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _applications = await _applicationService.getMyApplications();
      _hasActiveApplication = _applications.any(
        (app) => app.status == 'pending' || app.status == 'approved'
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteApplication(String applicationId) async {
    try {
      await _applicationService.deleteApplication(applicationId);
      await loadApplications();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  bool canSubmitNewApplication() {
    return !_hasActiveApplication;
  }
}
