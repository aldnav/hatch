import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hatch/providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _showEmailField = false;
  bool _loading = false;
  final _emailController = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Generic sign-in wrapper used by Google and Apple buttons.
  Future<void> _signIn(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() =>
      _signIn(ref.read(authRepositoryProvider).signInWithGoogle);

  Future<void> _signInWithApple() =>
      _signIn(ref.read(authRepositoryProvider).signInWithApple);

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _emailError = 'Enter a valid email address');
      return;
    }
    setState(() {
      _loading = true;
      _emailError = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithMagicLink(email);
      if (mounted) {
        setState(() {
          _loading = false;
          _showEmailField = false;
        });
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your inbox — tap the link to sign in'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hatch',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Your travel planner',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: _loading ? null : _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _signInWithApple,
                icon: const Icon(Icons.apple),
                label: const Text('Continue with Apple'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () => setState(() => _showEmailField = !_showEmailField),
                icon: const Icon(Icons.email_outlined),
                label: const Text('Continue with email'),
              ),
              if (_showEmailField) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  enabled: !_loading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    errorText: _emailError,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loading ? null : _sendMagicLink,
                  child: const Text('Send magic link'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
