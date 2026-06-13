import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/app.dart';
import 'package:customer_app/core/config/api_host_resolver.dart';
import 'package:customer_app/core/utils/local_storage/storage_utility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App loads splash', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await ApiHostResolver.init(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const CustomerApp(),
      ),
    );
    await tester.pump();
    expect(find.text('Demo Kitchen'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
  });
}
