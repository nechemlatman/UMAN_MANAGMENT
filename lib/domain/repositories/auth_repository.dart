abstract interface class AuthRepository {
  String? get userId;
  Stream<String?> get identities;
  Future<void> login(String email, String password);
  Future<void> logout();
}
