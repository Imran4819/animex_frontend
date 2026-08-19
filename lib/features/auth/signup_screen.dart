import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_fields.dart';
import '../../widgets/app_logo.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  bool _agree = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _onCreateAccount() async {
    final localContext = context;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();

    if (name.isEmpty) {
      _showError(localContext, 'Client/Firm Name is required');
      return;
    }
    if (email.isEmpty) {
      _showError(localContext, 'Email is required');
      return;
    }
    if (!_isValidEmail(email)) {
      _showError(localContext, 'Please enter a valid email address');
      return;
    }
    if (phone.isEmpty) {
      _showError(localContext, 'Phone Number is required');
      return;
    }
    if (!_agree) {
      _showError(localContext, 'You must agree to the Terms & Conditions');
      return;
    }

    final success = await ref.read(authProvider.notifier).signup(
          name: name,
          email: email,
          phone: phone,
          address: address,
          city: city,
        );

    if (success) {
      if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(
            content: Text('Account registered successfully!'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        localContext.go(AppRoutes.dashboard);
      }
    } else {
      if (localContext.mounted) {
        final error = ref.read(authProvider).errorMessage ?? 'Registration failed';
        _showError(localContext, error);
      }
    }
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 980;
                final formWidth = wide ? 520.0 : constraints.maxWidth;

                final form = AppCard(
                  padding: const EdgeInsets.all(24),
                  child: _SignupForm(
                    nameController: _nameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    addressController: _addressController,
                    cityController: _cityController,
                    agree: _agree,
                    isLoading: authState.isLoading,
                    onAgreeChanged: (value) {
                      if (!authState.isLoading) {
                        setState(() => _agree = value);
                      }
                    },
                    onCreateAccount: _onCreateAccount,
                    onLogin: () => context.go(AppRoutes.login),
                  ),
                );

                 if (!wide) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: formWidth),
                      child: Column(
                        children: [
                          const AppLogo(heroTag: 'animex-logo-signup', size: 74),
                          const SizedBox(height: 18),
                          form,
                        ],
                      ),
                    ),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1160),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: AppCard(
                            gradient: AppGradients.brand,
                            borderColor: Colors.transparent,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const AppLogo(
                                  heroTag: 'animex-logo-signup-wide',
                                  size: 88,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Register your pharmacy account',
                                      style: GoogleFonts.poppins(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Create your ANIMEX client profile to manage billing, products, and medical stores.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Colors.white.withValues(alpha: 0.88),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    _FeatureBullet(text: 'Client-scoped REST operations'),
                                    _FeatureBullet(text: 'Responsive dashboard and catalog management'),
                                    _FeatureBullet(text: 'Billing and invoice preview support'),
                                  ],
                                ),
                                Text(
                                  'ANIMEX Billing',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(width: formWidth, child: form),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SignupForm extends StatelessWidget {
  const _SignupForm({
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.cityController,
    required this.agree,
    required this.isLoading,
    required this.onAgreeChanged,
    required this.onCreateAccount,
    required this.onLogin,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final bool agree;
  final bool isLoading;
  final ValueChanged<bool> onAgreeChanged;
  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Register Client',
          style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Set up your client profile for your pharmacy business.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth > 700
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;

            Widget field(Widget child) {
              return SizedBox(width: fieldWidth, child: child);
            }

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                field(
                  AppTextField(
                    controller: nameController,
                    label: 'Client / Firm Name *',
                    prefixIcon: Icons.storefront_rounded,
                    readOnly: isLoading,
                  ),
                ),
                field(
                  AppTextField(
                    controller: emailController,
                    label: 'Email Address *',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: isLoading,
                  ),
                ),
                field(
                  AppTextField(
                    controller: phoneController,
                    label: 'Phone Number *',
                    prefixIcon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    readOnly: isLoading,
                  ),
                ),
                field(
                  AppTextField(
                    controller: cityController,
                    label: 'City',
                    prefixIcon: Icons.location_city_rounded,
                    readOnly: isLoading,
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth,
                  child: AppTextField(
                    controller: addressController,
                    label: 'Street Address',
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                    readOnly: isLoading,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Checkbox(
              value: agree,
              onChanged: isLoading ? null : (value) => onAgreeChanged(value ?? false),
            ),
            Expanded(
              child: Text(
                'I Agree to Terms & Conditions',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        PrimaryButton(
          label: isLoading ? 'Registering...' : 'Register Client',
          icon: isLoading ? null : Icons.rocket_launch_rounded,
          onPressed: isLoading ? () {} : onCreateAccount,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already registered?',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            LinkButton(
              label: 'Login',
              onPressed: isLoading ? () {} : onLogin,
              color: AppColors.orange,
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
