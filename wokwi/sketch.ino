// Firmware de riego automático para el proyecto electiva.
// Simulado en Wokwi: ESP32 + potenciómetro (humedad de suelo) + DHT22 (temperatura)
// + LED (indicador de bomba). Se conecta por WiFi a un broker MQTT público y
// habla con la app Flutter usando los mismos topics que espera
// lib/features/telemetry/application/telemetry_providers.dart.

#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include <time.h>

// ---------- Configuración que debes ajustar ----------
// Debe coincidir EXACTO con el "ID del dispositivo ESP32" que pusiste
// al crear/editar la planta en la app.
const char *DEVICE_ID = "esp32-planta-01";

// Wokwi provee esta red WiFi abierta con salida a internet real.
const char *WIFI_SSID = "Wokwi-GUEST";
const char *WIFI_PASSWORD = "";

// Broker público, sin credenciales (el mismo que usa la app).
const char *MQTT_BROKER = "broker.hivemq.com";
const int MQTT_PORT = 1883;

// Debe coincidir con _topicPrefix en telemetry_providers.dart.
const char *TOPIC_PREFIX = "proyecto-electiva-d58bf/plants";

// Umbral de temperatura para activar el modo "rápido" (más agua).
const float HOT_THRESHOLD_C = 30.0;

// Duración de riego por modo (milisegundos, tiempo que la bomba queda activa).
const unsigned long PUMP_DURATION_NORMAL_MS = 2000;
const unsigned long PUMP_DURATION_RAPIDO_MS = 5000;

// Cada cuántos "segundos por hora simulada" cuenta el reloj de riego.
// En la vida real déjalo en 3600 (1 hora = 3600s). Para demostrar el
// proyecto en clase sin esperar horas reales, bájalo (ej. 10 => cada
// "hora" configurada en la app equivale a 10 segundos reales).
const unsigned long SIMULATED_SECONDS_PER_HOUR = 10;

// ---------- Pines ----------
const int PIN_SOIL_MOISTURE = 34; // potenciómetro (ADC)
const int PIN_DHT = 4;            // DHT22
const int PIN_PUMP = 26;          // LED que simula el relé/bomba

// ---------- Estado global ----------
WiFiClient espClient;
PubSubClient mqttClient(espClient);
DHT dht(PIN_DHT, DHT22);
Preferences preferences;

unsigned long wateringFrequencyHours = 24;
time_t lastWateredAt = 0;
unsigned long lastTelemetryPublishMs = 0;
unsigned long pumpOffAtMs = 0;
bool pumpActive = false;

String topicConfig() { return String(TOPIC_PREFIX) + "/" + DEVICE_ID + "/config"; }
String topicTelemetry() { return String(TOPIC_PREFIX) + "/" + DEVICE_ID + "/telemetry"; }
String topicCommand() { return String(TOPIC_PREFIX) + "/" + DEVICE_ID + "/command"; }

void connectWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Conectando a WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(300);
    Serial.print(".");
  }
  Serial.println(" conectado.");

  // Hora real vía NTP, necesaria para que el horario de riego sobreviva reinicios.
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  Serial.print("Sincronizando hora");
  time_t now = time(nullptr);
  while (now < 8 * 3600 * 2) {
    delay(300);
    Serial.print(".");
    now = time(nullptr);
  }
  Serial.println(" listo.");
}

float readSoilMoisturePercent() {
  int raw = analogRead(PIN_SOIL_MOISTURE); // 0-4095
  return (raw / 4095.0) * 100.0;
}

void startPump(bool rapido) {
  digitalWrite(PIN_PUMP, HIGH);
  pumpActive = true;
  pumpOffAtMs = millis() + (rapido ? PUMP_DURATION_RAPIDO_MS : PUMP_DURATION_NORMAL_MS);
  Serial.println(rapido ? "Riego iniciado (modo rapido)" : "Riego iniciado (modo normal)");
}

void updatePumpState() {
  if (pumpActive && millis() >= pumpOffAtMs) {
    digitalWrite(PIN_PUMP, LOW);
    pumpActive = false;
    Serial.println("Riego finalizado.");
  }
}

void publishTelemetry(bool wateredNow, const char *mode) {
  StaticJsonDocument<200> doc;
  doc["soilMoisture"] = readSoilMoisturePercent();
  float temperature = dht.readTemperature();
  if (!isnan(temperature)) doc["temperature"] = temperature;
  doc["wateredNow"] = wateredNow;
  if (mode != nullptr) doc["mode"] = mode;

  char payload[200];
  serializeJson(doc, payload);
  mqttClient.publish(topicTelemetry().c_str(), payload);
}

void triggerWateringCycle() {
  float temperature = dht.readTemperature();
  bool rapido = !isnan(temperature) && temperature >= HOT_THRESHOLD_C;
  startPump(rapido);

  lastWateredAt = time(nullptr);
  preferences.putULong("lastWatered", (unsigned long)lastWateredAt);

  publishTelemetry(true, rapido ? "rapido" : "normal");
}

void onMqttMessage(char *topic, byte *payload, unsigned int length) {
  String topicStr(topic);
  String message;
  for (unsigned int i = 0; i < length; i++) message += (char)payload[i];

  if (topicStr == topicConfig()) {
    StaticJsonDocument<200> doc;
    if (deserializeJson(doc, message) == DeserializationError::Ok) {
      if (doc.containsKey("wateringFrequencyHours")) {
        wateringFrequencyHours = doc["wateringFrequencyHours"].as<unsigned long>();
        preferences.putULong("freqHours", wateringFrequencyHours);
        Serial.printf("Frecuencia de riego actualizada: %lu horas\n", wateringFrequencyHours);
      }
    }
  } else if (topicStr == topicCommand()) {
    if (message == "regar_ahora") {
      Serial.println("Comando manual recibido desde la app: regar_ahora");
      triggerWateringCycle();
    }
  }
}

void connectMqtt() {
  while (!mqttClient.connected()) {
    String clientId = String("esp32-") + DEVICE_ID + "-" + String(random(0xffff), HEX);
    Serial.print("Conectando a MQTT...");
    if (mqttClient.connect(clientId.c_str())) {
      Serial.println(" conectado.");
      mqttClient.subscribe(topicConfig().c_str());
      mqttClient.subscribe(topicCommand().c_str());
    } else {
      Serial.printf(" fallo (rc=%d), reintentando en 2s\n", mqttClient.state());
      delay(2000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(PIN_PUMP, OUTPUT);
  digitalWrite(PIN_PUMP, LOW);
  dht.begin();

  preferences.begin("riego", false);
  wateringFrequencyHours = preferences.getULong("freqHours", 24);
  lastWateredAt = (time_t)preferences.getULong("lastWatered", 0);

  connectWiFi();

  mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
  mqttClient.setCallback(onMqttMessage);
  connectMqtt();
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }
  if (!mqttClient.connected()) {
    connectMqtt();
  }
  mqttClient.loop();
  updatePumpState();

  // Riego automático por horario: horas configuradas -> segundos simulados.
  time_t now = time(nullptr);
  unsigned long elapsedSeconds = (unsigned long)difftime(now, lastWateredAt);
  unsigned long dueSeconds = wateringFrequencyHours * SIMULATED_SECONDS_PER_HOUR;
  if (lastWateredAt == 0 || elapsedSeconds >= dueSeconds) {
    triggerWateringCycle();
  }

  // Telemetría periódica (humedad/temperatura) para que la app siempre
  // tenga una lectura reciente, incluso sin ciclo de riego.
  if (millis() - lastTelemetryPublishMs >= 5000) {
    lastTelemetryPublishMs = millis();
    publishTelemetry(false, nullptr);
  }
}
