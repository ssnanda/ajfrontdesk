class CheckInRequest {
  final String visitType;
  final String fullName;
  final String phone;
  final String hostType;
  final String hostId;
  final String? email;
  final String? notes;

  const CheckInRequest({
    required this.visitType,
    required this.fullName,
    required this.phone,
    required this.hostType,
    required this.hostId,
    this.email,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'visit_type': visitType,
    'full_name': fullName,
    'phone': phone,
    'host_type': hostType,
    'host_id': hostId,
    'email': email,
    'notes': notes,
  };
}
