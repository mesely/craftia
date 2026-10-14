import 'package:equatable/equatable.dart';

class SubType extends Equatable {
  const SubType({required this.label, required this.value});

  final String label;
  final String value;

  factory SubType.fromJson(Map<String, dynamic> json) => SubType(
    label: (json['label'] ?? '').toString(),
    value: (json['value'] ?? '').toString(),
  );

  @override
  List<Object?> get props => [label, value];
}

class ProviderCategory extends Equatable {
  const ProviderCategory({
    required this.id,
    required this.name,
    required this.shortName,
    required this.subTypes,
  });

  final String id;
  final String name;
  final String shortName;
  final List<SubType> subTypes;

  factory ProviderCategory.fromJson(Map<String, dynamic> json) =>
      ProviderCategory(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        shortName: (json['shortName'] ?? json['name'] ?? '').toString(),
        subTypes: (json['subTypes'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => SubType.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false),
      );

  @override
  List<Object?> get props => [id, name, shortName, subTypes];
}
