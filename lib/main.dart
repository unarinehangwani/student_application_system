//BONTLE NICO MOTHUDI 224124772
// MSAWAKHE MLAMBO 223059218
//UNARINE HANGWANI 223059218
//TSHIAMO GOMOLEMO GOITSEMODIMO 223059551
//BENNY HLUNGWANE 224022767
//Bukamuso Shudufhadzo Luvhengo 224015143
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ViewModels
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/student_home_viewmodel.dart';
import 'viewmodels/application_form_viewmodel.dart';
import 'viewmodels/admin_dashboard_viewmodel.dart';
// Views
import 'views/login_screen.dart';
import 'views/student_home_screen.dart';
import 'views/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  await Supabase.initialize(
    url:
        'https://hfmuuytblxcaxhnbnzxu.supabase.co', 
    anonKey:
        'sb_publishable_IgyouyrfFv6ISfHCpTIiEA_CwZXRA8M', 
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => StudentHomeViewModel()),
        ChangeNotifierProvider(create: (_) => ApplicationFormViewModel()),
        ChangeNotifierProvider(create: (_) => AdminDashboardViewModel()),
      ],
      child: MaterialApp(
        title: 'Student Assistant System',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const AuthWrapper());
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/student-home':
              return MaterialPageRoute(
                  builder: (_) => const StudentHomeScreen());
            case '/admin-dashboard':
              return MaterialPageRoute(
                  builder: (_) => const AdminDashboardScreen());
            default:
              return MaterialPageRoute(builder: (_) => const AuthWrapper());
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    if (authViewModel.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authViewModel.currentUser == null) {
      return const LoginScreen();
    }

    // Redirect based on role - ADMINS GO TO ADMIN DASHBOARD, STUDENTS GO TO STUDENT DASHBOARD
    if (authViewModel.userRole == 'admin') {
      return const AdminDashboardScreen();
    } else {
      return const StudentHomeScreen();
    }
  }
}
