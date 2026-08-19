import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/theme_provider.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_overlays.dart';
import '../../widgets/standard_page_scaffold.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return StandardPageScaffold(
      title: 'Settings',
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Dark Mode',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          themeMode == ThemeMode.dark
                              ? 'Dark theme is currently active'
                              : 'Switch between light and dark theme',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        value: themeMode == ThemeMode.dark,
                        onChanged: (_) {
                          ref.read(themeModeProvider.notifier).toggle();
                        },
                      ),
                      const Divider(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Notifications',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Receive UI-only reminders and alerts',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        value: _notifications,
                        onChanged: (value) => setState(() => _notifications = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.language_rounded,
                        title: 'Language',
                        subtitle: 'English',
                        onTap: () => showInfoSheet(
                          context,
                          title: 'Language',
                          message: 'Language selection is a UI-only placeholder.',
                          actionLabel: 'Close',
                        ),
                      ),
                      const Divider(height: 24),
                      _SettingsTile(
                        icon: Icons.privacy_tip_rounded,
                        title: 'Privacy Policy',
                        subtitle: 'Read how we handle information',
                        onTap: () => showInfoSheet(
                          context,
                          title: 'Privacy Policy',
                          message: 'This section is ready for your content.',
                          actionLabel: 'Close',
                        ),
                      ),
                      const Divider(height: 24),
                      _SettingsTile(
                        icon: Icons.description_rounded,
                        title: 'Terms of Service',
                        subtitle: 'Review the terms and conditions',
                        onTap: () => showInfoSheet(
                          context,
                          title: 'Terms of Service',
                          message: 'This is a placeholder settings page.',
                          actionLabel: 'Close',
                        ),
                      ),
                      const Divider(height: 24),
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About',
                        subtitle: 'ANIMEX Billing UI only',
                        onTap: () => showInfoSheet(
                          context,
                          title: 'About',
                          message: 'Premium Flutter frontend for ANIMEX Billing.',
                          actionLabel: 'Close',
                        ),
                      ),
                      const Divider(height: 24),
                      const _SettingsTile(
                        icon: Icons.update_rounded,
                        title: 'App Version',
                        subtitle: '1.0.0',
                      ),
                      const Divider(height: 24),
                      _SettingsTile(
                        icon: Icons.support_agent_rounded,
                        title: 'Support',
                        subtitle: 'Contact the ANIMEX support team',
                        onTap: () => showInfoSheet(
                          context,
                          title: 'Support',
                          message: 'Add your support contact details here.',
                          actionLabel: 'Close',
                        ),
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.orange),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
      ),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
