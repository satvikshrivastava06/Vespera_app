import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vespera/screens/home_screen.dart';
import 'package:vespera/widgets/vespera_style.dart';

void main() {
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
