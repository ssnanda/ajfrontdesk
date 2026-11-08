import 'package:ajfrontdesk/app_config.dart';
import 'package:ajfrontdesk/checkin_request.dart';
import 'package:ajfrontdesk/reception_host.dart';
import 'package:ajfrontdesk/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeSiteUrl accepts a bare host', () {
    expect(AppConfig.normalizeSiteUrl('wozig.com'), 'https://wozig.com/wp-json/ajcore/v1');
    expect(AppConfig.normalizeSiteUrl('https://wozig.com/'), 'https://wozig.com/wp-json/ajcore/v1');
  });

  test('ReceptionHost reads staff and customer hosts', () {
    final staff = ReceptionHost.fromJson({'id': 12, 'host_type': 'staff', 'label': 'Sam'});
    final customer = ReceptionHost.fromJson({'id': 'local_ab', 'host_type': 'customer', 'label': 'Acme', 'subtitle': 'PMB 12'});
    expect(staff.isPerson, isTrue);
    expect(staff.id, '12');
    expect(customer.isPerson, isFalse);
    expect(customer.subtitle, isNull); // names only
  });

  test('CheckInRequest sends the host type and id', () {
    const req = CheckInRequest(visitType: 'walk_in', fullName: 'A B', phone: '7045550100', hostType: 'customer', hostId: 'local_ab');
    expect(req.toJson()['host_type'], 'customer');
    expect(req.toJson()['host_id'], 'local_ab');
  });

  test('Visitor lookup keeps the last host', () {
    final v = Visitor.fromLookupJson({
      'found': true,
      'guest': {'id': 1, 'full_name': 'A B', 'phone': '7045550100'},
      'latest_visit': {'host_type': 'staff', 'host_id': 5, 'host_label': 'Sam', 'check_in_at': '2026-11-01 10:00:00', 'visit_type': 'walk_in'},
    });
    expect(v.lastHostType, 'staff');
    expect(v.lastHostId, '5');
  });
}
