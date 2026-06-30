// Smoke test барои Superior AI.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:superior/main.dart';

void main() {
  testWidgets('Superior app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const SuperiorApp());
    await tester.pump();

    // Экрани сар (splash) бояд номи бренд ё иконро нишон диҳад.
    expect(find.text('Superior AI'), findsWidgets);
  });
}
