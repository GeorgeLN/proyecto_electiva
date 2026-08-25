import 'package:flutter/material.dart';

import '../../../../core/widgets/plant_health_animation.dart';
import '../../../../core/widgets/primary_button.dart';

class EmptyPlantsView extends StatelessWidget {
  const EmptyPlantsView({super.key, required this.onAddPlant});

  final VoidCallback onAddPlant;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PlantHealthAnimation(size: 140),
            const SizedBox(height: 24),
            Text(
              'Todavía no tienes plantas',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra tu primera planta para empezar a monitorear su riego automático.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Agregar una nueva planta',
              icon: Icons.add,
              onPressed: onAddPlant,
            ),
          ],
        ),
      ),
    );
  }
}
