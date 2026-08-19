import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_overlays.dart';
import '../../widgets/standard_page_scaffold.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    final String name = authState.userName ?? 'Apollo Pharmacy';
    final String email = authState.userEmail ?? 'contact@apollopharmacy.com';
    final String phone = authState.userPhone ?? '+91 98765 00011';
    final String address = authState.userAddress ?? '123 Main Medical Street';
    final String city = authState.userCity ?? 'Mumbai';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';

    final String fullAddress = [
      if (address.isNotEmpty) address,
      if (city.isNotEmpty) city,
    ].join(', ');

    final canPop = context.canPop();
    return StandardPageScaffold(
      title: 'Profile',
      leading: canPop ? const BackButton() : null,
      drawer: canPop ? null : const AppDrawer(),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  gradient: AppGradients.brand,
                  borderColor: Colors.transparent,
                  child: Row(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              city.isNotEmpty ? city : 'Registered Client',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: [
                      InfoTile(
                        icon: Icons.phone_rounded,
                        title: 'Phone',
                        subtitle: phone.isNotEmpty ? phone : 'No phone number provided',
                      ),
                      const Divider(height: 28),
                      InfoTile(
                        icon: Icons.location_on_rounded,
                        title: 'Address',
                        subtitle: fullAddress.isNotEmpty ? fullAddress : 'No address provided',
                      ),
                      const Divider(height: 28),
                      const InfoTile(
                        icon: Icons.badge_rounded,
                        title: 'Account Type',
                        subtitle: 'Authorized ANIMEX Client Portal',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.edit_rounded),
                        title: Text(
                          'Edit Profile',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(AppRoutes.editProfile),
                      ),
                      const Divider(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.lock_reset_rounded),
                        title: Text(
                          'Change Password',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(AppRoutes.forgot),
                      ),
                      const Divider(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.settings_rounded),
                        title: Text(
                          'Settings',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push(AppRoutes.settings),
                      ),
                      const Divider(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.logout_rounded),
                        title: Text(
                          'Logout',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          final confirm = await showConfirmDialog(
                            context,
                            title: 'Logout',
                            message: 'Are you sure you want to log out?',
                            confirmLabel: 'Logout',
                          );
                          if (confirm == true) {
                            await ref.read(authProvider.notifier).logout();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.orange),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
