import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/location_provider.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'views/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider(storageService)),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const BloodBankApp(),
    ),
  );
}

class BloodBankApp extends StatelessWidget {
  const BloodBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeFlow Blood Bank',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
