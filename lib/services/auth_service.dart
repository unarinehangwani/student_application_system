//Group Members
//BONTLE NICO MOTHUDI 224124772
// MSAWAKHE MLAMBO 223059218
//UNARINE HANGWANI 223059218
//TSHIAMO GOMOLEMO GOITSEMODIMO 223059551
//BENNY HLUNGWANE 224022767
//BUKAMUSO SHUDUFHADZO LUVHENGO 224015143

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================
  // SIGN UP - Student Registration
  // ============================================
  /// Registers a new student user
  /// Parameters:
  ///   - email: Student's email address
  ///   - password: Password (min 6 characters)
  ///   - fullName: Student's full name
  ///   - studentNumber: 8-digit student number
  /// Returns: AuthResponse with user data
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String studentNumber,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'student_number': studentNumber,
          'role': 'student',  // Always 'student' for registration
        },
      );
      
      if (response.user == null) {
        throw Exception('Sign up failed - no user returned');
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // SIGN IN - Login for both Students and Admins
  // ============================================
  /// Authenticates a user with email and password
  /// Returns: AuthResponse with user data
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Invalid email or password');
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // SIGN OUT - Logout user
  // ============================================
  /// Signs out the currently authenticated user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // GET CURRENT USER
  // ============================================
  /// Returns the currently authenticated user or null
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // ============================================
  // GET USER ROLE
  // ============================================
  /// Fetches the role of the current user from profiles table
  /// Returns: 'student', 'admin', or null if not found
  Future<String?> getUserRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    
    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();  // Use maybeSingle to avoid exception if not found
      
      if (response == null) {
        // Profile not found - create it
        await _createProfile(user);
        return 'student';
      }
      
      return response['role'];
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // CREATE PROFILE (if missing)
  // ============================================
  /// Creates a profile for a user if it doesn't exist
  Future<void> _createProfile(User user) async {
    try {
      await _supabase.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'] ?? 'Student User',
        'role': user.userMetadata?['role'] ?? 'student',
      });
    } catch (e) {
      // Profile might already exist
    }
  }

  // ============================================
  // CHECK IF USER IS ADMIN
  // ============================================
  /// Returns true if the current user has admin role
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }

  // ============================================
  // CHECK IF USER IS STUDENT
  // ============================================
  /// Returns true if the current user has student role
  Future<bool> isStudent() async {
    final role = await getUserRole();
    return role == 'student';
  }

  // ============================================
  // RESET PASSWORD
  // ============================================
  /// Sends a password reset email to the user
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // UPDATE PASSWORD
  // ============================================
  /// Updates the password for the current user
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // UPDATE USER PROFILE
  // ============================================
  /// Updates the user's profile information
  Future<void> updateProfile({
    String? fullName,
    String? studentNumber,
    int? yearOfStudy,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    
    final Map<String, dynamic> updates = {};
    if (fullName != null) updates['full_name'] = fullName;
    if (studentNumber != null) updates['student_number'] = studentNumber;
    if (yearOfStudy != null) updates['year_of_study'] = yearOfStudy;
    updates['updated_at'] = DateTime.now().toIso8601String();
    
    try {
      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', user.id);
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // GET USER PROFILE
  // ============================================
  /// Gets the full profile of the current user
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();
      
      return response;
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // SESSION MANAGEMENT
  // ============================================
  /// Returns true if a user is currently authenticated
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  /// Gets the current session
  Future<Session?> getSession() async {
    return _supabase.auth.currentSession;
  }

  /// Refreshes the current session
  Future<AuthResponse> refreshSession() async {
    return await _supabase.auth.refreshSession();
  }

  // ============================================
  // ERROR HANDLING HELPER
  // ============================================
  /// Converts Supabase error messages to user-friendly messages
  String getFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    } else if (errorString.contains('user already registered')) {
      return 'This email is already registered. Please login instead.';
    } else if (errorString.contains('password should be at least 6 characters')) {
      return 'Password must be at least 6 characters long.';
    } else if (errorString.contains('email not confirmed')) {
      return 'Please verify your email address before logging in.';
    } else if (errorString.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else {
      return error.toString().replaceAll('Exception: ', '');
    }
  }
}