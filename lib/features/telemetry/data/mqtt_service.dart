import 'dart:async';
import 'dart:math';

import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_platform_client.dart';

/// Broker público y gratuito usado tanto por la app como por el firmware
/// del ESP32 simulado en Wokwi. No requiere credenciales ni backend propio.
const String mqttBroker = 'broker.hivemq.com';

/// Mensaje MQTT ya decodificado: topic + payload de texto (JSON).
class MqttInboundMessage {
  const MqttInboundMessage(this.topic, this.payload);
  final String topic;
  final String payload;
}

/// Envuelve la conexión MQTT (multiplataforma) usada para hablar con los
/// dispositivos de riego. Un solo cliente por sesión de la app.
class MqttService {
  MqttService() : _client = createPlatformMqttClient(mqttBroker, _randomClientId());

  final MqttClient _client;
  final _messagesController = StreamController<MqttInboundMessage>.broadcast();
  bool _connecting = false;

  Stream<MqttInboundMessage> get messages => _messagesController.stream;
  bool get isConnected => _client.connectionStatus?.state == MqttConnectionState.connected;

  static String _randomClientId() {
    final rand = Random();
    return 'plantcare_${rand.nextInt(999999)}';
  }

  Future<void> ensureConnected() async {
    if (isConnected || _connecting) return;
    _connecting = true;
    try {
      _client.onDisconnected = () {};
      _client.updates?.listen((events) {
        for (final event in events) {
          final publishMessage = event.payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(publishMessage.payload.message);
          _messagesController.add(MqttInboundMessage(event.topic, payload));
        }
      });
      await _client.connect();
    } catch (_) {
      _client.disconnect();
    } finally {
      _connecting = false;
    }
  }

  Future<void> subscribe(String topic) async {
    await ensureConnected();
    if (!isConnected) return;
    _client.subscribe(topic, MqttQos.atLeastOnce);
  }

  Future<void> publish(String topic, String payload, {bool retain = false}) async {
    await ensureConnected();
    if (!isConnected) return;
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!, retain: retain);
  }

  void dispose() {
    _client.disconnect();
    _messagesController.close();
  }
}
