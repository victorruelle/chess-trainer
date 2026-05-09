import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/profile_provider.dart';
import 'screens/opening_selection_screen.dart';
import 'screens/welcome_screen.dart';

class ChessTrainerApp extends StatelessWidget {
  const ChessTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Openings Trainer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A7C59),
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const _AppGate(),
    );
  }
}

class _AppGate extends ConsumerStatefulWidget {
  const _AppGate();

  @override
  ConsumerState<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<_AppGate> {
  bool _guestMode = false;

  @override
  Widget build(BuildContext context) {
    if (_guestMode) return const OpeningSelectionScreen();

    final profileAsync = ref.watch(activeProfileProvider);
    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const OpeningSelectionScreen(),
      data: (profile) {
        if (profile != null) return const OpeningSelectionScreen();
        return WelcomeScreen(
          onGuest: () => setState(() => _guestMode = true),
        );
      },
    );
  }
}
