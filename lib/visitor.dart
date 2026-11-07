class Visitor {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? lastVisited;
  final String? lastVisitType;
  final String? lastHostLabel;
  final String? lastHostType;
  final String? lastHostId;

  const Visitor({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.lastVisited,
    this.lastVisitType,
    this.lastHostLabel,
    this.lastHostType,
    this.lastHostId,
  });

  factory Visitor.fromLookupJson(Map<String, dynamic> json) {
    final guest = json['guest'] as Map<String, dynamic>? ?? const {};
    final latestVisit = json['latest_visit'] as Map<String, dynamic>?;

    return Visitor(
      id: guest['id'] as int? ?? 0,
      name: guest['full_name'] as String? ?? '',
      phone: guest['phone'] as String? ?? '',
      email: guest['email'] as String?,
      lastVisited: latestVisit?['check_in_at'] as String?,
      lastVisitType: latestVisit?['visit_type'] as String?,
      lastHostLabel: latestVisit?['host_label'] as String?,
      lastHostType: latestVisit?['host_type'] as String?,
      lastHostId: latestVisit?['host_id']?.toString(),
    );
  }
}
