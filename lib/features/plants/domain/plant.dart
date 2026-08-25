import 'package:cloud_firestore/cloud_firestore.dart';

/// Modo con el que se ejecutó el último ciclo de riego automático.
enum WateringMode {
  normal,
  rapido;

  static WateringMode? fromName(String? name) {
    switch (name) {
      case 'normal':
        return WateringMode.normal;
      case 'rapido':
        return WateringMode.rapido;
      default:
        return null;
    }
  }
}

/// Modelo de una planta registrada por el usuario.
class Plant {
  const Plant({
    required this.id,
    required this.name,
    required this.species,
    required this.wateringFrequencyHours,
    required this.createdAt,
    this.photoUrl,
    this.location,
    this.deviceId,
    this.lastWateredAt,
    this.soilMoisture,
    this.temperature,
    this.lastReadingAt,
    this.lastWateringMode,
  });

  final String id;
  final String name;
  final String species;
  final int wateringFrequencyHours;
  final DateTime createdAt;
  final String? photoUrl;
  final String? location;
  final String? deviceId;
  final DateTime? lastWateredAt;

  /// Última lectura de humedad de suelo reportada por el dispositivo (0-100%).
  final double? soilMoisture;

  /// Última lectura de temperatura reportada por el dispositivo (°C).
  final double? temperature;

  /// Momento en que se recibió la última telemetría del dispositivo.
  final DateTime? lastReadingAt;

  /// Modo usado en el último ciclo de riego automático.
  final WateringMode? lastWateringMode;

  Duration get timeSinceLastWatered {
    final reference = lastWateredAt ?? createdAt;
    return DateTime.now().difference(reference);
  }

  /// Fracción de tiempo transcurrido respecto a la frecuencia de riego
  /// configurada (0 = recién regada, >= 1 = ya debería haberse regado).
  double get wateringProgress {
    final totalHours = wateringFrequencyHours <= 0 ? 1 : wateringFrequencyHours;
    return timeSinceLastWatered.inMinutes / (totalHours * 60);
  }

  Plant copyWith({
    String? id,
    String? name,
    String? species,
    int? wateringFrequencyHours,
    DateTime? createdAt,
    String? photoUrl,
    String? location,
    String? deviceId,
    DateTime? lastWateredAt,
    double? soilMoisture,
    double? temperature,
    DateTime? lastReadingAt,
    WateringMode? lastWateringMode,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      wateringFrequencyHours: wateringFrequencyHours ?? this.wateringFrequencyHours,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      deviceId: deviceId ?? this.deviceId,
      lastWateredAt: lastWateredAt ?? this.lastWateredAt,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      temperature: temperature ?? this.temperature,
      lastReadingAt: lastReadingAt ?? this.lastReadingAt,
      lastWateringMode: lastWateringMode ?? this.lastWateringMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'species': species,
      'wateringFrequencyHours': wateringFrequencyHours,
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': photoUrl,
      'location': location,
      'deviceId': deviceId,
      'lastWateredAt': lastWateredAt != null ? Timestamp.fromDate(lastWateredAt!) : null,
      'soilMoisture': soilMoisture,
      'temperature': temperature,
      'lastReadingAt': lastReadingAt != null ? Timestamp.fromDate(lastReadingAt!) : null,
      'lastWateringMode': lastWateringMode?.name,
    };
  }

  factory Plant.fromMap(String id, Map<String, dynamic> map) {
    return Plant(
      id: id,
      name: (map['name'] as String?) ?? '',
      species: (map['species'] as String?) ?? '',
      wateringFrequencyHours: (map['wateringFrequencyHours'] as num?)?.toInt() ?? 24,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: map['photoUrl'] as String?,
      location: map['location'] as String?,
      deviceId: map['deviceId'] as String?,
      lastWateredAt: (map['lastWateredAt'] as Timestamp?)?.toDate(),
      soilMoisture: (map['soilMoisture'] as num?)?.toDouble(),
      temperature: (map['temperature'] as num?)?.toDouble(),
      lastReadingAt: (map['lastReadingAt'] as Timestamp?)?.toDate(),
      lastWateringMode: WateringMode.fromName(map['lastWateringMode'] as String?),
    );
  }
}
