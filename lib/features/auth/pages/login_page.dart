import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:toastification/toastification.dart';
import 'package:salus/core/routes/app_router.dart';
import 'package:salus/core/sources/user_registration.dart';
import 'package:salus/core/themes/app_theme.dart';
import 'package:salus/core/utils/auth_state.dart';
import 'package:salus/core/utils/log.dart';
import 'package:salus/core/widgets/app_logo.dart';
import 'package:salus/core/widgets/google_logo.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _busy = false;
  bool _registering = false;

  void _notify(
    String message, {
    ToastificationType type = ToastificationType.info,
  }) {
    toastification.show(
      context: context,
      title: Text(message),
      type: type,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  void _enter() {
    context.router.replace(const MainRoute());
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final credential = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: account.authentication.idToken),
      );
      await _register(credential.user);
    } catch (e, s) {
      Log.error('Connexion Google impossible', e, s);
      if (mounted) {
        _notify('Connexion Google impossible', type: ToastificationType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _registering = false;
        });
      }
    }
  }

  /// Writes the Firestore profile, then enters the app.
  ///
  /// A Firestore failure is deliberately non-fatal: this is an emergency app,
  /// the user must reach the SOS button even with no network. The write is
  /// retried by the Firestore local cache on the next successful sync.
  Future<void> _register(User? user) async {
    if (user == null) {
      _notify('Connexion Google incomplète', type: ToastificationType.error);
      return;
    }
    setState(() => _registering = true);
    try {
      await ensureUserDocument(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      );
    } catch (e, s) {
      Log.error('Enregistrement du profil impossible', e, s);
      _notify(
        'Profil non synchronisé, réessaie plus tard',
        type: ToastificationType.warning,
      );
    }
    if (mounted) _enter();
  }

  Future<void> _enterAsGuest() async {
    await setGuestMode();
    if (!mounted) return;
    _enter();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(child: AppLogo(size: 140)),
              const SizedBox(height: 16),
              Text(
                'SALUS',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aide d’urgence, refuges et alertes.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              if (_registering) ...[
                const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Finalisation de votre compte…',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: _busy ? null : _signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GoogleLogo(size: 20),
                    SizedBox(width: 10),
                    Text('Continuer avec Google'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _busy ? null : _enterAsGuest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sos,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continuer sans connexion'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
