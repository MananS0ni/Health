import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/providers.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendOtp() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authStateProvider.notifier).sendOtpByEmail(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    if (authState.otpSent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/otp');
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FDFA), Color(0xFFF1F5F9), Color(0xFFEFF6FF)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Logo ──────────────────────────────────────────
                        Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.health_and_safety_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Center(
                          child: Text(
                            'HealthRecord',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Center(
                          child: Text(
                            'Your Digital Health Companion',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Section label ─────────────────────────────────
                        const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _EmailField(controller: _emailController),

                        const SizedBox(height: 18),

                        if (authState.error != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authState.error!,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── CTA ───────────────────────────────────────────
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _handleSendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child: authState.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Send OTP',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Divider ───────────────────────────────────────
                        Row(
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Sign up link ──────────────────────────────────
                        Center(
                          child: GestureDetector(
                            onTap: () => context.go('/signup'),
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                children: [
                                  TextSpan(text: 'New here? '),
                                  TextSpan(
                                    text: 'Create account',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Trust badges ──────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _TrustChip(Icons.lock_outline_rounded, 'Encrypted'),
                            const SizedBox(width: 14),
                            _TrustChip(Icons.verified_user_outlined, 'Secure'),
                            const SizedBox(width: 14),
                            _TrustChip(Icons.health_and_safety_outlined, 'Private'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Terms ─────────────────────────────────────────
                        const Text(
                          'By continuing, you agree to our Terms of Service and Privacy Policy.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────


class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  const _EmailField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Address',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: _inputDecoration(
            hint: 'you@example.com',
            prefixIcon: Icons.email_outlined,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Enter your email';
            if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
            return null;
          },
        ),
      ],
    );
  }
}


InputDecoration _inputDecoration({
  required String hint,
  Widget? prefix,
  IconData? prefixIcon,
}) {
  return InputDecoration(
    counterText: '',
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    prefixIcon: prefix ?? (prefixIcon != null
        ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary)
        : null),
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.emergency),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: AppColors.emergency, width: 1.5),
    ),
  );
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textTertiary)),
      ],
    );
  }
}
