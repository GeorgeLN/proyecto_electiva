import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../plants/application/plant_providers.dart';
import '../../plants/domain/plant.dart';
import '../data/mqtt_service.dart';

/// Prefijo de namespace para evitar choques con otros proyectos que también
/// usan el broker público de HiveMQ con topics genéricos.
const String _topicPrefix = 'proyecto-electiva-d58bf/plants';

String configTopic(String deviceId) => '$_topicPrefix/$deviceId/config';
String telemetryTopic(String deviceId) => '$_topicPrefix/$deviceId/telemetry';
String commandTopic(String deviceId) => '$_topicPrefix/$deviceId/command';
const String telemetryWildcard = '$_topicPrefix/+/telemetry';

final mqttServiceProvider = Provider<MqttService>((ref) {
  final service = MqttService();
  ref.onDispose(service.dispose);
  return service;
});

/// Mantiene viva la conexión MQTT mientras hay un usuario autenticado:
/// publica (retained) la configuración de riego por dispositivo y aplica
/// la telemetría entrante del ESP32/Wokwi directamente en Firestore.
final telemetryBootstrapProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  final mqtt = ref.watch(mqttServiceProvider);
  final repository = ref.watch(plantRepositoryProvider);

  var devicePlants = <String, Plant>{};

  Future<void> handleMessage(MqttInboundMessage message) async {
    final parts = message.topic.split('/');
    if (parts.length < 4) return;
    final deviceId = parts[2];
    final plant = devicePlants[deviceId];
    if (plant == null) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(message.payload) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    await repository.applyTelemetry(
      user.uid,
      plant.id,
      soilMoisture: (data['soilMoisture'] as num?)?.toDouble(),
      temperature: (data['temperature'] as num?)?.toDouble(),
      wateringMode: data['mode'] as String?,
      wateredNow: data['wateredNow'] == true,
    );
  }

  mqtt.subscribe(telemetryWildcard);
  final subscription = mqtt.messages.listen(handleMessage);
  ref.onDispose(subscription.cancel);

  ref.listen<AsyncValue<List<Plant>>>(plantsStreamProvider, (previous, next) {
    final plants = next.value ?? const <Plant>[];
    devicePlants = {
      for (final plant in plants)
        if (plant.deviceId != null && plant.deviceId!.isNotEmpty) plant.deviceId!: plant,
    };
    for (final plant in plants) {
      final deviceId = plant.deviceId;
      if (deviceId == null || deviceId.isEmpty) continue;
      mqtt.publish(
        configTopic(deviceId),
        jsonEncode({'wateringFrequencyHours': plant.wateringFrequencyHours}),
        retain: true,
      );
    }
  }, fireImmediately: true);
});

/// Publica un comando de riego inmediato hacia el dispositivo de la planta.
Future<void> publishWaterNowCommand(WidgetRef ref, String deviceId) {
  final mqtt = ref.read(mqttServiceProvider);
  return mqtt.publish(commandTopic(deviceId), 'regar_ahora');
}
