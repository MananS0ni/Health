import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/config/providers.dart';
import '../../shared/models/user.dart';

class OtpEntryScreen extends ConsumerStatefulWidget {
  const OtpEntryScreen({super.key});

  @override
  ConsumerState<OtpEntryScreen> createState() => _OtpEntryScreenState();
}

class _OtpEntryScreenState extends ConsumerState<OtpEntryScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  int _resendTimer = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    const demoOtp = '482910';
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].text = demoOtp[i];
    }
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      bool keepGoing = true;
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
          keepGoing = false;
        }
      });
      return keepGoing && _resendTimer > 0;
    });
  }

  void _handleOtpChange(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isNotEmpty && index == 5) {
      final otp = _otpControllers.map((c) => c.text).join();
      if (otp.length == 6) _verifyOtp(otp);
    }
  }

  void _handleKeyDown(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _verifyOtp(String otp) {
    ref.read(authStateProvider.notifier).verifyOtp(otp);
  }

  void _handleResendOtp() {
    if (_canResend) {
      final authState = ref.read(authStateProvider);
      ref
          .read(authStateProvider.notifier)
          .sendOtp(authState.phoneNumber ?? '');
      setState(() {
        _resendTimer = 30;
        _canResend = false;
      });
      _startResendTimer();
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final User user = authState.user ?? ref.read(userProvider);
        if (user.roles.length > 1) {
          context.go('/role-select');
        } else if (user.roles.contains('doctor')) {
          ref.read(activeRoleProvider.notifier).setRole('doctor');
          context.go('/doctor');
        } else if (user.roles.contains('lab_staff')) {
          ref.read(activeRoleProvider.notifier).setRole('lab_staff');
          context.go('/lab');
        } else if (user.roles.contains('hospital_staff')) {
          ref.read(activeRoleProvider.notifier).setRole('hospital_staff');
          context.go('/hospital');
        } else {
          ref.read(activeRoleProvider.notifier).setRole('patient');
          context.go('/dashboard');
        }
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
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Back button row ─────────────────────────────────
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/phone');
                              }
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Header ──────────────────────────────────────────
                      Text(
                        'Enter OTP',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                          children: [
                            const TextSpan(text: 'We sent a 6-digit code to '),
                            TextSpan(
                              text: '+91 ${authState.phoneNumber ?? ''}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.mark_chat_read_rounded, size: 16, color: Color(0xFF0F766E)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Demo Code: 482910 (Auto-filled for testing)',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── OTP boxes ───────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 44,
                            height: 52,
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (event) =>
                                  _handleKeyDown(event, index),
                              child: TextFormField(
                                controller: _otpControllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  contentPadding: EdgeInsets.zero,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9),
                                    borderSide: const BorderSide(
                                        color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(9),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary, width: 2),
                                  ),
                                ),
                                onChanged: (value) =>
                                    _handleOtpChange(index, value),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      // ── Verify button ───────────────────────────────────
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: authState.isLoading
                              ? null
                              : () {
                                  final otp = _otpControllers
                                      .map((c) => c.text)
                                      .join();
                                  if (otp.length == 6) _verifyOtp(otp);
                                },
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
                                  'Verify & Continue',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Resend row ──────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive it? ",
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          if (_canResend)
                            GestureDetector(
                              onTap: _handleResendOtp,
                              child: Text(
                                'Resend OTP',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            )
                          else
                            Text(
                              'Resend in ${_resendTimer}s',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textTertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                        ],
                      ),

                      // ── Error message ───────────────────────────────────
                      if (authState.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.emergencyLight,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                                color: AppColors.emergency.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppColors.emergency, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  authState.error!,
                                  style: const TextStyle(
                                    color: AppColors.emergency,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
