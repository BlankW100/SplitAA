import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:splitaa/main.dart';
import 'package:splitaa/features/checklist/providers/checklist_provider.dart';
import 'package:splitaa/features/calculator/providers/calculator_provider.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ChecklistProvider()),
          ChangeNotifierProvider(create: (_) => CalculatorProvider()),
        ],
        child: const SplitaaApp(),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
