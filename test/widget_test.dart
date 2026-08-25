import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_electiva/core/widgets/plant_health_animation.dart';

void main() {
  testWidgets('PlantHealthAnimation renders without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: PlantHealthAnimation()),
        ),
      ),
    );

    expect(find.byType(PlantHealthAnimation), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
