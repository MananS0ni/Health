import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/providers.dart';

const _kSpecializations = [
  'General Physician',
  'Cardiologist',
  'Dermatologist',
  'Neurologist',
  'Orthopedic Surgeon',
  'Pediatrician',
  'Psychiatrist',
  'Gynecologist',
  'ENT Specialist',
  'Ophthalmologist',
  'Radiologist',
  'Oncologist',
  'Gastroenterologist',
  'Pulmonologist',
  'Nephrologist',
  'Endocrinologist',
  'Rheumatologist',
  'Urologist',
  'Other',
];

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  LoginMode _mode = LoginMode.phone;

  // Roles — patient is always selected
  final Set<String> _selectedRoles = {'patient'};

  // Doctor fields
  final _regNoController = TextEditingController();
  final _clinicController = TextEditingController();
  String _specialization = _kSpecializations.first;

  // Org fields (lab/hospital staff)
  final _orgNameController = TextEditingController();
  final _empIdController = TextEditingController();

  bool _termsAccepted = false;
  bool _isLoading = false;

  bool get _isDoctor => _selectedRoles.contains('doctor');
  bool get _isOrgRole =>
      _selectedRoles.contains('lab_staff') ||
      _selectedRoles.contains('hospital_staff');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _regNoController.dispose();
    _clinicController.dispose();
    _orgNameController.dispose();
    _empIdController.dispose();
    super.dispose();
  }

  void _handleCreateAccount() {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate registration → OTP flow
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (_mode == LoginMode.phone) {
        ref
            .read(authStateProvider.notifier)
            .sendOtpByPhone(_phoneController.text.trim());
      } else {
        ref
            .read(authStateProvider.notifier)
            .sendOtpByEmail(_emailController.text.trim());
      }
    });
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
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
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
                        // ── Header ────────────────────────────────────────
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.go('/'),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Join HealthRecord in seconds',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const _SectionDivider(label: 'Basic Info'),
                        const SizedBox(height: 14),

                        // ── Full name ─────────────────────────────────────
                        _FormLabel('Full Name'),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _dec('Rahul Sharma',
                              icon: Icons.person_outline),
                          validator: (v) => (v == null || v.trim().length < 2)
                              ? 'Enter your full name'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // ── Phone / Email toggle ──────────────────────────
                        _FormLabel('Sign-in Method'),
                        const SizedBox(height: 7),
                        _ModeToggle(
                          mode: _mode,
                          onChanged: (m) => setState(() {
                            _mode = m;
                            _formKey.currentState?.reset();
                          }),
                        ),
                        const SizedBox(height: 10),
                        if (_mode == LoginMode.phone)
                          _PhoneInput(controller: _phoneController)
                        else
                          _EmailInput(controller: _emailController),
                        const SizedBox(height: 22),

                        // ── Role chips ────────────────────────────────────
                        const _SectionDivider(label: 'Account Type'),
                        const SizedBox(height: 6),
                        const Text(
                          'Every account is a Patient account by default. Select additional professional roles if applicable.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _RoleChip(
                              label: 'Patient',
                              icon: Icons.person_rounded,
                              selected: true,
                              locked: true,
                              onToggle: (_) {},
                            ),
                            _RoleChip(
                              label: 'Doctor',
                              icon: Icons.medical_services_outlined,
                              selected: _selectedRoles.contains('doctor'),
                              onToggle: (v) => setState(() {
                                v
                                    ? _selectedRoles.add('doctor')
                                    : _selectedRoles.remove('doctor');
                              }),
                            ),
                            _RoleChip(
                              label: 'Lab Staff',
                              icon: Icons.science_outlined,
                              selected: _selectedRoles.contains('lab_staff'),
                              onToggle: (v) => setState(() {
                                v
                                    ? _selectedRoles.add('lab_staff')
                                    : _selectedRoles.remove('lab_staff');
                              }),
                            ),
                            _RoleChip(
                              label: 'Hospital Staff',
                              icon: Icons.local_hospital_outlined,
                              selected:
                                  _selectedRoles.contains('hospital_staff'),
                              onToggle: (v) => setState(() {
                                v
                                    ? _selectedRoles.add('hospital_staff')
                                    : _selectedRoles.remove('hospital_staff');
                              }),
                            ),
                          ],
                        ),

                        // ── Doctor fields ─────────────────────────────────
                        if (_isDoctor) ...[
                          const SizedBox(height: 20),
                          const _SectionDivider(label: 'Doctor Details'),
                          const SizedBox(height: 14),
                          _FormLabel('Medical Registration Number *'),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: _regNoController,
                            decoration: _dec('e.g. MH-12345',
                                icon: Icons.badge_outlined),
                            validator: _isDoctor
                                ? (v) => (v == null || v.trim().isEmpty)
                                    ? 'Registration number required'
                                    : null
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _FormLabel('Specialization *'),
                          const SizedBox(height: 7),
                          DropdownButtonFormField<String>(
                            initialValue: _specialization,
                            decoration: _dec(''),
                            isExpanded: true,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            items: _kSpecializations
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _specialization = v!),
                          ),
                          const SizedBox(height: 12),
                          _FormLabel('Clinic / Hospital Name (optional)'),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: _clinicController,
                            decoration: _dec('e.g. Apollo Clinic',
                                icon: Icons.local_hospital_outlined),
                          ),
                        ],

                        // ── Org fields ────────────────────────────────────
                        if (_isOrgRole) ...[
                          const SizedBox(height: 20),
                          const _SectionDivider(label: 'Organisation Details'),
                          const SizedBox(height: 14),
                          _FormLabel('Organisation Name *'),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: _orgNameController,
                            decoration: _dec('e.g. Narayana Health',
                                icon: Icons.business_outlined),
                            validator: _isOrgRole
                                ? (v) => (v == null || v.trim().isEmpty)
                                    ? 'Organisation name required'
                                    : null
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _FormLabel('Employee ID (optional)'),
                          const SizedBox(height: 7),
                          TextFormField(
                            controller: _empIdController,
                            decoration: _dec('e.g. EMP-0042',
                                icon: Icons.tag_outlined),
                          ),
                        ],

                        const SizedBox(height: 22),

                        // ── Terms ─────────────────────────────────────────
                        GestureDetector(
                          onTap: () =>
                              setState(() => _termsAccepted = !_termsAccepted),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _termsAccepted,
                                  onChanged: (v) => setState(
                                      () => _termsAccepted = v ?? false),
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'I agree to the Terms of Service and Privacy Policy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ── Create Account button ─────────────────────────
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed:
                                (_isLoading || authState.isLoading)
                                    ? null
                                    : _handleCreateAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child: (_isLoading || authState.isLoading)
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Create Account & Send OTP',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Already have account ──────────────────────────
                        Center(
                          child: GestureDetector(
                            onTap: () => context.go('/'),
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                                children: [
                                  TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Sign in',
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
// Helpers
// ─────────────────────────────────────────────────────────────

InputDecoration _dec(String hint, {IconData? icon}) {
  return InputDecoration(
    counterText: '',
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    prefixIcon:
        icon != null ? Icon(icon, size: 18, color: AppColors.textSecondary) : null,
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

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      );
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(height: 1)),
        ],
      );
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool locked;
  final ValueChanged<bool> onToggle;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onToggle,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    final bg = selected
        ? AppColors.primary.withValues(alpha: 0.08)
        : const Color(0xFFF3F4F6);
    final border =
        selected ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border;

    return GestureDetector(
      onTap: locked ? null : () => onToggle(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 5),
              Icon(
                locked ? Icons.lock_rounded : Icons.check_circle_rounded,
                size: 14,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Re-use the mode toggle and input widgets from login screen
class _ModeToggle extends StatelessWidget {
  final LoginMode mode;
  final ValueChanged<LoginMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          _Tab('Phone', Icons.phone_outlined, mode == LoginMode.phone,
              () => onChanged(LoginMode.phone)),
          _Tab('Email', Icons.email_outlined, mode == LoginMode.email,
              () => onChanged(LoginMode.email)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _Tab(this.label, this.icon, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneInput extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        counterText: '',
        hintText: '98765 43210',
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        prefixIcon: _CountryPrefix(),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
          borderSide:
              const BorderSide(color: AppColors.emergency, width: 1.5),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter your mobile number';
        if (v.length < 10) return 'Enter a valid 10-digit number';
        return null;
      },
    );
  }
}

class _EmailInput extends StatelessWidget {
  final TextEditingController controller;
  const _EmailInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: _dec('you@example.com', icon: Icons.email_outlined),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter your email';
        if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
        return null;
      },
    );
  }
}

class _CountryPrefix extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 1),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('🇮🇳', style: TextStyle(fontSize: 14)),
          SizedBox(width: 4),
          Text(
            '+91',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
