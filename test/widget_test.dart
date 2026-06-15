import 'package:flutter_test/flutter_test.dart';
import 'package:pak_independence_photo_frames/main.dart';

void main() {
  testWidgets('shows the Independence Day frame home screen', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('14 August Frames'), findsWidgets);
    expect(find.text('Celebrate Pakistan Independence Day'), findsOneWidget);
    expect(find.text('Choose a frame'), findsOneWidget);
  });
}
