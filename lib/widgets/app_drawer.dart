import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import 'app_buttons.dart';
import 'app_cards.dart';
import 'app_logo.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: AppCard(
                padding: const EdgeInsets.all(18),
                gradient: AppGradients.brand,
                borderColor: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogo(size: 54, showLabel: false),
                    const SizedBox(height: 18),
                    Text(
                      'ANIMEX Billing',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Premium veterinary billing UI',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.space_dashboard_rounded,
                    label: 'Dashboard',
                    onTap: () => _go(context, AppRoutes.dashboard),
                  ),
                  _DrawerItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Create Bill',
                    onTap: () => _go(context, AppRoutes.createBill),
                  ),
                  _DrawerItem(
                    icon: Icons.history_rounded,
                    label: 'Bill History',
                    onTap: () => _go(context, AppRoutes.bills),
                  ),
                  _DrawerItem(
                    icon: Icons.inventory_2_rounded,
                    label: 'Products',
                    onTap: () => _go(context, AppRoutes.products),
                  ),
                  _DrawerItem(
                    icon: Icons.local_pharmacy_rounded,
                    label: 'Medical Stores',
                    onTap: () => _go(context, AppRoutes.stores),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () => _go(context, AppRoutes.settings),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SecondaryButton(
                label: 'Logout',
                icon: Icons.logout_rounded,
                onPressed: () => _go(context, AppRoutes.login),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.pop(context);
    context.go(route);
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon),
        title: Text(
          label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
