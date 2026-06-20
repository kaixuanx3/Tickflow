import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../features/auth/viewmodel/auth_controller.dart';
import 'theme_mode.dart'; // sharedPreferencesProvider

final _localAuth = LocalAuthentication();

/// Whether this device can do biometric / device-credential auth. Always false
/// on web (no reliable browser API), so the Menu toggle is hidden there.
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) return false;
  try {
    return await _localAuth.isDeviceSupported();
  } catch (_) {
    return false;
  }
});

/// Persisted on/off switch for the app lock.
class BiometricEnabledController extends Notifier<bool> {
  static const _key = 'biometric_lock';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  /// Turning it on requires a successful auth first (proves capability + intent).
  Future<bool> enable() async {
    final ok = await _authenticate('Enable biometric unlock');
    if (ok) {
      state = true;
      await ref.read(sharedPreferencesProvider).setBool(_key, true);
    }
    return ok;
  }

  Future<void> disable() async {
    state = false;
    await ref.read(sharedPreferencesProvider).setBool(_key, false);
  }
}

final biometricEnabledProvider =
    NotifierProvider<BiometricEnabledController, bool>(BiometricEnabledController.new);

/// Runs the platform prompt. Returns false on any error or cancellation.
Future<bool> _authenticate(String reason) async {
  try {
    return await _localAuth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(stickyAuth: true),
    );
  } catch (_) {
    return false;
  }
}

/// Wraps the whole app. When the lock is enabled AND the user is signed in, a
/// lock screen covers everything on cold start and after returning from the
/// background, until biometrics succeed. No-op when disabled, signed out, or on
/// an unsupported platform.
class BiometricGate extends ConsumerStatefulWidget {
  const BiometricGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends ConsumerState<BiometricGate>
    with WidgetsBindingObserver {
  static const _relockAfter = Duration(seconds: 30);

  bool _locked = false;
  bool _unlockedThisSession = false;
  bool _authInFlight = false;
  DateTime? _pausedAt;

  bool get _enabled => ref.read(biometricEnabledProvider);
  bool get _signedIn => ref.read(authControllerProvider).value != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null
          ? Duration.zero
          : DateTime.now().difference(_pausedAt!);
      if (away >= _relockAfter) _unlockedThisSession = false;
      _maybeLock();
    }
  }

  void _maybeLock() {
    if (_enabled && _signedIn && !_unlockedThisSession && !_locked) {
      setState(() => _locked = true);
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_authInFlight) return;
    _authInFlight = true;
    final ok = await _authenticate('Unlock Tickflow');
    _authInFlight = false;
    if (!mounted) return;
    if (ok) {
      setState(() {
        _locked = false;
        _unlockedThisSession = true;
      });
    }
  }

  void _signOut() {
    setState(() {
      _locked = false;
      _unlockedThisSession = false;
    });
    ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    // React to sign-in changes: signing out clears the lock; a fresh sign-in is
    // evaluated for locking.
    ref.listen(authControllerProvider, (_, next) {
      if (next.value == null) {
        if (_locked || _unlockedThisSession) {
          setState(() {
            _locked = false;
            _unlockedThisSession = false;
          });
        }
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLock());
      }
    });

    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(child: _LockScreen(onUnlock: _unlock, onSignOut: _signOut)),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock, required this.onSignOut});

  final VoidCallback onUnlock;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text('Tickflow is locked', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Unlock with biometrics to continue.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: onSignOut, child: const Text('Sign out')),
            ],
          ),
        ),
      ),
    );
  }
}
