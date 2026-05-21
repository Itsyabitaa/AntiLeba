import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anti_leba/app.dart';

void main() {
  testWidgets('AntiLebaApp boots and shows the splash logo', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AntiLebaApp()),
    );

    // First frame after splash route is mounted should contain our brand icon.
    expect(find.byIcon(Icons.shield_moon_rounded), findsOneWidget);
    expect(find.text('Anti-Leba'), findsOneWidget);
  });
}
