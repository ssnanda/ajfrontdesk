class CheckInResponse {
  final bool success;
  final String? message;
  final int? visitId;
  final String? guestName;
  final String? hostLabel;

  const CheckInResponse({
    required this.success,
    this.message,
    this.visitId,
    this.guestName,
    this.hostLabel,
  });

  factory CheckInResponse.fromJson(Map<String, dynamic> json) {
    final guest = json['guest'] as Map<String, dynamic>?;
    return CheckInResponse(
      success: true,
      message: json['message'] as String?,
      visitId: json['id'] as int?,
      guestName: guest?['full_name'] as String?,
      hostLabel: json['host_label'] as String?,
    );
  }
}
