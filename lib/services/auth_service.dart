//STUDENT NAMES :BONTLE NICO MOTHUDI, MSAWAKHE MLAMBO, UNARINE HANGWANI, TSHIAMO GOMOLEMO GOITSEMODIMO, BENNY HLUNGWANE, Bukamuso Shudufhadzo Luvhengo
//STUDENT NUMBERS : 224124772, 223059218,224073925, 223059551, 224022767, 224015143
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
          'role': 'student',
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

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  Future<String?> getUserRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        await _createProfile(user);
        return 'student';
      }

      return response['role'];
    } catch (e) {
      return null;
    }
  }

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

  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }

  Future<bool> isStudent() async {
    final role = await getUserRole();
    return role == 'student';
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      rethrow;
    }
  }

  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  String getFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    } else if (errorString.contains('user already registered')) {
      return 'This email is already registered. Please login instead.';
    } else if (errorString.contains(
      'password should be at least 6 characters',
    )) {
      return 'Password must be at least 6 characters long.';
    } else if (errorString.contains('email not confirmed')) {
      return 'Please verify your email address before logging in.';
    } else if (errorString.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return error.toString().replaceAll('Exception: ', '');
    }
  }
}
