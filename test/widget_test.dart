import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pak_independence_photo_frames/features/home/home_screen.dart';

void main() {
  testWidgets('shows the Independence Day frame home screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Photo Frames'), findsOneWidget);
    expect(find.text('Explore Categories'), findsOneWidget);
    expect(find.text('Frames'), findsOneWidget);
  });
}
