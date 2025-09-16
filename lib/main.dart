import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'login_screen.dart';
import 'language_selection_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'setup_profile_personal_screen.dart';
import 'setup_profile_vehicle_screen.dart';
import 'setup_profile_documents_screen.dart';
import 'sos_emergency_screen.dart';
import 'trip_history_screen.dart';
import 'journey_planner_screen.dart';
import 'support_center_screen.dart';
import 'chat_support_screen.dart';
import 'theme_notifier.dart';
import 'dart:developer' as developer;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    developer.log('Successfully loaded .env file', name: 'Main');
  } catch (e) {
    developer.log('Error loading .env file: $e', name: 'Main');
  }
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeNotifier(),
      child: const MargDarshakApp(),
    ),
  );
}

class MargDarshakApp extends StatelessWidget {
  const MargDarshakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'MargDarshak',
          debugShowCheckedModeBanner: false,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/language': (context) => const LanguageSelectionScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/setup_profile_personal': (context) => const SetupProfilePersonalScreen(),
            '/setup_profile_vehicle': (context) => const SetupProfileVehicleScreen(),
            '/setup_profile_documents': (context) => const SetupProfileDocumentsScreen(),
            '/sos_emergency': (context) => const SosEmergencyScreen(),
            '/trip_history': (context) => const TripHistoryScreen(),
            '/journey_planner': (context) => const JourneyPlannerScreen(),
            '/support_center': (context) => const SupportCenterScreen(),
            '/chat_support': (context) => const ChatSupportScreen(),
          },
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorSchemeSeed: const Color(0xFF6366F1), // Matches LoginScreen gradient
      useMaterial3: true,
      brightness: Brightness.light,
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light, // White icons on status bar
          statusBarBrightness: Brightness.dark, // For iOS
        ),
        backgroundColor: Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      cardColor: Colors.white,
      dividerColor: Colors.grey,
      iconTheme: const IconThemeData(color: Colors.black54),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black54),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.black54,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorSchemeSeed: const Color(0xFF6366F1), // Matches LoginScreen gradient
      useMaterial3: true,
      brightness: Brightness.dark,
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Black icons on status bar
          statusBarBrightness: Brightness.light, // For iOS
        ),
        backgroundColor: Color(0xFF121212),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      dividerColor: Colors.white24,
      iconTheme: const IconThemeData(color: Colors.white70),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white70,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1E1E1E),
      ),
    );
  }
}
