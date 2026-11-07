class ReceptionHost {
  final String id; // staff user id or customer id
  final String hostType; // 'staff' or 'customer'
  final String label;
  final String? subtitle;

  const ReceptionHost({
    required this.id,
    required this.hostType,
    required this.label,
    this.subtitle,
  });

  bool get isPerson => hostType == 'staff';

  factory ReceptionHost.fromJson(Map<String, dynamic> json) {
    return ReceptionHost(
      id: (json['id'] ?? '').toString(),
      hostType: (json['host_type'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      subtitle: json['subtitle'] as String?,
    );
  }
}
