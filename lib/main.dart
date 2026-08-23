import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/plant_provider.dart';
import 'providers/scan_provider.dart';
import 'services/auth_service.dart';
import 'services/onboarding_service.dart';
import 'services/plant_service.dart';
import 'services/scan_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  // Initialize Firebase Core
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp warning: $e');
  }

  // Initialize local storage services
  final storageService = StorageService();
  final onboardingService = OnboardingService();
  await onboardingService.init();

  final authService = AuthService(storageService: storageService);
  final plantService = PlantService();
  final scanService = ScanService();

  runApp(
    MultiProvider(
      providers: [
        // ── Services ──
        Provider<OnboardingService>.value(value: onboardingService),
        Provider<StorageService>.value(value: storageService),

        // ── Providers ──
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => PlantProvider(plantService: plantService),
        ),
        ChangeNotifierProvider(
          create: (_) => ScanProvider(scanService: scanService),
        ),
        ChangeNotifierProvider(
          create: (_) => NavigationProvider(),
        ),
      ],
      child: const App(),
    ),
  );
}
