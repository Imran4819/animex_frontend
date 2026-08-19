import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:animex_billing/main.dart';

void main() {
  testWidgets('renders the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AnimexApp()));
    await tester.pump();
    expect(find.text('ANIMEX Billing'), findsOneWidget);
  });
}
