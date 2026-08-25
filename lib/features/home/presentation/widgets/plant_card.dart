import 'package:flutter/material.dart';

import '../../../../core/widgets/plant_health_animation.dart';
import '../../../plants/domain/plant.dart';

PlantHealth healthFor(double wateringProgress) {
  if (wateringProgress >= 1) return PlantHealth.critical;
  if (wateringProgress >= 0.7) return PlantHealth.thirsty;
  return PlantHealth.healthy;
}

class PlantCard extends StatelessWidget {
  const PlantCard({super.key, required this.plant, required this.onTap});

  final Plant plant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final health = healthFor(plant.wateringProgress);
    final statusText = switch (health) {
      PlantHealth.healthy => 'Hidratada',
      PlantHealth.thirsty => 'Pronto necesita agua',
      PlantHealth.critical => 'Necesita agua ya',
    };
    final statusColor = switch (health) {
      PlantHealth.healthy => const Color(0xFF2E7D5B),
      PlantHealth.thirsty => const Color(0xFF9A8A2E),
      PlantHealth.critical => const Color(0xFFB0512E),
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: PlantHealthAnimation(health: health, size: 76),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plant.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (plant.species.isNotEmpty)
                Text(
                  plant.species,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.water_drop, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
