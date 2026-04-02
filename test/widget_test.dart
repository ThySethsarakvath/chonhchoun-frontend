import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';
import 'package:frontend/screens/driver/driver_workspace_screen.dart'
    show DriverWorkspaceScreen;

void main() {
  testWidgets('app boots into the driver workspace', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(DriverWorkspaceScreen), findsOneWidget);
    expect(find.text('Available Requests'), findsOneWidget);
  });
}
