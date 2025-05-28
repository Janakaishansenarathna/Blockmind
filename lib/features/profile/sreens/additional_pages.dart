import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/themes/gradient_background.dart';

// Time Management Screen
class TimeManagementScreen extends StatefulWidget {
  const TimeManagementScreen({super.key});

  @override
  State<TimeManagementScreen> createState() => _TimeManagementScreenState();
}

class _TimeManagementScreenState extends State<TimeManagementScreen> {
  bool dailyLimitEnabled = true;
  bool weeklyLimitEnabled = false;
  bool breakRemindersEnabled = true;
  int dailyHours = 4;
  int dailyMinutes = 30;
  int weeklyHours = 28;
  int breakInterval = 30;

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            _buildAppBar('Time Management'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTimeCard(),
                    const SizedBox(height: 24),
                    _buildLimitsCard(),
                    const SizedBox(height: 24),
                    _buildBreaksCard(),
                    const SizedBox(height: 24),
                    _buildQuickActionsCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Text(
            'Daily Usage Limit',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimePicker('Hours', dailyHours, 0, 12, (value) {
                setState(() => dailyHours = value);
              }),
              const SizedBox(width: 20),
              const Text(':',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 24)),
              const SizedBox(width: 20),
              _buildTimePicker('Minutes', dailyMinutes, 0, 59, (value) {
                setState(() => dailyMinutes = value);
              }),
            ],
          ),
          const SizedBox(height: 20),
          _buildToggleRow('Enable Daily Limit', dailyLimitEnabled, (value) {
            setState(() => dailyLimitEnabled = value);
          }),
        ],
      ),
    );
  }

  Widget _buildLimitsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Usage Limits', Icons.timer_outlined),
          const SizedBox(height: 20),
          _buildToggleRow('Weekly Limit', weeklyLimitEnabled, (value) {
            setState(() => weeklyLimitEnabled = value);
          }),
          if (weeklyLimitEnabled) ...[
            const SizedBox(height: 16),
            _buildSlider('Weekly Hours', weeklyHours, 1, 50, (value) {
              setState(() => weeklyHours = value.round());
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildBreaksCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Break Reminders', Icons.pause_circle_outline),
          const SizedBox(height: 20),
          _buildToggleRow('Break Reminders', breakRemindersEnabled, (value) {
            setState(() => breakRemindersEnabled = value);
          }),
          if (breakRemindersEnabled) ...[
            const SizedBox(height: 16),
            _buildSlider('Reminder Interval (minutes)', breakInterval, 15, 120,
                (value) {
              setState(() => breakInterval = value.round());
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Quick Actions', Icons.flash_on_outlined),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton('Reset Today', Icons.refresh, () {
                  _showResetDialog();
                }),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton('View Stats', Icons.analytics, () {
                  Get.snackbar('Stats', 'Opening usage statistics...');
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(
      String label, int value, int min, int max, Function(int) onChanged) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.containerBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: CupertinoPicker(
            itemExtent: 32,
            scrollController: FixedExtentScrollController(initialItem: value),
            onSelectedItemChanged: onChanged,
            children: List.generate(max - min + 1, (index) {
              return Center(
                child: Text(
                  (min + index).toString().padLeft(2, '0'),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 18),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  void _showResetDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.containerBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Today\'s Usage',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will reset today\'s usage statistics. Continue?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Reset Complete', 'Today\'s usage has been reset');
            },
            child:
                const Text('Reset', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// Language Screen
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String selectedLanguage = 'English';

  final List<Map<String, String>> languages = [
    {'name': 'English', 'code': 'en', 'flag': '🇺🇸'},
    {'name': 'Spanish', 'code': 'es', 'flag': '🇪🇸'},
    {'name': 'French', 'code': 'fr', 'flag': '🇫🇷'},
    {'name': 'German', 'code': 'de', 'flag': '🇩🇪'},
    {'name': 'Italian', 'code': 'it', 'flag': '🇮🇹'},
    {'name': 'Portuguese', 'code': 'pt', 'flag': '🇵🇹'},
    {'name': 'Chinese', 'code': 'zh', 'flag': '🇨🇳'},
    {'name': 'Japanese', 'code': 'ja', 'flag': '🇯🇵'},
    {'name': 'Korean', 'code': 'ko', 'flag': '🇰🇷'},
    {'name': 'Arabic', 'code': 'ar', 'flag': '🇸🇦'},
  ];

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            _buildAppBar('Language Settings'),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final language = languages[index];
                  final isSelected = language['name'] == selectedLanguage;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.containerBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.buttonPrimary
                            : AppColors.borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      leading: Text(
                        language['flag']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        language['name']!,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.buttonPrimary
                              : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: AppColors.buttonPrimary)
                          : null,
                      onTap: () {
                        setState(() => selectedLanguage = language['name']!);
                        Get.snackbar(
                          'Language Changed',
                          'Language set to ${language['name']}',
                          snackPosition: SnackPosition.TOP,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Theme Screen
class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  String selectedTheme = 'Dark';
  bool adaptiveTheme = false;

  final List<Map<String, dynamic>> themes = [
    {'name': 'Light', 'icon': Icons.light_mode, 'color': Colors.orange},
    {'name': 'Dark', 'icon': Icons.dark_mode, 'color': Colors.indigo},
    {'name': 'System', 'icon': Icons.phone_android, 'color': Colors.green},
  ];

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            _buildAppBar('Theme Settings'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildThemeSelector(),
                    const SizedBox(height: 24),
                    _buildCustomizationCard(),
                    const SizedBox(height: 24),
                    _buildPreviewCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Choose Theme', Icons.palette_outlined),
          const SizedBox(height: 20),
          ...themes.map((theme) {
            final isSelected = theme['name'] == selectedTheme;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme['color'].withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? theme['color'] : AppColors.borderColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: Icon(theme['icon'], color: theme['color']),
                title: Text(
                  theme['name'],
                  style: TextStyle(
                    color: isSelected ? theme['color'] : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: theme['color'])
                    : null,
                onTap: () => setState(() => selectedTheme = theme['name']),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCustomizationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Customization', Icons.tune_outlined),
          const SizedBox(height: 20),
          _buildToggleRow('Adaptive Theme', adaptiveTheme, (value) {
            setState(() => adaptiveTheme = value);
          }),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Preview', Icons.preview_outlined),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.backgroundGradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: const Center(
              child: Text(
                'Theme Preview',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Help Screen
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            _buildAppBar('Help & FAQ'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    _buildQuickHelpCard(),
                    const SizedBox(height: 24),
                    _buildFAQSection(),
                    const SizedBox(height: 24),
                    _buildContactCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: _cardDecoration(),
      child: TextField(
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: AppColors.iconSecondary),
          hintText: 'Search for help...',
          hintStyle: const TextStyle(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildQuickHelpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildSectionHeader('Quick Help', Icons.help_outline),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child:
                      _buildHelpAction('Tutorial', Icons.play_circle_outline)),
              const SizedBox(width: 16),
              Expanded(child: _buildHelpAction('Guide', Icons.book_outlined)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpAction(String title, IconData icon) {
    return GestureDetector(
      onTap: () => Get.snackbar('Help', 'Opening $title...'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.buttonPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.buttonPrimary, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      {
        'q': 'How to block apps?',
        'a': 'Go to Dashboard, select apps, and tap Block.'
      },
      {
        'q': 'How to set time limits?',
        'a': 'Use the Time Management section in Profile.'
      },
      {
        'q': 'How to export data?',
        'a': 'Use the Backup feature in Profile settings.'
      },
      {
        'q': 'How to upgrade to Premium?',
        'a': 'Tap the Premium badge in Profile.'
      },
    ];

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildSectionHeader(
                'Frequently Asked Questions', Icons.quiz_outlined),
          ),
          ...faqs
              .map((faq) => ExpansionTile(
                    title: Text(faq['q']!,
                        style: const TextStyle(color: AppColors.textPrimary)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(faq['a']!,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                      ),
                    ],
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildSectionHeader('Need More Help?', Icons.support_agent_outlined),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton('Email Support', Icons.email, () {
                  Get.snackbar('Support', 'Opening email client...');
                }),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton('Live Chat', Icons.chat, () {
                  Get.snackbar('Chat', 'Opening live chat...');
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Backup Screen
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool autoBackup = true;
  String lastBackup = '2 days ago';
  String backupSize = '2.4 MB';

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            _buildAppBar('Backup & Restore'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildBackupStatusCard(),
                    const SizedBox(height: 24),
                    _buildBackupActionsCard(),
                    const SizedBox(height: 24),
                    _buildSettingsCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.cloud_done,
                color: AppColors.success, size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Backup Status',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Last backup: $lastBackup',
              style: const TextStyle(color: AppColors.textSecondary)),
          Text('Size: $backupSize',
              style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBackupActionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildSectionHeader('Backup Actions', Icons.backup_outlined),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton('Backup Now', Icons.cloud_upload, () {
                  Get.snackbar('Backup', 'Creating backup...');
                }),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton('Restore', Icons.cloud_download, () {
                  _showRestoreDialog();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Backup Settings', Icons.settings_outlined),
          const SizedBox(height: 20),
          _buildToggleRow('Auto Backup', autoBackup, (value) {
            setState(() => autoBackup = value);
          }),
        ],
      ),
    );
  }

  void _showRestoreDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.containerBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Restore Data',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will replace your current data with backup data. Continue?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Restore', 'Data restored successfully');
            },
            child: const Text('Restore',
                style: TextStyle(color: AppColors.buttonPrimary)),
          ),
        ],
      ),
    );
  }
}

// Privacy Screen
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool analyticsEnabled = true;
  bool crashReportsEnabled = true;
  bool personalizedAds = false;

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            _buildAppBar('Privacy Settings'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildPrivacyOverviewCard(),
                    const SizedBox(height: 24),
                    _buildDataCollectionCard(),
                    const SizedBox(height: 24),
                    _buildPermissionsCard(),
                    const SizedBox(height: 24),
                    _buildDataControlCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.buttonPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.security,
                color: AppColors.buttonPrimary, size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your Privacy Matters',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'We are committed to protecting your privacy and keeping your data secure.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDataCollectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Data Collection', Icons.data_usage_outlined),
          const SizedBox(height: 20),
          _buildToggleRow('Usage Analytics', analyticsEnabled, (value) {
            setState(() => analyticsEnabled = value);
          }),
          _buildToggleRow('Crash Reports', crashReportsEnabled, (value) {
            setState(() => crashReportsEnabled = value);
          }),
          _buildToggleRow('Personalized Ads', personalizedAds, (value) {
            setState(() => personalizedAds = value);
          }),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'App Permissions', Icons.admin_panel_settings_outlined),
          const SizedBox(height: 20),
          _buildPermissionItem(
              'Usage Access', 'Required for app blocking', true),
          _buildPermissionItem(
              'Notifications', 'For alerts and reminders', true),
          _buildPermissionItem('Camera', 'For profile pictures', false),
          _buildPermissionItem('Storage', 'For backup and restore', false),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String title, String description, bool granted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                Text(description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataControlCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Data Control', Icons.manage_accounts_outlined),
          const SizedBox(height: 20),
          _buildActionButton('View Privacy Policy', Icons.description, () {
            Get.snackbar('Privacy Policy', 'Opening privacy policy...');
          }),
          const SizedBox(height: 16),
          _buildActionButton('Export My Data', Icons.download, () {
            Get.snackbar('Export', 'Preparing data export...');
          }),
          const SizedBox(height: 16),
          _buildActionButton('Delete My Data', Icons.delete_forever, () {
            _showDeleteDataDialog();
          }),
        ],
      ),
    );
  }

  void _showDeleteDataDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.containerBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete All Data',
            style: TextStyle(color: AppColors.error)),
        content: const Text(
          'This will permanently delete all your data. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Data Deleted', 'All data has been deleted');
            },
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// Shared widgets and utilities
Widget _buildAppBar(String title) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      border: Border(
        bottom:
            BorderSide(color: AppColors.borderColor.withOpacity(0.3), width: 1),
      ),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Get.back(),
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.containerBackground,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2))
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.iconPrimary, size: 16),
          ),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.containerBackground,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.borderColor.withOpacity(0.3), width: 1),
    boxShadow: [
      BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 15,
          offset: const Offset(0, 8))
    ],
  );
}

Widget _buildSectionHeader(String title, IconData icon) {
  return Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.buttonPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.buttonPrimary, size: 20),
      ),
      const SizedBox(width: 16),
      Text(title,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _buildToggleRow(String title, bool value, Function(bool) onChanged) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
      CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.buttonPrimary,
      ),
    ],
  );
}

Widget _buildSlider(
    String title, int value, int min, int max, Function(double) onChanged) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          Text('$value',
              style: const TextStyle(
                  color: AppColors.buttonPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
      Slider(
        value: value.toDouble(),
        min: min.toDouble(),
        max: max.toDouble(),
        activeColor: AppColors.buttonPrimary,
        inactiveColor: AppColors.containerBackground,
        onChanged: onChanged,
      ),
    ],
  );
}

Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.buttonPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.buttonPrimary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.buttonPrimary, size: 20),
          const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(
                  color: AppColors.buttonPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}
