/// The ways to sign in through Firebase. Apple and SMS code exist on the server but are not offered
/// in the app. (Legacy password sign-in against the app's own database still works without Firebase.)
enum SignInMethod {
  google('google', 'Google ile devam et'),
  email('email', 'E-posta ve şifre');

  const SignInMethod(this.apiKey, this.label);
  final String apiKey;
  final String label;
}

class AuthMethods {
  const AuthMethods({this.enabled = const {}});

  /// Everything off: the safe answer when the server cannot be asked.
  static const none = AuthMethods();

  final Set<SignInMethod> enabled;

  bool allows(SignInMethod m) => enabled.contains(m);

  factory AuthMethods.fromJson(Map<String, dynamic> json) => AuthMethods(
    enabled: {
      for (final m in SignInMethod.values)
        if (json[m.apiKey] == true) m,
    },
  );
}

/// What the server answers to a federated sign-in: a session, or "tell us who you are first".
class FederatedOutcome {
  const FederatedOutcome.session(this.session) : suggested = null;
  const FederatedOutcome.needsProfile(this.suggested) : session = null;

  final dynamic session;
  final Map<String, String>? suggested;
  bool get needsProfile => session == null;
}
