import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_colors.dart';
import '../../../utils/themes/gradient_background.dart';

// Responsive Time Management Screen
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final horizontalPadding = isTablet ? 48.0 : 20.0;

            return Column(
              children: [
                _buildResponsiveAppBar('Time Management', isTablet),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 800 : double.infinity,
                        ),
                        child: Column(
                          children: [
                            _buildTimeCard(isTablet),
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildLimitsCard(isTablet),
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildBreaksCard(isTablet),
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildQuickActionsCard(isTablet),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            'Daily Usage Limit',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 28 : 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 300) {
                // Stack vertically on very small screens
                return Column(
                  children: [
                    _buildTimePicker('Hours', dailyHours, 0, 12, (value) {
                      setState(() => dailyHours = value);
                    }, isTablet),
                    SizedBox(height: isTablet ? 20 : 16),
                    _buildTimePicker('Minutes', dailyMinutes, 0, 59, (value) {
                      setState(() => dailyMinutes = value);
                    }, isTablet),
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimePicker('Hours', dailyHours, 0, 12, (value) {
                      setState(() => dailyHours = value);
                    }, isTablet),
                    SizedBox(width: isTablet ? 32 : 20),
                    Text(
                      ':',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: isTablet ? 32 : 24,
                      ),
                    ),
                    SizedBox(width: isTablet ? 32 : 20),
                    _buildTimePicker('Minutes', dailyMinutes, 0, 59, (value) {
                      setState(() => dailyMinutes = value);
                    }, isTablet),
                  ],
                );
              }
            },
          ),
          SizedBox(height: isTablet ? 28 : 20),
          _buildToggleRow('Enable Daily Limit', dailyLimitEnabled, (value) {
            setState(() => dailyLimitEnabled = value);
          }, isTablet),
        ],
      ),
    );
  }

  Widget _buildLimitsCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Usage Limits', Icons.timer_outlined, isTablet),
          SizedBox(height: isTablet ? 28 : 20),
          _buildToggleRow('Weekly Limit', weeklyLimitEnabled, (value) {
            setState(() => weeklyLimitEnabled = value);
          }, isTablet),
          if (weeklyLimitEnabled) ...[
            SizedBox(height: isTablet ? 24 : 16),
            _buildSlider('Weekly Hours', weeklyHours, 1, 50, (value) {
              setState(() => weeklyHours = value.round());
            }, isTablet),
          ],
        ],
      ),
    );
  }

  Widget _buildBreaksCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'Break Reminders', Icons.pause_circle_outline, isTablet),
          SizedBox(height: isTablet ? 28 : 20),
          _buildToggleRow('Break Reminders', breakRemindersEnabled, (value) {
            setState(() => breakRemindersEnabled = value);
          }, isTablet),
          if (breakRemindersEnabled) ...[
            SizedBox(height: isTablet ? 24 : 16),
            _buildSlider('Reminder Interval (minutes)', breakInterval, 15, 120,
                (value) {
              setState(() => breakInterval = value.round());
            }, isTablet),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'Quick Actions', Icons.flash_on_outlined, isTablet),
          SizedBox(height: isTablet ? 28 : 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    _buildActionButton('Reset Today', Icons.refresh, () {
                      _showResetDialog();
                    }, isTablet),
                    SizedBox(height: isTablet ? 20 : 16),
                    _buildActionButton('View Stats', Icons.analytics, () {
                      Get.snackbar('Stats', 'Opening usage statistics...');
                    }, isTablet),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child:
                          _buildActionButton('Reset Today', Icons.refresh, () {
                        _showResetDialog();
                      }, isTablet),
                    ),
                    SizedBox(width: isTablet ? 20 : 16),
                    Expanded(
                      child:
                          _buildActionButton('View Stats', Icons.analytics, () {
                        Get.snackbar('Stats', 'Opening usage statistics...');
                      }, isTablet),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String label, int value, int min, int max,
      Function(int) onChanged, bool isTablet) {
    final pickerWidth = isTablet ? 100.0 : 80.0;
    final pickerHeight = isTablet ? 140.0 : 120.0;
    final itemExtent = isTablet ? 40.0 : 32.0;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isTablet ? 14 : 12,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Container(
          width: pickerWidth,
          height: pickerHeight,
          decoration: BoxDecoration(
            color: AppColors.containerBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: CupertinoPicker(
            itemExtent: itemExtent,
            scrollController: FixedExtentScrollController(initialItem: value),
            onSelectedItemChanged: onChanged,
            children: List.generate(max - min + 1, (index) {
              return Center(
                child: Text(
                  (min + index).toString().padLeft(2, '0'),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: isTablet ? 20 : 18,
                  ),
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

// Responsive Language Screen
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final horizontalPadding = isTablet ? 48.0 : 20.0;

            return Column(
              children: [
                _buildResponsiveAppBar('Language Settings', isTablet),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 600 : double.infinity,
                      ),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 16,
                        ),
                        itemCount: languages.length,
                        itemBuilder: (context, index) {
                          final language = languages[index];
                          final isSelected =
                              language['name'] == selectedLanguage;

                          return Container(
                            margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
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
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 24 : 20,
                                vertical: isTablet ? 12 : 8,
                              ),
                              leading: Text(
                                language['flag']!,
                                style: TextStyle(fontSize: isTablet ? 28 : 24),
                              ),
                              title: Text(
                                language['name']!,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.buttonPrimary
                                      : AppColors.textPrimary,
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: AppColors.buttonPrimary,
                                      size: isTablet ? 24 : 20,
                                    )
                                  : null,
                              onTap: () {
                                setState(
                                    () => selectedLanguage = language['name']!);
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
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Responsive Theme Screen
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final horizontalPadding = isTablet ? 48.0 : 20.0;

            return Column(
              children: [
                _buildResponsiveAppBar('Theme Settings', isTablet),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 800 : double.infinity,
                        ),
                        child: Column(
                          children: [
                            _buildThemeSelector(isTablet),
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildCustomizationCard(isTablet),
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPreviewCard(isTablet),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemeSelector(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Choose Theme', Icons.palette_outlined, isTablet),
          SizedBox(height: isTablet ? 28 : 20),
          ...themes.map((theme) {
            final isSelected = theme['name'] == selectedTheme;
            return Container(
              margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
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
                contentPadding: EdgeInsets.all(isTablet ? 16 : 12),
                leading: Icon(
                  theme['icon'],
                  color: theme['color'],
                  size: isTablet ? 28 : 24,
                ),
                title: Text(
                  theme['name'],
                  style: TextStyle(
                    color: isSelected ? theme['color'] : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: theme['color'],
                        size: isTablet ? 24 : 20,
                      )
                    : null,
                onTap: () => setState(() => selectedTheme = theme['name']),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomizationCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Customization', Icons.tune_outlined, isTablet),
          SizedBox(height: isTablet ? 28 : 20),
          _buildToggleRow('Adaptive Theme', adaptiveTheme, (value) {
            setState(() => adaptiveTheme = value);
          }, isTablet),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Preview', Icons.preview_outlined, isTablet),
          SizedBox(height: isTablet ? 28 : 20),
          Container(
            width: double.infinity,
            height: isTablet ? 160 : 120,
            decoration: BoxDecoration(
              gradient: AppColors.backgroundGradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Center(
              child: Text(
                'Theme Preview',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: isTablet ? 20 : 16,
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

// Responsive Help Screen
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final horizontalPadding = isTablet ? 48.0 : 20.0;

            return Column(
              children: [
                _buildResponsiveAppBar('Help & FAQ', isTablet),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 800 : double.infinity,
                        ),
                        child: Column(
                          children: [
                            _buildSearchBar(isTablet),
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildQuickHelpCard(isTablet),
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildFAQSection(isTablet),
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildContactCard(isTablet),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isTablet) {
    return Container(
      decoration: _cardDecoration(),
      child: TextField(
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: isTablet ? 16 : 14,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.iconSecondary,
            size: isTablet ? 24 : 20,
          ),
          hintText: 'Search for help...',
          hintStyle: TextStyle(
            color: AppColors.textMuted,
            fontSize: isTablet ? 16 : 14,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(isTablet ? 24 : 20),
        ),
      ),
    );
  }

  Widget _buildQuickHelpCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildSectionHeader('Quick Help', Icons.help_outline, isTablet),
          SizedBox(height: isTablet ? 28 : 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    _buildHelpAction(
                        'Tutorial', Icons.play_circle_outline, isTablet),
                    SizedBox(height: isTablet ? 20 : 16),
                    _buildHelpAction('Guide', Icons.book_outlined, isTablet),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: _buildHelpAction(
                          'Tutorial', Icons.play_circle_outline, isTablet),
                    ),
                    SizedBox(width: isTablet ? 20 : 16),
                    Expanded(
                      child: _buildHelpAction(
                          'Guide', Icons.book_outlined, isTablet),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHelpAction(String title, IconData icon, bool isTablet) {
    return GestureDetector(
      onTap: () => Get.snackbar('Help', 'Opening $title...'),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: AppColors.buttonPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.buttonPrimary,
              size: isTablet ? 40 : 32,
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection(bool isTablet) {
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
            padding: EdgeInsets.all(isTablet ? 32 : 24),
            child: _buildSectionHeader(
                'Frequently Asked Questions', Icons.quiz_outlined, isTablet),
          ),
          ...faqs.map((faq) => ExpansionTile(
                tilePadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 24,
                  vertical: isTablet ? 8 : 4,
                ),
                title: Text(
                  faq['q']!,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isTablet ? 32 : 16,
                      0,
                      isTablet ? 32 : 16,
                      isTablet ? 24 : 16,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        faq['a']!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: isTablet ? 14 : 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildContactCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildSectionHeader(
              'Need More Help?', Icons.support_agent_outlined, isTablet),
          SizedBox(height: isTablet ? 28 : 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    _buildActionButton('Email Support', Icons.email, () {
                      Get.snackbar('Support', 'Opening email client...');
                    }, isTablet),
                    SizedBox(height: isTablet ? 20 : 16),
                    _buildActionButton('Live Chat', Icons.chat, () {
                      Get.snackbar('Chat', 'Opening live chat...');
                    }, isTablet),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child:
                          _buildActionButton('Email Support', Icons.email, () {
                        Get.snackbar('Support', 'Opening email client...');
                      }, isTablet),
                    ),
                    SizedBox(width: isTablet ? 20 : 16),
                    Expanded(
                      child: _buildActionButton('Live Chat', Icons.chat, () {
                        Get.snackbar('Chat', 'Opening live chat...');
                      }, isTablet),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// Responsive Backup Screen
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final horizontalPadding = isTablet ? 48.0 : 20.0;

            return Column(
              children: [
                _buildResponsiveAppBar('Backup & Restore', isTablet),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 600 : double.infinity,
                        ),
                        child: Column(
                          children: [
                            _buildBackupStatusCard(isTablet),
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildBackupActionsCard(isTablet),
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildSettingsCard(isTablet),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackupStatusCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: isTablet ? 80 : 60,
            height: isTablet ? 80 : 60,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isTablet ? 40 : 30),
            ),
            child: Icon(
              Icons.cloud_done,
              color: AppColors.success,
              size: isTablet ? 40 : 30,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'Backup Status',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'Last backup: $lastBackup',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isTablet ? 16 : 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Size: $backupSize',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isTablet ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupActionsCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildSectionHeader(
              'Backup Actions', Icons.backup_outlined, isTablet),
          SizedBox(height: isTablet ? 28 : 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    _buildActionButton('Backup Now', Icons.cloud_upload, () {
                      Get.snackbar('Backup', 'Creating backup...');
                    }, isTablet),
                    SizedBox(height: isTablet ? 20 : 16),
                    _buildActionButton('Restore', Icons.cloud_download, () {
                      _showRestoreDialog();
                    }, isTablet),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                          'Backup Now', Icons.cloud_upload, () {
                        Get.snackbar('Backup', 'Creating backup...');
                      }, isTablet),
                    ),
                    SizedBox(width: isTablet ? 20 : 16),
                    Expanded(
                      child: _buildActionButton('Restore', Icons.cloud_download,
                          () {
                        _showRestoreDialog();
                      }, isTablet),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'Backup Settings', Icons.settings_outlined, isTablet),
          SizedBox(height: isTablet ? 28 : 20),
          _buildToggleRow('Auto Backup', autoBackup, (value) {
            setState(() => autoBackup = value);
          }, isTablet),
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

// Responsive Privacy Screen
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final horizontalPadding = isTablet ? 48.0 : 20.0;

            return Column(
              children: [
                _buildResponsiveAppBar('Privacy Settings', isTablet),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 800 : double.infinity,
                        ),
                        child: Column(
                          children: [
                            _buildPrivacyOverviewCard(isTablet),
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildDataCollectionCard(isTablet),
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildPermissionsCard(isTablet),
                            SizedBox(height: isTablet ? 32 : 24),
                            _buildDataControlCard(isTablet),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPrivacyOverviewCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: isTablet ? 80 : 60,
            height: isTablet ? 80 : 60,
            decoration: BoxDecoration(
              color: AppColors.buttonPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isTablet ? 40 : 30),
            ),
            child: Icon(
              Icons.security,
              color: AppColors.buttonPrimary,
              size: isTablet ? 40 : 30,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'Your Privacy Matters',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'We are committed to protecting your privacy and keeping your data secure.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: isTablet ? 16 : 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDataCollectionCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'Data Collection', Icons.data_usage_outlined, isTablet),
          SizedBox(height: isTablet ? 28 : 20),
          _buildToggleRow('Usage Analytics', analyticsEnabled, (value) {
            setState(() => analyticsEnabled = value);
          }, isTablet),
          SizedBox(height: isTablet ? 16 : 12),
          _buildToggleRow('Crash Reports', crashReportsEnabled, (value) {
            setState(() => crashReportsEnabled = value);
          }, isTablet),
          SizedBox(height: isTablet ? 16 : 12),
          _buildToggleRow('Personalized Ads', personalizedAds, (value) {
            setState(() => personalizedAds = value);
          }, isTablet),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'App Permissions', Icons.admin_panel_settings_outlined, isTablet),
          SizedBox(height: isTablet ? 28 : 20),
          _buildPermissionItem(
              'Usage Access', 'Required for app blocking', true, isTablet),
          _buildPermissionItem(
              'Notifications', 'For alerts and reminders', true, isTablet),
          _buildPermissionItem(
              'Camera', 'For profile pictures', false, isTablet),
          _buildPermissionItem(
              'Storage', 'For backup and restore', false, isTablet),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(
      String title, String description, bool granted, bool isTablet) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? AppColors.success : AppColors.error,
            size: isTablet ? 24 : 20,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: isTablet ? 14 : 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataControlCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              'Data Control', Icons.manage_accounts_outlined, isTablet),
          SizedBox(height: isTablet ? 28 : 20),
          _buildActionButton('View Privacy Policy', Icons.description, () {
            Get.snackbar('Privacy Policy', 'Opening privacy policy...');
          }, isTablet),
          SizedBox(height: isTablet ? 20 : 16),
          _buildActionButton('Export My Data', Icons.download, () {
            Get.snackbar('Export', 'Preparing data export...');
          }, isTablet),
          SizedBox(height: isTablet ? 20 : 16),
          _buildActionButton('Delete My Data', Icons.delete_forever, () {
            _showDeleteDataDialog();
          }, isTablet),
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

// Shared responsive widgets and utilities
Widget _buildResponsiveAppBar(String title, bool isTablet) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: isTablet ? 24 : 16,
      vertical: isTablet ? 16 : 12,
    ),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: AppColors.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Get.back(),
          icon: Container(
            width: isTablet ? 40 : 32,
            height: isTablet ? 40 : 32,
            decoration: BoxDecoration(
              color: AppColors.containerBackground,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.iconPrimary,
              size: isTablet ? 20 : 16,
            ),
          ),
        ),
        SizedBox(width: isTablet ? 16 : 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
        offset: const Offset(0, 8),
      )
    ],
  );
}

Widget _buildSectionHeader(String title, IconData icon, bool isTablet) {
  return Row(
    children: [
      Container(
        width: isTablet ? 48 : 40,
        height: isTablet ? 48 : 40,
        decoration: BoxDecoration(
          color: AppColors.buttonPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: AppColors.buttonPrimary,
          size: isTablet ? 24 : 20,
        ),
      ),
      SizedBox(width: isTablet ? 20 : 16),
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

Widget _buildToggleRow(
    String title, bool value, Function(bool) onChanged, bool isTablet) {
  return Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: isTablet ? 18 : 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(width: 16),
      Transform.scale(
        scale: isTablet ? 1.2 : 1.0,
        child: CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.buttonPrimary,
        ),
      ),
    ],
  );
}

Widget _buildSlider(String title, int value, int min, int max,
    Function(double) onChanged, bool isTablet) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: isTablet ? 18 : 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12 : 8,
              vertical: isTablet ? 6 : 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.buttonPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$value',
              style: TextStyle(
                color: AppColors.buttonPrimary,
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: isTablet ? 12 : 8),
      SliderTheme(
        data: SliderTheme.of(Get.context!).copyWith(
          trackHeight: isTablet ? 6 : 4,
          thumbShape: RoundSliderThumbShape(
            enabledThumbRadius: isTablet ? 12 : 10,
          ),
        ),
        child: Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          activeColor: AppColors.buttonPrimary,
          inactiveColor: AppColors.containerBackground,
          onChanged: onChanged,
        ),
      ),
    ],
  );
}

Widget _buildActionButton(
    String title, IconData icon, VoidCallback onTap, bool isTablet) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.buttonPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.buttonPrimary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.buttonPrimary,
            size: isTablet ? 24 : 20,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.buttonPrimary,
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 16 : 14,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}
