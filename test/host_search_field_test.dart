import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ajfrontdesk/host_search_field.dart';
import 'package:ajfrontdesk/reception_host.dart';

void main() {
  testWidgets('prefilled host stays editable when selecting a different host', (
    WidgetTester tester,
  ) async {
    ReceptionHost? selectedHost = const ReceptionHost(
      id: '1',
      hostType: 'customer',
      label: 'Nanda and Company LLC',
    );

    Future<List<ReceptionHost>> searchHosts(String query) async {
      if (query == 'Man') {
        return const [
          ReceptionHost(
            id: '2',
            hostType: 'staff',
            label: 'Manpreet Nanda',
            subtitle: 'manpreet@intlord.com',
          ),
        ];
      }
      return const [];
    }

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: HostSearchField(
                  searchHosts: searchHosts,
                  selectedHost: selectedHost,
                  onSelected: (host) {
                    setState(() {
                      selectedHost = host;
                    });
                  },
                ),
              ),
            ),
          );
        },
      ),
    );

    expect(find.text('Nanda and Company LLC'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Man');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Manpreet Nanda'), findsOneWidget);
    expect(find.text('Nanda and Company LLC'), findsNothing);

    await tester.tap(find.text('Manpreet Nanda'));
    await tester.pumpAndSettle();

    expect(find.text('Manpreet Nanda'), findsOneWidget);
  });
}
