import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'src/navigation/app_navigator.dart';
import 'src/context/cart_provider.dart'; // Corrected path
import 'package:geolocator/geolocator.dart';
import '../src/screens/voice_assistant.dart';
import '../src/context/voice_state.dart';
import '../src/context/group_cart_provider.dart'; // ✅ ADD THIS

Future<void> checkLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Handle denied permission
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Handle permanently denied permission
    return;
  }

  // Permission granted, you can now access location
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check location permission when app starts
  await checkLocationPermission();

  // Set status bar color and icon brightness
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFF6B35),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final VoiceAssistant _voiceAssistant = VoiceAssistant();

  @override
  void initState() {
    super.initState();
    _voiceAssistant.init(); // 👈 Auto-start listening
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => VoiceState()),
        ChangeNotifierProvider(
          create: (context) => GroupCartProvider(),
        ), // ✅ ADD THIS
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Platter',
        theme: ThemeData(
          primaryColor: const Color(0xFFFF6B35),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF6B35),
            primary: const Color(0xFFFF6B35),
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Color(0xFFFF6B35),
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.light,
            ),
          ),
          useMaterial3: true,
        ),
        home: const AppNavigator(),
      ),
    );
  }
}
