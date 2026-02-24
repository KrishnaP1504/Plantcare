import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_plants_screen.dart';
import 'screens/details_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/account_settings_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/plant_guide_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/disease_result_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    runApp(const MyApp());
  } catch (e) {
    runApp(ErrorApp(message: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plant Care',
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/my_plants': (context) => const MyPlantsScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/profile': (context) => const AccountSettingsScreen(),
        '/notifications': (context) => const NotificationSettingsScreen(),
        '/guide': (context) => const PlantGuideScreen(),
        '/scanner': (context) => const ScannerScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/signup') {
          final args = settings.arguments as String;
          return MaterialPageRoute(builder: (_) => SignupScreen(phoneNumber: args));
        }
        if (settings.name == '/details') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(builder: (_) => DetailsScreen(plantData: args));
        }
        // ✅ NEW: Handle AI Result Route
        if (settings.name == '/disease_result') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => DiseaseResultScreen(
              resultData: args['result'],
              base64Image: args['image'],
            )
          );
        }
        return null;
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Startup Error: $message")))));
  }
}