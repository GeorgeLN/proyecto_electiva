import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Cliente MQTT para plataformas nativas (Windows, Android, iOS, macOS, Linux):
/// se conecta por TCP plano al broker público, mismo puerto que usa el firmware.
MqttClient createPlatformMqttClient(String broker, String clientId) {
  return MqttServerClient.withPort(broker, clientId, 1883)
    ..keepAlivePeriod = 30
    ..autoReconnect = true
    ..logging(on: false);
}
