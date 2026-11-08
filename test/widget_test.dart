import 'package:ajfrontdesk/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ajfrontdesk/app_config.dart';

void main() {
  testWidgets('an unconfigured iPad shows setup', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppConfig.load();
    await tester.pumpWidget(const ReceptionApp());
    expect(find.text('AJ Front Desk'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });

  testWidgets('a configured iPad shows the check-in options', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'site_url': 'https://example.com/wp-json/ajcore/v1', 'device_key': 'k', 'pin': '1234', 'site_name': 'Example'});
    await AppConfig.load();
    await tester.pumpWidget(const ReceptionApp());
    expect(find.textContaining('Welcome'), findsNothing); // just the buttons
    expect(find.text('Appointment'), findsOneWidget);
    expect(find.text('Walk-In'), findsOneWidget);
    expect(find.text('Returning Visitor'), findsOneWidget);
  });
}
