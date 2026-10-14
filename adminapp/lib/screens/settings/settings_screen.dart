import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/brand_button.dart';
import '../../widgets/brand_card.dart';

/// Settings tab screen for the Slice & Serve Admin application.
///
/// Implements `PRD.md` §3.8 (A-41, A-42, A-43, A-44) and `TASKS.md` Tasks 5A-1, 5A-2, 5A-3:
/// - Three sections in order: **Theme**, **About**, **Report a Bug**
/// - Section 1: Real interactive theme picker (Light / Dark / System, default Light)
/// - Section 2: Real About section with runtime version display from [PackageInfo],
///   shop/app description, and static "Check for update" placeholder
/// - Section 3: Report a Bug scaffold (Task 5A-4 next)
/// - Brand-styled rows using [BrandCard] with tactile press feedback and spring motion
/// - Proper spacing conforming to `DESIGN_TOKENS.md` and `polished-flutter-ui`
/// - Full light and dark mode support
class SettingsScreen extends StatefulWidget {
  /// When true, renders a standalone [AppBar] with the "Settings" title.
  /// Defaults to false when hosted inside `MainShell`, which already provides the top AppBar.
  final bool showAppBar;
  final ThemeController? controller;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final VoidCallback? onThemeTap;
  final VoidCallback? onAboutTap;
  final VoidCallback? onReportBugTap;

  /// Optional dependency injection for testing or early-loaded package info.
  final PackageInfo? packageInfo;

  /// Whether the About card is expanded on initial render.
  final bool initialAboutExpanded;

  /// Whether the Report a Bug card is expanded on initial render.
  final bool initialReportBugExpanded;

  /// The developer or support contact email displayed in the Report a Bug section.
  final String contactEmail;

  const SettingsScreen({
    super.key,
    this.showAppBar = false,
    this.controller,
    this.onThemeModeChanged,
    this.onThemeTap,
    this.onAboutTap,
    this.onReportBugTap,
    this.packageInfo,
    this.initialAboutExpanded = false,
    this.initialReportBugExpanded = false,
    this.contactEmail = 'smrutiprakashrout3@gmail.com',
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _aboutExpanded;
  late bool _reportBugExpanded;
  String? _updateMessage;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _aboutExpanded = widget.initialAboutExpanded;
    _reportBugExpanded = widget.initialReportBugExpanded;
    _packageInfo = widget.packageInfo;
    if (_packageInfo == null) {
      _loadPackageInfo();
    }
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _packageInfo = info;
        });
      }
    } catch (_) {
      // Graceful fallback for headless test environments
    }
  }

  String get _versionString {
    if (_packageInfo == null) {
      return 'Version loading...';
    }
    final version = _packageInfo!.version;
    final build = _packageInfo!.buildNumber;
    return build.isNotEmpty ? 'Version $version (build $build)' : 'Version $version';
  }

  void _toggleAbout() {
    HapticFeedback.selectionClick();
    setState(() {
      _aboutExpanded = !_aboutExpanded;
    });
    widget.onAboutTap?.call();
  }

  void _handleCheckForUpdate() {
    HapticFeedback.selectionClick();
    setState(() {
      _updateMessage = "You're on the latest version.";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("You're on the latest version."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleReportBug() {
    HapticFeedback.selectionClick();
    setState(() {
      _reportBugExpanded = !_reportBugExpanded;
    });
    widget.onReportBugTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final themeCtrl = widget.controller ?? ThemeController.instance;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final body = SafeArea(
      child: ListenableBuilder(
        listenable: themeCtrl,
        builder: (context, _) {
          final currentMode = themeCtrl.themeMode;

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space5,
              vertical: AppTokens.space4,
            ),
            children: [
              // Section 1: Theme (Task 5A-2)
              BrandCard(
                key: const Key('settings_section_theme'),
                radius: BrandCardRadius.large,
                padding: const EdgeInsets.all(AppTokens.space4),
                onTap: widget.onThemeTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: Icon, Title, Subtitle
                    Row(
                      children: [
                        _buildIconContainer(
                          theme: theme,
                          icon: Icons.palette_outlined,
                        ),
                        const SizedBox(width: AppTokens.space4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Theme',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: theme.brandInk,
                                ),
                              ),
                              const SizedBox(height: AppTokens.space1 / 2),
                              Text(
                                'App appearance',
                                style: AppTypography.labelCaption(
                                  color: theme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space4),

                    // Segmented Theme Picker: Light / Dark / System
                    _buildThemeSegmentedPicker(
                      theme: theme,
                      currentMode: currentMode,
                      onSelect: (mode) {
                        themeCtrl.setThemeMode(mode);
                        widget.onThemeModeChanged?.call(mode);
                        widget.onThemeTap?.call();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.space3),

              // Section 2: About (Task 5A-3)
              BrandCard(
                key: const Key('settings_section_about'),
                radius: BrandCardRadius.large,
                padding: const EdgeInsets.all(AppTokens.space4),
                onTap: _aboutExpanded ? null : _toggleAbout,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _aboutExpanded ? _toggleAbout : null,
                      child: Row(
                        children: [
                          _buildIconContainer(
                            theme: theme,
                            icon: Icons.info_outline_rounded,
                          ),
                          const SizedBox(width: AppTokens.space4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: theme.brandInk,
                                  ),
                                ),
                                const SizedBox(height: AppTokens.space1 / 2),
                                Text(
                                  'Version & shop details',
                                  style: AppTypography.labelCaption(
                                    color: theme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTokens.space3),
                          AnimatedRotation(
                            turns: _aboutExpanded ? 0.25 : 0.0,
                            duration: reduceMotion
                                ? Duration.zero
                                : AppTokens.motionMicro,
                            curve: AppTokens.curveEnter,
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: theme.textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Expandable real content per Task 5A-3
                    AnimatedSize(
                      duration: reduceMotion
                          ? Duration.zero
                          : AppTokens.motionStandard,
                      curve: AppTokens.curveSpring,
                      child: _aboutExpanded
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: AppTokens.space4),
                                Divider(color: theme.divider),
                                const SizedBox(height: AppTokens.space3),

                                // App title & static description
                                Text(
                                  'Slice and Serve Admin',
                                  key: const Key('settings_about_app_name'),
                                  style: AppTypography.sectionHeader(
                                    color: theme.brandInk,
                                  ),
                                ),
                                const SizedBox(height: AppTokens.space1),
                                Text(
                                  "Manage your shop's menu, loyalty program, and kitchen orders.",
                                  key: const Key('settings_about_description'),
                                  style: AppTypography.body(
                                    color: theme.textSecondary,
                                  ).copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: AppTokens.space3),

                                // Installed version display from package_info_plus
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTokens.space3,
                                    vertical: AppTokens.space2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.surfaceCreamAlt,
                                    borderRadius: AppTokens.borderRadiusMedium,
                                    border: Border.all(
                                      color: theme.divider,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_outlined,
                                        size: 16,
                                        color: theme.brandInk,
                                      ),
                                      const SizedBox(width: AppTokens.space2),
                                      Text(
                                        _versionString,
                                        key: const Key('settings_version_text'),
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: theme.brandInk,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppTokens.space4),

                                // Static "Check for update" button (v1 placeholder)
                                BrandButton.outlined(
                                  key: const Key(
                                      'settings_check_update_button'),
                                  text: 'Check for update',
                                  icon: Icons.refresh_rounded,
                                  height: 48,
                                  onPressed: _handleCheckForUpdate,
                                ),

                                // Inline confirmation message after checking
                                if (_updateMessage != null) ...[
                                  const SizedBox(height: AppTokens.space3),
                                  Container(
                                    key: const Key('settings_update_message'),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTokens.space3,
                                      vertical: AppTokens.space2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.successBackground,
                                      borderRadius:
                                          AppTokens.borderRadiusSmall,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 16,
                                          color: theme.success,
                                        ),
                                        const SizedBox(
                                            width: AppTokens.space2),
                                        Expanded(
                                          child: Text(
                                            _updateMessage!,
                                            style: GoogleFonts.inter(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: theme.success,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.space3),

              // Section 3: Report a Bug (Task 5A-4)
              BrandCard(
                key: const Key('settings_section_report_bug'),
                radius: BrandCardRadius.large,
                padding: const EdgeInsets.all(AppTokens.space4),
                onTap: _reportBugExpanded ? null : _toggleReportBug,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _reportBugExpanded ? _toggleReportBug : null,
                      child: Row(
                        children: [
                          _buildIconContainer(
                            theme: theme,
                            icon: Icons.bug_report_outlined,
                          ),
                          const SizedBox(width: AppTokens.space4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Report a Bug',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: theme.brandInk,
                                  ),
                                ),
                                const SizedBox(height: AppTokens.space1 / 2),
                                Text(
                                  'Support & contact info',
                                  style: AppTypography.labelCaption(
                                    color: theme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTokens.space3),
                          AnimatedRotation(
                            turns: _reportBugExpanded ? 0.25 : 0.0,
                            duration: reduceMotion
                                ? Duration.zero
                                : AppTokens.motionMicro,
                            curve: AppTokens.curveEnter,
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: theme.textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Expandable real content per Task 5A-4
                    AnimatedSize(
                      duration: reduceMotion
                          ? Duration.zero
                          : AppTokens.motionStandard,
                      curve: AppTokens.curveSpring,
                      child: _reportBugExpanded
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: AppTokens.space4),
                                Divider(color: theme.divider),
                                const SizedBox(height: AppTokens.space3),

                                // Title & static description
                                Text(
                                  'Found an Issue?',
                                  key: const Key('settings_report_bug_title'),
                                  style: AppTypography.screenTitle(
                                    color: theme.brandInk,
                                  ).copyWith(fontSize: 17),
                                ),
                                const SizedBox(height: AppTokens.space2),
                                Text(
                                  'If you encounter a bug, UI glitch, or unexpected behavior in the admin app, please reach out to developer support directly:',
                                  key: const Key('settings_report_bug_description'),
                                  style: AppTypography.body(
                                    color: theme.textSecondary,
                                  ).copyWith(fontSize: 13, height: 1.4),
                                ),
                                const SizedBox(height: AppTokens.space4),

                                // Contact info card
                                Container(
                                  key: const Key('settings_contact_card'),
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AppTokens.space4),
                                  decoration: BoxDecoration(
                                    color: theme.surfaceCreamAlt,
                                    borderRadius: AppTokens.borderRadiusMedium,
                                    border: Border.all(
                                      color: theme.divider,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.alternate_email_rounded,
                                            size: 18,
                                            color: theme.brandInk,
                                          ),
                                          const SizedBox(width: AppTokens.space2),
                                          Text(
                                            'Developer Contact',
                                            style: AppTypography.labelCaption(
                                              color: theme.textSecondary,
                                            ).copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppTokens.space2),
                                      SelectableText(
                                        widget.contactEmail,
                                        key: const Key('settings_contact_email'),
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: theme.brandInk,
                                        ),
                                      ),
                                      const SizedBox(height: AppTokens.space3),
                                      Divider(color: theme.divider.withValues(alpha: 0.15)),
                                      const SizedBox(height: AppTokens.space2),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            size: 15,
                                            color: theme.textSecondary,
                                          ),
                                          const SizedBox(width: AppTokens.space2),
                                          Expanded(
                                            child: Text(
                                              'Please include steps to reproduce, build version (${_packageInfo?.version ?? '1.0.0'}), and screenshots if applicable.',
                                              key: const Key('settings_contact_hint'),
                                              style: AppTypography.labelCaption(
                                                color: theme.textSecondary,
                                              ).copyWith(fontSize: 12, height: 1.3),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // Debug notification testing tools (Task Push-3 verification)
              if (kDebugMode) ...[
                const SizedBox(height: AppTokens.space4),
                BrandCard(
                  key: const Key('settings_debug_notifications_card'),
                  padding: const EdgeInsets.all(AppTokens.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 20,
                            color: theme.brandInk,
                          ),
                          const SizedBox(width: AppTokens.space2),
                          Text(
                            'Push Notification Test (Debug)',
                            style: AppTypography.sectionHeader(
                              color: theme.brandInk,
                            ).copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTokens.space3),
                      BrandButton(
                        key: const Key('settings_debug_trigger_fg_button'),
                        text: 'Test In-App Foreground Banner',
                        icon: Icons.notifications_none_rounded,
                        height: 48,
                        onPressed: () {
                          NotificationService.triggerForegroundTest(
                            title: 'New Order #1042',
                            body: 'Dine-In • Table 3 • 2 items • ₹280',
                          );
                        },
                      ),
                      const SizedBox(height: AppTokens.space2),
                      BrandButton.outlined(
                        key: const Key('settings_debug_trigger_bg_button'),
                        text: 'Trigger System Push in 5s',
                        icon: Icons.timer_outlined,
                        height: 48,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Press HOME now! Notification arrives in 5 seconds...'),
                              duration: Duration(seconds: 4),
                            ),
                          );
                          Future.delayed(const Duration(seconds: 5), () {
                            NotificationService.triggerBackgroundTest(
                              title: 'New Order #1043',
                              body: 'Takeaway • 1 item • ₹150',
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: Text(
            'Settings',
            style: AppTypography.screenTitle(color: theme.brandInk).copyWith(
              fontSize: 22,
            ),
          ),
        ),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: body,
    );
  }

  /// Segmented control container with 3 segments: Light, Dark, System.
  Widget _buildThemeSegmentedPicker({
    required AppThemeExtension theme,
    required ThemeMode currentMode,
    required ValueChanged<ThemeMode> onSelect,
  }) {
    return Container(
      key: const Key('settings_theme_segmented_control'),
      height: 48,
      padding: const EdgeInsets.all(AppTokens.space1),
      decoration: BoxDecoration(
        color: theme.surfaceCreamAlt,
        borderRadius: AppTokens.borderRadiusPill,
        border: Border.all(
          color: theme.divider,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ThemeSegmentButton(
              key: const Key('settings_theme_light'),
              label: 'Light',
              icon: Icons.light_mode_rounded,
              isSelected: currentMode == ThemeMode.light,
              onTap: () {
                if (currentMode != ThemeMode.light) {
                  HapticFeedback.selectionClick();
                  onSelect(ThemeMode.light);
                }
              },
            ),
          ),
          const SizedBox(width: AppTokens.space1),
          Expanded(
            child: _ThemeSegmentButton(
              key: const Key('settings_theme_dark'),
              label: 'Dark',
              icon: Icons.dark_mode_rounded,
              isSelected: currentMode == ThemeMode.dark,
              onTap: () {
                if (currentMode != ThemeMode.dark) {
                  HapticFeedback.selectionClick();
                  onSelect(ThemeMode.dark);
                }
              },
            ),
          ),
          const SizedBox(width: AppTokens.space1),
          Expanded(
            child: _ThemeSegmentButton(
              key: const Key('settings_theme_system'),
              label: 'System',
              icon: Icons.brightness_auto_rounded,
              isSelected: currentMode == ThemeMode.system,
              onTap: () {
                if (currentMode != ThemeMode.system) {
                  HapticFeedback.selectionClick();
                  onSelect(ThemeMode.system);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconContainer({
    required AppThemeExtension theme,
    required IconData icon,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.surfaceCreamAlt,
        borderRadius: AppTokens.borderRadiusMedium,
      ),
      child: Icon(
        icon,
        color: theme.brandInk,
        size: 22,
      ),
    );
  }
}

/// Brand-styled pill segment button for the Theme picker.
class _ThemeSegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeSegmentButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label theme mode',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          onTap: onTap,
          child: AnimatedContainer(
            duration: reduceMotion ? Duration.zero : AppTokens.motionMicro,
            curve: AppTokens.curveSpring,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? theme.brandHighlight : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? AppTokens.brandInk : theme.textSecondary,
                ),
                const SizedBox(width: AppTokens.space1),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isSelected ? AppTokens.brandInk : theme.textSecondary,
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
