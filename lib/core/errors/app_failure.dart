enum FailureKind { network, timeout, server, notFound, invalid, unknown }

/// A user-presentable failure. [message] is always human Turkish, never a raw error.
class AppFailure implements Exception {
  const AppFailure(this.kind, this.message);

  final FailureKind kind;
  final String message;

  static const network = AppFailure(
    FailureKind.network,
    'İnternet bağlantına ulaşamadık. Bağlantını kontrol edip tekrar dene.',
  );
  static const timeout = AppFailure(
    FailureKind.timeout,
    'Sunucu geç yanıt veriyor. Birazdan tekrar dene.',
  );
  static const server = AppFailure(
    FailureKind.server,
    'Şu anda bir sorun yaşıyoruz. Biraz sonra tekrar dene.',
  );
  static const notFound = AppFailure(
    FailureKind.notFound,
    'Aradığın içeriği bulamadık.',
  );
  static const unknown = AppFailure(
    FailureKind.unknown,
    'Beklenmedik bir sorun oluştu. Tekrar dene.',
  );

  /// Maps any thrown object to something safe to show.
  static AppFailure from(Object error) => error is AppFailure ? error : unknown;

  @override
  String toString() => 'AppFailure($kind)';
}

/// Runs a repository call and turns anything that goes wrong into a user-presentable [AppFailure].
Future<T> guarded<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AppFailure {
    rethrow;
  } catch (_) {
    throw AppFailure.unknown;
  }
}
