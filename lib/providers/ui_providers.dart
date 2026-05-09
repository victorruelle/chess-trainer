import 'package:flutter_riverpod/flutter_riverpod.dart';

final boardFlippedProvider = StateProvider<bool>((ref) => false);
final trainingModeProvider = StateProvider<bool>((ref) => false);
final analysisPanelOpenProvider = StateProvider<bool>((ref) => false);
