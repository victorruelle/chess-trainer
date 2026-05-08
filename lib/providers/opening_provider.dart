import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/opening.dart';
import '../services/opening_book_service.dart';

final openingBookServiceProvider = Provider<OpeningBookService>(
  (ref) => OpeningBookService(),
);

final allOpeningsProvider = FutureProvider<List<Opening>>((ref) {
  final service = ref.watch(openingBookServiceProvider);
  return service.loadOpenings();
});

final selectedColorProvider = StateProvider<String?>((ref) => null);

final selectedOpeningProvider = StateProvider<Opening?>((ref) => null);
