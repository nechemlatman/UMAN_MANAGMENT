import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'application/event_controller.dart';
import 'infrastructure/cloud/cloud_config.dart';
import 'infrastructure/cloud/secure_cloud_storage.dart';
import 'infrastructure/cloud/supabase_repositories.dart';
import 'infrastructure/cloud/supabase_people_repository.dart';
import 'presentation/cloud_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = CloudConfig.environment();
  if (!config.isValid) {
    runApp(
      const CloudApp(
        setupMessage:
            'Cloud setup required. Provide the project HTTPS URL and publishable key.',
      ),
    );
    return;
  }
  try {
    final project = Uri.parse(config.url).host;
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.key,
      debug: false,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(project),
        detectSessionInUri: false,
      ),
    );
    final client = Supabase.instance.client;
    runApp(
      CloudApp(
        auth: SupabaseAuthRepository(client),
        peopleFactory: (eventId) =>
            SupabasePeopleRepository(SupabasePeopleDataSource(client, eventId)),
        createController: (userId) => EventController(
          SupabaseEventRepository(client),
          SecureEventCache(project, userId),
        ),
      ),
    );
  } catch (_) {
    runApp(
      const CloudApp(
        setupMessage:
            'Unable to open secure storage or restore your session. Restart the app to try again.',
      ),
    );
  }
}
