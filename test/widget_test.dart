import 'package:flutter_test/flutter_test.dart';
import 'package:govassist_ai_fresh/main.dart';

void main() {
  testWidgets('GovAssist AI landing page loads', (WidgetTester tester) async {
    await tester.pumpWidget(const GovAssistApp());
    expect(find.textContaining('GovAssist AI'), findsWidgets);
    expect(find.textContaining('Citizen'), findsWidgets);
  });
}
