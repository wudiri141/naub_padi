import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:naubpadi/main.dart';

void main() {
  testWidgets('launches the Padi home shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const NaubPadiApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to NAUB Padi'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Browse'), findsWidgets);
  });
}
