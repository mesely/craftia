import 'package:equatable/equatable.dart';

enum RequestStatus {
  pending('Beklemede'),
  accepted('Kabul edildi'),
  completed('Tamamlandı'),
  cancelled('İptal edildi');

  const RequestStatus(this.label);
  final String label;

  static RequestStatus parse(String? raw) => switch (raw) {
    'ACCEPTED' => accepted,
    'COMPLETED' => completed,
    'CANCELLED' => cancelled,
    _ => pending,
  };
}

class ServiceRequest extends Equatable {
  const ServiceRequest({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.mainType,
    required this.subType,
    required this.city,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String? providerId;
  final String? providerName;
  final String mainType;
  final String subType;
  final String city;
  final String description;
  final RequestStatus status;
  final DateTime createdAt;

  factory ServiceRequest.fromJson(Map<String, dynamic> json) => ServiceRequest(
    id: (json['id'] ?? '').toString(),
    providerId: json['providerId'] as String?,
    providerName: json['providerName'] as String?,
    mainType: (json['mainType'] ?? '').toString(),
    subType: (json['subType'] ?? '').toString(),
    city: (json['city'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    status: RequestStatus.parse(json['status'] as String?),
    createdAt:
        DateTime.tryParse((json['createdAt'] ?? '').toString())?.toLocal() ??
        DateTime.now(),
  );

  @override
  List<Object?> get props => [id, status];
}
