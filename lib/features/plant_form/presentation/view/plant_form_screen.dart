import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../plants/application/plant_providers.dart';
import '../../../plants/domain/plant.dart';
import '../viewmodel/plant_form_viewmodel.dart';

enum _FrequencyUnit { hours, days }

/// Formulario para crear una planta nueva o editar una existente.
/// Si [plantId] es null, crea; si viene con valor, precarga y actualiza.
class PlantFormScreen extends ConsumerStatefulWidget {
  const PlantFormScreen({super.key, this.plantId});

  final String? plantId;

  @override
  ConsumerState<PlantFormScreen> createState() => _PlantFormScreenState();
}

class _PlantFormScreenState extends ConsumerState<PlantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _frequencyController = TextEditingController(text: '24');
  final _locationController = TextEditingController();
  final _deviceIdController = TextEditingController();
  _FrequencyUnit _unit = _FrequencyUnit.hours;
  bool _prefilled = false;
  DateTime? _createdAt;
  DateTime? _lastWateredAt;

  bool get _isEditing => widget.plantId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _frequencyController.dispose();
    _locationController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  void _prefillFrom(Plant plant) {
    _nameController.text = plant.name;
    _speciesController.text = plant.species;
    _locationController.text = plant.location ?? '';
    _deviceIdController.text = plant.deviceId ?? '';
    _createdAt = plant.createdAt;
    _lastWateredAt = plant.lastWateredAt;
    final hours = plant.wateringFrequencyHours;
    if (hours % 24 == 0 && hours != 0) {
      _unit = _FrequencyUnit.days;
      _frequencyController.text = (hours ~/ 24).toString();
    } else {
      _unit = _FrequencyUnit.hours;
      _frequencyController.text = hours.toString();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final value = int.parse(_frequencyController.text.trim());
    final hours = _unit == _FrequencyUnit.days ? value * 24 : value;

    final success = await ref.read(plantFormViewModelProvider.notifier).save(
          existingId: widget.plantId,
          name: _nameController.text,
          species: _speciesController.text,
          wateringFrequencyHours: hours,
          location: _locationController.text,
          deviceId: _deviceIdController.text,
          createdAt: _createdAt,
          lastWateredAt: _lastWateredAt,
        );
    if (success && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(plantFormViewModelProvider);

    ref.listen(plantFormViewModelProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: ${next.error}')),
        );
      }
    });

    if (_isEditing && !_prefilled) {
      final plantAsync = ref.watch(plantByIdProvider(widget.plantId!));
      return plantAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Error: $error')),
        ),
        data: (plant) {
          if (plant == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Planta no encontrada')),
            );
          }
          _prefillFrom(plant);
          _prefilled = true;
          return _buildForm(context, formState);
        },
      );
    }

    return _buildForm(context, formState);
  }

  Widget _buildForm(BuildContext context, AsyncValue<void> formState) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar planta' : 'Nueva planta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Nombre de la planta',
                  controller: _nameController,
                  prefixIcon: Icons.local_florist_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.notEmpty(v, message: 'Ponle un nombre a tu planta'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Especie (opcional)',
                  controller: _speciesController,
                  prefixIcon: Icons.eco_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                Text('Frecuencia de riego', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Cada cuánto',
                        controller: _frequencyController,
                        keyboardType: TextInputType.number,
                        validator: Validators.positiveNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<_FrequencyUnit>(
                        initialValue: _unit,
                        decoration: const InputDecoration(labelText: 'Unidad'),
                        items: const [
                          DropdownMenuItem(value: _FrequencyUnit.hours, child: Text('Horas')),
                          DropdownMenuItem(value: _FrequencyUnit.days, child: Text('Días')),
                        ],
                        onChanged: (value) => setState(() => _unit = value ?? _FrequencyUnit.hours),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Ubicación (opcional)',
                  controller: _locationController,
                  prefixIcon: Icons.place_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'ID del dispositivo ESP32 (opcional)',
                  controller: _deviceIdController,
                  prefixIcon: Icons.developer_board_outlined,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: _isEditing ? 'Guardar cambios' : 'Guardar planta',
                  isLoading: formState.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
