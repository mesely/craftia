import '../../core/errors/app_failure.dart';
import '../datasources/remote_data_source.dart';
import '../models/account.dart';

/// Profile + KVKK rights. Passwords never leave the phone in the current (mock sign-in) stage.
class AccountsRepository {
  AccountsRepository(this._remote);

  final RemoteDataSource _remote;

  Future<void> upsert(Account account) => guarded(
    () => _remote.upsertAccount({
      'id': account.id,
      'role': account.role.apiValue,
      'name': account.name,
      if (account.phone.isNotEmpty) 'phone': account.phone,
      if (account.email.isNotEmpty) 'email': account.email,
      if (account.providerId != null) 'providerId': account.providerId,
    }),
  );

  /// Everything stored about the person, as JSON-encodable data.
  Future<Map<String, dynamic>> exportData(String accountId) =>
      guarded(() => _remote.exportData(accountId));

  Future<void> deleteAccount(String accountId) =>
      guarded(() => _remote.deleteAccount(accountId));
}
