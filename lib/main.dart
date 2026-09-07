import 'package:flutter/material.dart';

import 'demo_repository.dart';
import 'domain.dart';
import 'matching_view_model.dart';
import 'screens.dart';

void main() => runApp(PawVerseApp(repository: DemoMatchingRepository()));

class PawVerseApp extends StatefulWidget {
  const PawVerseApp({super.key, required this.repository});
  final MatchingRepository repository;
  @override
  State<PawVerseApp> createState() => _PawVerseAppState();
}

class _PawVerseAppState extends State<PawVerseApp> {
  late final model = MatchingViewModel(widget.repository)..load();
  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PawVerse · Pet Matching',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff214f43),
        primary: const Color(0xff214f43),
        secondaryContainer: const Color(0xffdceda0),
        surface: const Color(0xfffcfbf6),
      ),
      scaffoldBackgroundColor: const Color(0xfffcfbf6),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xfffcfbf6)),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: MatchingHome(model: model),
  );
}
