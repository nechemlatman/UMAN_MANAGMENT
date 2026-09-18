class CloudConfig {
  const CloudConfig(this.url, this.key);
  final String url, key;
  factory CloudConfig.environment() => const CloudConfig(
    String.fromEnvironment('SUPABASE_URL'),
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );
  bool get isValid {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        key.startsWith('sb_publishable_') &&
        !key.contains('REPLACE_ME');
  }
}
