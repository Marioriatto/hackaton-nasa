import 'package:flutter/material.dart';

import '../../screens/aqua_debt_tokens.dart';
import 'auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();
  bool _obscure = true;
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await _auth.signUp(
        nombre: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
    } on AuthUiException catch (e) {
      setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AquaColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AquaCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Crear cuenta', style: AquaText.title),
                    const SizedBox(height: 8),
                    const Text(
                      'Registra tu cuenta para empezar a monitorear riesgo agrícola.',
                      style: AquaText.body,
                    ),
                    const SizedBox(height: 24),
                    _field(
                      _name,
                      'Nombre completo',
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Ingresa tu nombre.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      _email,
                      'Correo electrónico',
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    _field(
                      _password,
                      'Contraseña',
                      obscureText: _obscure,
                      validator: _validatePassword,
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _field(
                      _confirm,
                      'Confirmar contraseña',
                      obscureText: _obscure,
                      validator: (value) => value != _password.text
                          ? 'Las contraseñas no coinciden.'
                          : null,
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _message!,
                        style: AquaText.small.copyWith(
                          color: AquaColors.warningText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    PrimaryButton(
                      text: _loading ? 'Creando cuenta...' : 'Crear cuenta',
                      onPressed: _loading ? null : _submit,
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Ya tengo cuenta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(labelText: label, suffixIcon: suffix),
    );
  }
}

String? _validateEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Ingresa tu correo.';
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(text)) {
    return 'Ingresa un correo válido.';
  }
  return null;
}

String? _validatePassword(String? value) {
  if ((value ?? '').length < 8) {
    return 'La contraseña debe tener al menos 8 caracteres.';
  }
  return null;
}
