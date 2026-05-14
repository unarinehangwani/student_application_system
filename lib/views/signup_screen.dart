//STUDENT NUMBERS :BONTLE NICO MOTHUDI, MSAWAKHE MLAMBO, UNARINE HANGWANI, TSHIAMO GOMOLEMO GOITSEMODIMO, BENNY HLUNGWANE, Bukamuso Shudufhadzo Luvhengo 
//STUDENT NAMES : 224124772, 223059218,224073925, 223059551, 224022767, 224015143
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _studentNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms'), backgroundColor: Colors.orange),
      );
      return;
    }

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    final success = await authViewModel.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      studentNumber: _studentNumberController.text.trim(),
    );

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Registration Successful!'),
          content: const Text('Your account has been created. Please login.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authViewModel.errorMessage ?? 'Registration failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Icon(Icons.person_add, size: 60, color: Colors.blue.shade600),
              const SizedBox(height: 16),
              Text('Create Student Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
              const SizedBox(height: 32),
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                validator: (value) => value == null || value.isEmpty ? 'Please enter full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Student Number (8 digits)', prefixIcon: Icon(Icons.badge)),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter student number';
                  if (value.length != 8) return 'Must be 8 digits';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                validator: (value) => value == null || value.isEmpty ? 'Please enter email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                ),
                validator: (value) => value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                ),
                validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(value: _agreeTerms, onChanged: (value) => setState(() => _agreeTerms = value!)),
                  Expanded(child: Text('I agree to the Terms and Conditions')),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authViewModel.isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: authViewModel.isLoading ? const CircularProgressIndicator() : const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
