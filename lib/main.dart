import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:vespera/screens/home_screen.dart';
import 'package:vespera/services/auth_service.dart';
import 'package:vespera/widgets/vespera_style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.vespera.app.playback',
    androidNotificationChannelName: 'Vespera playback',
    androidNotificationOngoing: true,
  );
  // VSP-007: Ensure this install has an anonymous device-bound token.
  // This is a no-op on subsequent launches when the token already exists.
  await AuthService().ensureBootstrapped();
  runApp(const VesperaApp());
}

class VesperaApp extends StatelessWidget {
  const VesperaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vespera',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: VesperaStyle.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: VesperaStyle.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A1B9A),
          surface: VesperaStyle.background,
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      home: const HomeScreen(),
    );
  }
}
