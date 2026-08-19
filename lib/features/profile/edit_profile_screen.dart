import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_fields.dart';
import '../../widgets/standard_page_scaffold.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    _nameController = TextEditingController(text: authState.userName ?? 'Apollo Pharmacy');
    _emailController = TextEditingController(text: authState.userEmail ?? 'contact@apollopharmacy.com');
    _phoneController = TextEditingController(text: authState.userPhone ?? '+919876543210');
    _addressController = TextEditingController(text: authState.userAddress ?? '123 Main Medical Street');
    _cityController = TextEditingController(text: authState.userCity ?? 'Mumbai');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StandardPageScaffold(
      title: 'Edit Profile',
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            child: AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client Profile Settings',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Update your client account information and pharmacy contact details.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 700;
                      final fieldWidth =
                          wide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

                      Widget field(Widget child) =>
                          SizedBox(width: fieldWidth, child: child);

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          field(
                            AppTextField(
                              controller: _nameController,
                              label: 'Client / Firm Name',
                              prefixIcon: Icons.storefront_rounded,
                            ),
                          ),
                          field(
                            AppTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              readOnly: true,
                            ),
                          ),
                          field(
                            AppTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              prefixIcon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          field(
                            AppTextField(
                              controller: _cityController,
                              label: 'City',
                              prefixIcon: Icons.location_city_rounded,
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: AppTextField(
                              controller: _addressController,
                              label: 'Street Address',
                              prefixIcon: Icons.location_on_outlined,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Cancel',
                          icon: Icons.close_rounded,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Save Changes',
                          icon: Icons.check_circle_rounded,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Client profile updated successfully!'),
                                backgroundColor: Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
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
