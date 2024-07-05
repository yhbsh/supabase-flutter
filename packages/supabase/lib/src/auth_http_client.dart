import 'package:http/http.dart';
import 'package:supabase/supabase.dart';

class AuthHttpClient extends BaseClient {
  final Client _inner;
  final GoTrueClient _auth;
  final String _supabaseKey;

  AuthHttpClient(this._supabaseKey, this._inner, this._auth);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    if (_auth.currentSession?.isExpired ?? false) {
      try {
        await _auth.refreshSession();
      } catch (error) {
        // Failed to refresh the token.
        final isExpiredWithoutMargin = DateTime.now().isAfter(DateTime.fromMillisecondsSinceEpoch(_auth.currentSession!.expiresAt! * 1000));
        if (isExpiredWithoutMargin) {
          // Throw the error instead of making an API request with an expired token.
          rethrow;
        }
      }
    }
    final authBearer = _auth.currentSession?.accessToken ?? _supabaseKey;

    request.headers.putIfAbsent("Authorization", () => 'Bearer $authBearer');
    request.headers.putIfAbsent("apikey", () => _supabaseKey);
    return _inner.send(request);
  }
}
