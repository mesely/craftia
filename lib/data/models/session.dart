import 'account.dart';

/// A signed-in person plus the token the server issued for them.
class Session {
  const Session({required this.account, required this.token});

  final Account account;
  final String token;

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    account: Account.fromJson(
      Map<String, dynamic>.from(json['account'] as Map),
    ),
    token: (json['token'] ?? '').toString(),
  );
}
