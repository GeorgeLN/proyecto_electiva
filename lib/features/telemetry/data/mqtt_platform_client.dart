import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_platform_client_io.dart'
    if (dart.library.html) 'mqtt_platform_client_web.dart' as impl;

/// Crea el cliente MQTT apropiado para la plataforma actual, apuntando al
/// mismo broker público (`broker.hivemq.com`) que usa el firmware del ESP32.
MqttClient createPlatformMqttClient(String broker, String clientId) {
  return impl.createPlatformMqttClient(broker, clientId);
}
