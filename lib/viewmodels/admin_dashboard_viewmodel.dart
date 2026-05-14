//STUDENT NUMBERS :BONTLE NICO MOTHUDI, MSAWAKHE MLAMBO, UNARINE HANGWANI, TSHIAMO GOMOLEMO GOITSEMODIMO, BENNY HLUNGWANE, Bukamuso Shudufhadzo Luvhengo 
//STUDENT NAMES : 224124772, 223059218,224073925, 223059551, 224022767, 224015143
import 'package:flutter/material.dart';
import '../models/application.dart';
import '../services/application_service.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  final ApplicationService _applicationService = ApplicationService();

  List<Application> _applications = [];
  List<Application> _filteredApplications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatusFilter = 'all';

  List<Application> get applications => _filteredApplications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatusFilter => _selectedStatusFilter;

  int get totalCount => _applications.length;
  int get pendingCount =>
      _applications.where((a) => a.status == 'pending').length;
  int get approvedCount =>
      _applications.where((a) => a.status == 'approved').length;
  int get rejectedCount =>
      _applications.where((a) => a.status == 'rejected').length;

  Future<void> loadApplications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _applications = await _applicationService.getAllApplications();
      _applyFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading applications: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatusFilter(String filter) {
    _selectedStatusFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_selectedStatusFilter == 'all') {
      _filteredApplications = List.from(_applications);
    } else {
      _filteredApplications = _applications
          .where((app) => app.status == _selectedStatusFilter)
          .toList();
    }
  }

  Future<bool> updateStatus(String applicationId, String newStatus) async {
    try {
      await _applicationService.updateApplicationStatus(applicationId, newStatus);
      await loadApplications();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
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
}
