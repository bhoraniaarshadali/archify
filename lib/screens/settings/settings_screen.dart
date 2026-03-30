import 'package:flutter/material.dart';
import '../../ads/app_state.dart';
import '../../services/helper/settings_service.dart';
import '../premium/premium_module_screen.dart';
import '../../navigation/app_navigator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../creations/my_creations_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_use_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Profile Section
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF6366F1),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guest User',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppState.isPremiumUser ? 'Premium Member' : 'Free Plan',
                          style: TextStyle(
                            color: AppState.isPremiumUser
                                ? Colors.amber[800]
                                : Colors.grey[500],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!AppState.isPremiumUser)
                    ElevatedButton(
                      onPressed: () => AppNavigator.push(context, const PremiumModuleScreen()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Upgrade'),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Settings Groups
            _buildSettingsGroup(context, 'Account', [
              _buildSettingsTile(
                context,
                icon: Icons.history,
                title: 'Design History',
                onTap: () => AppNavigator.push(context, const MyCreationsScreen()),
              ),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSettingsGroup(context, 'Preferences', [
              ValueListenableBuilder<bool>(
                valueListenable: SettingsService.instance.notificationsNotifier,
                builder: (context, enabled, _) {
                  return _buildSettingsTile(
                    context,
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    trailing: Switch(
                      value: enabled,
                      onChanged: (v) => SettingsService.instance.setNotifications(v),
                      activeThumbColor: const Color(0xFF6366F1),
                    ),
                  );
                },
              ),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSettingsGroup(context, 'Support', [
              _buildSettingsTile(
                context,
                icon: Icons.help_outline_rounded,
                title: 'Help Center',
                onTap: () => _launchURL('https://support.example.com'),
              ),
              _buildSettingsTile(
                context,
                icon: Icons.policy_outlined,
                title: 'Privacy Policy',
                onTap: () => AppNavigator.push(context, const PrivacyPolicyScreen()),
              ),
              _buildSettingsTile(
                context,
                icon: Icons.description_outlined,
                title: 'Terms of Use',
                onTap: () => AppNavigator.push(context, const TermsOfUseScreen()),
              ),
              _buildSettingsTile(
                context,
                icon: Icons.info_outline_rounded,
                title: 'About App',
                onTap: () => _showAboutDialog(context),
              ),
            ]),
            
            const SizedBox(height: 40),
            
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.grey[400],
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light 
              ? const Color(0xFFF8F9FC) 
              : Colors.black26,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).iconTheme.color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).textTheme.titleMedium?.color,
        ),
      ),
      subtitle: subtitle != null ? Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[500],
        ),
      ) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    );
  }
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAboutDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;

    showAboutDialog(
      context: context,
      applicationName: 'HouseDecor AI',
      applicationVersion: '${packageInfo.version} (${packageInfo.buildNumber})',
      applicationIcon: const Icon(Icons.home_work_rounded, size: 40, color: Color(0xFF6366F1)),
      children: [
        const Text('Transform your space with the power of Artificial Intelligence.'),
        const SizedBox(height: 12),
        const Text('© 2026 HouseDecor AI Team'),
      ],
    );
  }

}
