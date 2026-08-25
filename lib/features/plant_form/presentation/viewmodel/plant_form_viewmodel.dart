import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_providers.dart';
import '../../../plants/application/plant_providers.dart';
import '../../../plants/domain/plant.dart';

class PlantFormViewModel extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> save({
    String? existingId,
    required String name,
    required String species,
    required int wateringFrequencyHours,
    String? location,
    String? deviceId,
    DateTime? createdAt,
    DateTime? lastWateredAt,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = AsyncError('No hay sesión activa', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final repository = ref.read(plantRepositoryProvider);
    state = await AsyncValue.guard(() async {
      final plant = Plant(
        id: existingId ?? '',
        name: name.trim(),
        species: species.trim(),
        wateringFrequencyHours: wateringFrequencyHours,
        createdAt: createdAt ?? DateTime.now(),
        location: (location == null || location.trim().isEmpty) ? null : location.trim(),
        deviceId: (deviceId == null || deviceId.trim().isEmpty) ? null : deviceId.trim(),
        lastWateredAt: lastWateredAt,
      );
      if (existingId == null) {
        await repository.addPlant(user.uid, plant);
      } else {
        await repository.updatePlant(user.uid, plant);
      }
    });
    return !state.hasError;
  }
}

final plantFormViewModelProvider = AsyncNotifierProvider<PlantFormViewModel, void>(
  PlantFormViewModel.new,
);
