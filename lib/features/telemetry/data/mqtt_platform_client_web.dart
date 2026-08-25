import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

/// Cliente MQTT para Flutter Web: los navegadores no permiten sockets TCP
/// crudos, así que se usa el listener WebSocket que expone el mismo broker.
MqttClient createPlatformMqttClient(String broker, String clientId) {
  return MqttBrowserClient('ws://$broker:8000/mqtt', clientId)
    ..keepAlivePeriod = 30
    ..autoReconnect = true
    ..logging(on: false);
}
