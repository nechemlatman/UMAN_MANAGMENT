import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/event_controller.dart';
import '../domain/entities/event.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/event_repository.dart';
import '../domain/value_objects/uuid_v4.dart';

typedef ControllerFactory = EventController Function(String userId);

class CloudApp extends StatelessWidget {
  const CloudApp({
    super.key,
    this.auth,
    this.createController,
    this.setupMessage,
  });
  final AuthRepository? auth;
  final ControllerFactory? createController;
  final String? setupMessage;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Uman Event Manager',
    home: auth == null
        ? Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(setupMessage ?? 'Cloud configuration required.'),
                ),
              ),
            ),
          )
        : _SessionGate(auth: auth!, factory: createController!),
  );
}

class _SessionGate extends StatefulWidget {
  const _SessionGate({required this.auth, required this.factory});
  final AuthRepository auth;
  final ControllerFactory factory;
  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  late final identities = widget.auth.identities;
  @override
  Widget build(BuildContext context) => StreamBuilder<String?>(
    stream: identities,
    initialData: widget.auth.userId,
    builder: (context, snapshot) => snapshot.data == null
        ? _Login(auth: widget.auth)
        : _Events(
            key: ValueKey(snapshot.data),
            auth: widget.auth,
            factory: widget.factory,
            userId: snapshot.data!,
          ),
  );
}

class _Login extends StatefulWidget {
  const _Login({required this.auth});
  final AuthRepository auth;
  @override
  State<_Login> createState() => _LoginState();
}

class _LoginState extends State<_Login> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.auth.login(email.text, password.text);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Unable to sign in. Check your details and connection.',
        );
      }
    } finally {
      if (mounted) {
        password.clear();
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Uman — Sign in')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          if (error != null) Text(error!),
          FilledButton(
            onPressed: busy ? null : login,
            child: Text(busy ? 'Signing in…' : 'Sign in'),
          ),
        ],
      ),
    ),
  );
}

class _Events extends StatefulWidget {
  const _Events({
    super.key,
    required this.auth,
    required this.factory,
    required this.userId,
  });
  final AuthRepository auth;
  final ControllerFactory factory;
  final String userId;
  @override
  State<_Events> createState() => _EventsState();
}

class _EventsState extends State<_Events> with WidgetsBindingObserver {
  late EventController controller = widget.factory(widget.userId);
  bool signingOut = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(controller.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(controller.reconcile());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(releaseSession(controller));
    super.dispose();
  }

  Future<void> releaseSession(EventController session) async {
    await session.close();
    try {
      await session.cache.clear();
    } catch (_) {
      /* Cache still has a bounded expiry. */
    }
  }

  Future<void> logout() async {
    if (signingOut) return;
    setState(() => signingOut = true);
    // Stop all in-flight cache writes before erasing this account's snapshot.
    await controller.close();
    try {
      await controller.cache.clear();
      await widget.auth.logout();
    } catch (_) {
      if (mounted) {
        setState(() {
          controller = widget.factory(widget.userId);
          signingOut = false;
        });
        unawaited(controller.start());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign out could not finish. Try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<EventController, EventState>(
    bloc: controller,
    builder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Uman — Events'),
        actions: [
          TextButton(
            onPressed: signingOut ? null : logout,
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                !state.online
                    ? 'Offline — showing last synchronized data${state.synchronizedAt == null ? '' : '\n${state.synchronizedAt!.toLocal()}'}'
                    : switch (state.saveStatus) {
                        SaveStatus.saving => 'Saving…',
                        SaveStatus.conflict =>
                          'This record changed on another device',
                        SaveStatus.failed =>
                          'Save not confirmed. Check current data before retrying.',
                        _ => 'Synced',
                      },
              ),
            ),
            if (state.events.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No events available. An administrator must grant event access.',
                ),
              ),
            Expanded(
              child: ListView(
                children: [
                  for (final event in state.events.where((e) => !e.isDeleted))
                    ListTile(
                      key: ValueKey(event.id),
                      title: Text(event.name),
                      subtitle: Text(
                        '${event.year} · ${event.lifecycleStage.storageValue}',
                      ),
                      onTap:
                          !state.canEdit ||
                              event.lifecycleStage ==
                                  EventLifecycleStage.archived
                          ? null
                          : () => edit(event),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.canEdit ? () => edit(null) : null,
        tooltip: 'Create event',
        child: const Icon(Icons.add),
      ),
    ),
  );
  Future<void> edit(Event? base) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EventEditor(controller: controller, base: base),
    );
  }
}

class _EventEditor extends StatefulWidget {
  const _EventEditor({required this.controller, this.base});
  final EventController controller;
  final Event? base;
  @override
  State<_EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<_EventEditor> {
  late final name = TextEditingController(text: widget.base?.name);
  final start = TextEditingController(),
      end = TextEditingController(),
      currency = TextEditingController(text: 'USD');
  final requestId = UuidV4.generate();
  bool saving = false, conflicted = false;
  String? message;
  @override
  void dispose() {
    name.dispose();
    start.dispose();
    end.dispose();
    currency.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) return;
    if (widget.base == null &&
        (DateTime.tryParse(start.text) == null ||
            DateTime.tryParse(end.text) == null)) {
      setState(() => message = 'Enter dates as YYYY-MM-DD.');
      return;
    }
    setState(() {
      saving = true;
      message = null;
    });
    final ok = widget.base == null
        ? await widget.controller.create(
            NewEvent(
              requestId: requestId,
              name: name.text,
              year: DateTime.parse(start.text).year,
              startDate: start.text,
              endDate: end.text,
              baseCurrency: currency.text,
            ),
          )
        : await widget.controller.rename(widget.base!, name.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      saving = false;
      conflicted = widget.controller.state.saveStatus == SaveStatus.conflict;
      message = conflicted
          ? 'This record changed on another device. Your text is kept here. Copy it, close this form and reopen the latest record to apply it intentionally.'
          : 'Save not confirmed. Check connection and current data before retrying.';
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<EventController, EventState>(
        bloc: widget.controller,
        builder: (context, state) => AlertDialog(
          title: Text(widget.base == null ? 'Create event' : 'Edit event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                if (widget.base == null) ...[
                  TextField(
                    controller: start,
                    decoration: const InputDecoration(
                      labelText: 'Start date (YYYY-MM-DD)',
                    ),
                  ),
                  TextField(
                    controller: end,
                    decoration: const InputDecoration(
                      labelText: 'End date (YYYY-MM-DD)',
                    ),
                  ),
                  TextField(
                    controller: currency,
                    decoration: const InputDecoration(
                      labelText: 'Base currency (ISO code)',
                    ),
                  ),
                ],
                if (message != null) Text(message!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: saving || conflicted || !state.canEdit ? null : save,
              child: Text(saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      );
}
