//STUDENT NUMBERS :BONTLE NICO MOTHUDI, MSAWAKHE MLAMBO, UNARINE HANGWANI, TSHIAMO GOMOLEMO GOITSEMODIMO, BENNY HLUNGWANE, Bukamuso Shudufhadzo Luvhengo 
//STUDENT NAMES : 224124772, 223059218,224073925, 223059551, 224022767, 224015143
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;
  String? _userRole;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  String? get userRole => _userRole;

  AuthViewModel() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _currentUser = _authService.getCurrentUser();
    if (_currentUser != null) {
      _userRole = await _authService.getUserRole();
    }
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String studentNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (studentNumber.length != 8 ||
          !RegExp(r'^\d+$').hasMatch(studentNumber)) {
        _errorMessage = 'Student number must be 8 digits';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        studentNumber: studentNumber,
      );

      if (response.user != null) {
        _currentUser = response.user;
        _userRole = await _authService.getUserRole();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Sign up failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _authService.getFriendlyErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = response.user;
        _userRole = await _authService.getUserRole();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _authService.getFriendlyErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _userRole = null;
    notifyListeners();
  }

  bool isAuthenticated() {
    return _authService.isAuthenticated();
  }
}
