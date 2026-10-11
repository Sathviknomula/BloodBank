import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_colors.dart';
import '../admin/admin_dashboard_screen.dart';
import '../management/management_dashboard.dart';

class HospitalLoginScreen extends StatefulWidget {
  final bool isAdminLogin;

  const HospitalLoginScreen({
    super.key,
    this.isAdminLogin = false,
  });

  @override
  State<HospitalLoginScreen> createState() => _HospitalLoginScreenState();
}

class _HospitalLoginScreenState extends State<HospitalLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-fill with requested firebase account
    _emailController.text = 'steaverogers111@gmail.com';
    _passwordController.text = 'steave123';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppStateProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (widget.isAdminLogin) {
      final success = appState.loginAdmin(email, password);
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid Admin credentials. Use steaverogers111@gmail.com / steave123';
        });
      }
    } else {
      final success = appState.loginHospital(email, password);
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ManagementDashboard()),
        );
      } else {
        setState(() {
          _errorMessage = 'Hospital account not found. Try: steaverogers111@gmail.com or apollo@bloodbank.in';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isAdminLogin ? 'Admin / Developer Portal' : 'Hospital Management Login';
    final subtitle = widget.isAdminLogin
        ? 'Access system metrics, manage hospitals & view network requests'
        : 'Update blood sachets stock and process emergency customer requests';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(title),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon Header with subtle pastel styling
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE57373), Color(0xFFD9534F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(45),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.isAdminLogin ? Icons.admin_panel_settings_rounded : Icons.domain_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Authorized Firebase Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter your email';
                      if (!val.contains('@')) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter your password';
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(
                      widget.isAdminLogin ? 'Login to Admin Dashboard' : 'Login to Blood Bank',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Demo quick fill chips with steaverogers111@gmail.com
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.vpn_key_rounded, size: 14, color: AppColors.accent),
                            SizedBox(width: 6),
                            Text(
                              'Firebase Connected Accounts:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.verified_user_rounded, size: 15, color: AppColors.primary),
                              label: const Text('steaverogers111@gmail.com'),
                              backgroundColor: AppColors.primaryTint,
                              side: BorderSide(color: AppColors.primary.withAlpha(70)),
                              onPressed: () {
                                _emailController.text = 'steaverogers111@gmail.com';
                                _passwordController.text = 'steave123';
                              },
                            ),
                            if (!widget.isAdminLogin) ...[
                              ActionChip(
                                avatar: const Icon(Icons.local_hospital, size: 15),
                                label: const Text('Apollo Hospital'),
                                onPressed: () {
                                  _emailController.text = 'apollo@bloodbank.in';
                                  _passwordController.text = 'apollo123';
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.local_hospital, size: 15),
                                label: const Text('Red Cross Society'),
                                onPressed: () {
                                  _emailController.text = 'redcross@bloodbank.in';
                                  _passwordController.text = 'redcross123';
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
