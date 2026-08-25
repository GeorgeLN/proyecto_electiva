import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/plant_repository.dart';
import '../domain/plant.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  return PlantRepository(ref.watch(firestoreProvider));
});

/// Lista en vivo de las plantas del usuario autenticado.
/// Si no hay usuario, expone una lista vacía en lugar de fallar.
final plantsStreamProvider = StreamProvider<List<Plant>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(plantRepositoryProvider).watchPlants(user.uid);
});

final plantByIdProvider = StreamProvider.family<Plant?, String>((ref, plantId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(plantRepositoryProvider).watchPlant(user.uid, plantId);
});
