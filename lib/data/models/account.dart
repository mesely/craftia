import 'package:equatable/equatable.dart';

enum AccountRole {
  customer('customer', 'Müşteri'),
  provider('provider', 'Usta');

  const AccountRole(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static AccountRole parse(String? raw) =>
      raw == 'provider' ? AccountRole.provider : AccountRole.customer;
}

/// The person using the app. Customers and ustas are two kinds of the same account.
class Account extends Equatable {
  const Account({
    required this.id,
    required this.role,
    required this.name,
    this.phone = '',
    this.email = '',
    this.providerId,
    this.isDemo = false,
  });

  final String id;
  final AccountRole role;
  final String name;
  final String phone;
  final String email;

  /// The `providers` listing this usta manages.
  final String? providerId;

  /// Created through the mock "admin" sign-in.
  final bool isDemo;

  bool get isProvider => role == AccountRole.provider;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  Account copyWith({String? name, String? phone, String? email}) => Account(
    id: id,
    role: role,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    providerId: providerId,
    isDemo: isDemo,
  );

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: (json['id'] ?? '').toString(),
    role: AccountRole.parse(json['role'] as String?),
    name: (json['name'] ?? '').toString(),
    phone: (json['phone'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    providerId: json['providerId'] as String?,
    isDemo: json['isDemo'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.apiValue,
    'name': name,
    'phone': phone,
    'email': email,
    'providerId': providerId,
    'isDemo': isDemo,
  };

  @override
  List<Object?> get props => [id, role, name, phone, email, providerId];
}
