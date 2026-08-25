import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/plant.dart';

/// Acceso a la colección de plantas de un usuario en Cloud Firestore.
/// Estructura: users/{uid}/plants/{plantId}
class PlantRepository {
  PlantRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _plantsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('plants');
  }

  Stream<List<Plant>> watchPlants(String uid) {
    return _plantsRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Plant.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<Plant?> watchPlant(String uid, String plantId) {
    return _plantsRef(uid).doc(plantId).snapshots().map(
          (doc) => doc.exists ? Plant.fromMap(doc.id, doc.data()!) : null,
        );
  }

  Future<String> addPlant(String uid, Plant plant) async {
    final doc = await _plantsRef(uid).add(plant.toMap());
    return doc.id;
  }

  Future<void> updatePlant(String uid, Plant plant) {
    return _plantsRef(uid).doc(plant.id).update(plant.toMap());
  }

  Future<void> deletePlant(String uid, String plantId) {
    return _plantsRef(uid).doc(plantId).delete();
  }

  Future<void> markWatered(String uid, String plantId) {
    return _plantsRef(uid).doc(plantId).update({
      'lastWateredAt': Timestamp.now(),
    });
  }

  /// Aplica la telemetría reportada por el dispositivo (ESP32/Wokwi) vía MQTT.
  /// [wateredNow] se marca en true cuando el mensaje indica que el dispositivo
  /// completó un ciclo de riego automático en ese instante.
  Future<void> applyTelemetry(
    String uid,
    String plantId, {
    double? soilMoisture,
    double? temperature,
    String? wateringMode,
    bool wateredNow = false,
  }) {
    final data = <String, dynamic>{
      'lastReadingAt': Timestamp.now(),
      'soilMoisture': ?soilMoisture,
      'temperature': ?temperature,
    };
    if (wateredNow) {
      data['lastWateredAt'] = Timestamp.now();
      if (wateringMode != null) data['lastWateringMode'] = wateringMode;
    }
    return _plantsRef(uid).doc(plantId).update(data);
  }
}
