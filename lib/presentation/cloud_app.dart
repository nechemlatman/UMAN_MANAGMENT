import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../application/event_controller.dart';
import '../domain/repositories/auth_repository.dart';
import 'design_system.dart';
import 'events/event_editor.dart';
import 'events/event_details.dart';
import 'events/event_shell.dart';

typedef ControllerFactory = EventController Function(String userId);

class CloudApp extends StatelessWidget {
  const CloudApp({
    super.key,
    this.auth,
    this.createController,
    this.setupMessage,
    this.peopleFactory,
  });
  final AuthRepository? auth;
  final ControllerFactory? createController;
  final String? setupMessage;
  final PeopleRepositoryFactory? peopleFactory;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Uman Event Manager',
    theme: AppTheme.theme(Brightness.light),
    darkTheme: AppTheme.theme(Brightness.dark),
    home: auth == null
        ? Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.xl),
                  child: Text(setupMessage ?? 'Cloud configuration required.'),
                ),
              ),
            ),
          )
        : _SessionGate(
            auth: auth!,
            factory: createController!,
            peopleFactory: peopleFactory,
          ),
  );
}

class _SessionGate extends StatefulWidget {
  const _SessionGate({
    required this.auth,
    required this.factory,
    this.peopleFactory,
  });
  final AuthRepository auth;
  final ControllerFactory factory;
  final PeopleRepositoryFactory? peopleFactory;
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
            peopleFactory: widget.peopleFactory,
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
        padding: const EdgeInsets.all(AppSpace.xl),
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
    this.peopleFactory,
  });
  final AuthRepository auth;
  final ControllerFactory factory;
  final String userId;
  final PeopleRepositoryFactory? peopleFactory;
  @override
  State<_Events> createState() => _EventsState();
}

class _EventsState extends State<_Events> with WidgetsBindingObserver {
  late EventController controller = widget.factory(widget.userId);
  bool signingOut = false, showDeleted = false;
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
              padding: const EdgeInsets.all(AppSpace.l),
              child: Text(
                state.loading
                    ? 'Loading events…'
                    : !state.online
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
            if (state.online && state.events.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpace.l),
                child: Text(
                  'No events available. An administrator must grant event access.',
                ),
              ),
            CheckboxListTile(
              title: const Text('Show deleted events'),
              value: showDeleted,
              onChanged: (value) =>
                  setState(() => showDeleted = value ?? false),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final event in state.events.where(
                    (e) => showDeleted ? e.isDeleted : !e.isDeleted,
                  ))
                    ListTile(
                      key: ValueKey(event.id),
                      title: Text(event.name),
                      subtitle: Text(
                        '${event.year} · ${event.lifecycleStage.storageValue}',
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              widget.peopleFactory != null && !event.isDeleted
                              ? EventShell(
                                  events: controller,
                                  eventId: event.id,
                                  peopleFactory: widget.peopleFactory!,
                                )
                              : EventDetailsPage(
                                  controller: controller,
                                  eventId: event.id,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.capabilities().canCreate
            ? () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => EventEditor(controller: controller),
                ),
              )
            : null,
        tooltip: 'Create event',
        child: const Icon(Icons.add),
      ),
    ),
  );
}
