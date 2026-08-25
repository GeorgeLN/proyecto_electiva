import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../plants/application/plant_providers.dart';
import '../../../telemetry/application/telemetry_providers.dart';
import '../widgets/empty_plants_view.dart';
import '../widgets/plant_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsStreamProvider);
    // Mantiene la conexión MQTT viva mientras el usuario navega la app.
    ref.watch(telemetryBootstrapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis plantas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: plantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('No se pudieron cargar tus plantas.\n$error', textAlign: TextAlign.center),
        ),
        data: (plants) {
          if (plants.isEmpty) {
            return EmptyPlantsView(onAddPlant: () => context.push('/plants/add'));
          }
          return RefreshIndicator(
            onRefresh: () async {},
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.78,
              ),
              itemCount: plants.length,
              itemBuilder: (context, index) {
                final plant = plants[index];
                return PlantCard(
                  plant: plant,
                  onTap: () => context.push('/plants/${plant.id}'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: plantsAsync.maybeWhen(
        data: (plants) => plants.isEmpty
            ? null
            : FloatingActionButton(
                onPressed: () => context.push('/plants/add'),
                child: const Icon(Icons.add),
              ),
        orElse: () => null,
      ),
    );
  }
}
