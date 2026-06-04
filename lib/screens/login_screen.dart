import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _mfaCtrl = TextEditingController();

  bool _loading = false;
  String _error = '';
  bool _mfaRequired = false;
  int? _mfaUserId;
  String _mfaType = 'email';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _mfaCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final l10n = AppL10n.of(context)!;
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = l10n.errorFillAll);
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      final data = await context.read<AuthService>().login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (!mounted) return;
      if (data['mfaRequired'] == true) {
        setState(() {
          _mfaRequired = true;
          _mfaUserId = data['userId'] as int?;
          _mfaType = data['mfaType'] as String? ?? 'email';
          _loading = false;
        });
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _verifyMfa() async {
    if (_mfaCtrl.text.isEmpty || _mfaUserId == null) return;
    setState(() { _loading = true; _error = ''; });
    try {
      await context.read<AuthService>().verifyMfa(_mfaUserId!, _mfaCtrl.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFB3B3B3)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF1DB954),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.music_note, color: Colors.black, size: 44),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.adminLogin,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.adminSubtitle,
                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
              ),
              const SizedBox(height: 40),

              if (!_mfaRequired) ...[
                _Input(controller: _emailCtrl, hint: l10n.hintEmail, icon: Icons.email_outlined,
                    type: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _Input(controller: _passwordCtrl, hint: l10n.hintPassword, icon: Icons.lock_outline,
                    obscure: true),
                const SizedBox(height: 24),
                _Button(label: l10n.btnSignIn, loading: _loading, onTap: _login),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1DB954).withValues(alpha:0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: Color(0xFF1DB954)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _mfaType == 'totp'
                              ? l10n.mfaTotp
                              : l10n.mfaEmail,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Input(
                  controller: _mfaCtrl,
                  hint: l10n.hint6digit,
                  icon: Icons.pin_outlined,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 24),
                _Button(label: l10n.btnVerify, loading: _loading, onTap: _verifyMfa),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() { _mfaRequired = false; _error = ''; }),
                  child: Text(l10n.backToLogin,
                      style: const TextStyle(color: Color(0xFFB3B3B3))),
                ),
              ],

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE22134).withValues(alpha:0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE22134).withValues(alpha:0.6)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFE22134), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error,
                            style: const TextStyle(color: Color(0xFFE22134), fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType type;

  const _Input({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB3B3B3)),
        prefixIcon: Icon(icon, color: const Color(0xFF1DB954), size: 20),
        filled: true,
        fillColor: const Color(0xFF282828),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1DB954), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _Button({required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1DB954),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
              )
            : Text(label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
