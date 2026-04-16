import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:offlimu/app/app.dart';

void main() {
  testWidgets('App shell renders node status screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: OfflimuApp()));
    await tester.pump();

    expect(find.text('OffLiMU Node Status'), findsOneWidget);
  });
}
