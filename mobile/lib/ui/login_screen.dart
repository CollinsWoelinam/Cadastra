import 'package:flutter/material.dart';

import '../app.dart';
import 'theme.dart';
import 'widgets.dart';

/// Sign-in form. As the app's home it gates first use; pushed as a route it
/// renews an expired session and pops on success.
class LoginScreen extends StatefulWidget {
  final String? email;

  const LoginScreen({super.key, this.email});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final services = Services.read(context);
    final error = await services.session.login(_email.text, _password.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    await services.db.claimUnownedSurveys(services.session.user!.id);
    services.sync.sync();
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navigator.of(context).canPop() ? AppBar(title: const Text('Sign in')) : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Row(children: [
                  BrandMark(size: 34),
                  SizedBox(width: 10),
                  Text('Cadastra Field', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 32),
                const Text('Sign in', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Use the surveyor account your registry administrator gave you.',
                    style: TextStyle(color: Palette.muted, fontSize: 15)),
                const SizedBox(height: 28),
                TextFormField(
                  key: const Key('login-email'),
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  autocorrect: false,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter your email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('login-password'),
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Callout(
                      icon: _error!.startsWith('Too many') ? Icons.schedule : Icons.error_outline,
                      tone: _error!.startsWith('Too many') ? Tone.amber : Tone.red,
                      child: Text(_error!, key: const Key('login-error')),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('login-submit'),
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? 'Signing in…' : 'Sign in'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
