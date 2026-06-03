import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalis_mobile/main.dart';

void main() {
  testWidgets('renders Vitalis auth screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const VitalisApp());
    await tester.pump();
    await tester.pump();

    expect(find.text('Vitalis'), findsOneWidget);
    expect(find.text('Entrar'), findsWidgets);
  });
}
