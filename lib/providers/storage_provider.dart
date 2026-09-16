import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';

/// Fournie une vraie valeur via ProviderScope.overrides dans main(), une fois
/// StorageService.init() terminé (Hive nécessite une initialisation async).
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider doit être surchargé dans main().');
});
