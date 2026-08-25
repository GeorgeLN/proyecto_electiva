import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/plant_health_animation.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../home/presentation/widgets/plant_card.dart';
import '../../../plants/application/plant_providers.dart';
import '../../../plants/domain/plant.dart';
import '../../../telemetry/application/telemetry_providers.dart';

class PlantDetailScreen extends ConsumerWidget {
  const PlantDetailScreen({super.key, required this.plantId});

  final String plantId;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar planta'),
        content: const Text('Esta acción no se puede deshacer. ¿Deseas continuar?'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(plantRepositoryProvider).deletePlant(uid, plantId);
      if (context.mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantAsync = ref.watch(plantByIdProvider(plantId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de la planta'),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/plants/$plantId/edit'),
            ),
          if (user != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref, user.uid),
            ),
        ],
      ),
      body: plantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (plant) {
          if (plant == null || user == null) {
            return const Center(child: Text('Planta no encontrada'));
          }
          return _PlantDetailBody(plant: plant, uid: user.uid);
        },
      ),
    );
  }
}

class _PlantDetailBody extends ConsumerWidget {
  const _PlantDetailBody({required this.plant, required this.uid});

  final Plant plant;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = healthFor(plant.wateringProgress);
    final dateFormat = DateFormat('d MMM y, h:mm a', 'es');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Center(child: PlantHealthAnimation(health: health, size: 160)),
          const SizedBox(height: 20),
          Text(
            plant.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (plant.species.isNotEmpty)
            Text(plant.species, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.water_drop_outlined,
                    label: 'Frecuencia de riego',
                    value: plant.wateringFrequencyHours % 24 == 0
                        ? 'Cada ${plant.wateringFrequencyHours ~/ 24} día(s)'
                        : 'Cada ${plant.wateringFrequencyHours} hora(s)',
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: Icons.history,
                    label: 'Último riego',
                    value: plant.lastWateredAt != null
                        ? dateFormat.format(plant.lastWateredAt!)
                        : 'Aún sin registro',
                  ),
                  if (plant.location != null) ...[
                    const Divider(),
                    _InfoRow(icon: Icons.place_outlined, label: 'Ubicación', value: plant.location!),
                  ],
                  if (plant.deviceId != null) ...[
                    const Divider(),
                    _InfoRow(icon: Icons.developer_board_outlined, label: 'Dispositivo', value: plant.deviceId!),
                  ],
                  if (plant.soilMoisture != null) ...[
                    const Divider(),
                    _InfoRow(
                      icon: Icons.water_drop_outlined,
                      label: 'Humedad de suelo',
                      value: '${plant.soilMoisture!.round()}%',
                    ),
                  ],
                  if (plant.temperature != null) ...[
                    const Divider(),
                    _InfoRow(
                      icon: Icons.thermostat_outlined,
                      label: 'Temperatura',
                      value: '${plant.temperature!.toStringAsFixed(1)}°C',
                    ),
                  ],
                  if (plant.lastWateringMode != null) ...[
                    const Divider(),
                    _InfoRow(
                      icon: Icons.speed_outlined,
                      label: 'Último modo de riego',
                      value: plant.lastWateringMode == WateringMode.rapido ? 'Rápido' : 'Normal',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Marcar como regada ahora',
            icon: Icons.water_drop,
            onPressed: () async {
              await ref.read(plantRepositoryProvider).markWatered(uid, plant.id);
              final deviceId = plant.deviceId;
              if (deviceId != null && deviceId.isNotEmpty) {
                await publishWaterNowCommand(ref, deviceId);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
