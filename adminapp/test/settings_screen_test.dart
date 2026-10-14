import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adminapp/screens/settings/settings_screen.dart';
import 'package:adminapp/theme/app_theme.dart';
import 'package:adminapp/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeController testController;
  final testPackageInfo = PackageInfo(
    appName: 'Slice and Serve Admin',
    packageName: 'com.example.adminapp',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    testController = ThemeController.scoped(initialMode: ThemeMode.light);
  });

  Widget buildTestSettingsScreen({
    ThemeMode themeMode = ThemeMode.light,
    ThemeController? controller,
    bool showAppBar = false,
    ValueChanged<ThemeMode>? onThemeModeChanged,
    VoidCallback? onThemeTap,
    VoidCallback? onAboutTap,
    VoidCallback? onReportBugTap,
    PackageInfo? packageInfo,
    bool initialAboutExpanded = false,
    bool initialReportBugExpanded = false,
    String contactEmail = 'smrutiprakashrout3@gmail.com',
  }) {
    return MaterialApp(
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: SettingsScreen(
        controller: controller ?? testController,
        showAppBar: showAppBar,
        onThemeModeChanged: onThemeModeChanged,
        onThemeTap: onThemeTap,
        onAboutTap: onAboutTap,
        onReportBugTap: onReportBugTap,
        packageInfo: packageInfo ?? testPackageInfo,
        initialAboutExpanded: initialAboutExpanded,
        initialReportBugExpanded: initialReportBugExpanded,
        contactEmail: contactEmail,
      ),
    );
  }

  group('SettingsScreen Widget Tests (Tasks 5A-1, 5A-2, 5A-3)', () {
    testWidgets(
        'Renders three sections in exact order: Theme, About, Report a Bug',
        (tester) async {
      await tester.pumpWidget(buildTestSettingsScreen());
      await tester.pumpAndSettle();

      // Check section keys exist
      final themeFinder = find.byKey(const Key('settings_section_theme'));
      final aboutFinder = find.byKey(const Key('settings_section_about'));
      final reportBugFinder =
          find.byKey(const Key('settings_section_report_bug'));

      expect(themeFinder, findsOneWidget);
      expect(aboutFinder, findsOneWidget);
      expect(reportBugFinder, findsOneWidget);

      // Verify vertical ordering (Theme above About, About above Report a Bug)
      final themeTop = tester.getTopLeft(themeFinder).dy;
      final aboutTop = tester.getTopLeft(aboutFinder).dy;
      final reportBugTop = tester.getTopLeft(reportBugFinder).dy;

      expect(themeTop, lessThan(aboutTop));
      expect(aboutTop, lessThan(reportBugTop));

      // Check titles
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Report a Bug'), findsOneWidget);

      // Check subtitles
      expect(find.text('App appearance'), findsOneWidget);
      expect(find.text('Version & shop details'), findsOneWidget);
      expect(find.text('Support & contact info'), findsOneWidget);
    });

    testWidgets(
        'Theme picker renders 3 segments: Light, Dark, System; defaults to Light',
        (tester) async {
      await tester.pumpWidget(buildTestSettingsScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_theme_segmented_control')),
          findsOneWidget);
      expect(find.byKey(const Key('settings_theme_light')), findsOneWidget);
      expect(find.byKey(const Key('settings_theme_dark')), findsOneWidget);
      expect(find.byKey(const Key('settings_theme_system')), findsOneWidget);

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);

      // Verify initial active mode is Light
      expect(testController.themeMode, equals(ThemeMode.light));
    });

    testWidgets(
        'Tapping Dark segment immediately updates ThemeController and invokes callback',
        (tester) async {
      ThemeMode? selectedMode;

      await tester.pumpWidget(
        buildTestSettingsScreen(
          onThemeModeChanged: (mode) => selectedMode = mode,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Dark
      await tester.tap(find.byKey(const Key('settings_theme_dark')));
      await tester.pumpAndSettle();

      expect(selectedMode, equals(ThemeMode.dark));
      expect(testController.themeMode, equals(ThemeMode.dark));
    });

    testWidgets(
        'Tapping System segment updates ThemeController to System',
        (tester) async {
      ThemeMode? selectedMode;

      await tester.pumpWidget(
        buildTestSettingsScreen(
          onThemeModeChanged: (mode) => selectedMode = mode,
        ),
      );
      await tester.pumpAndSettle();

      // Tap System
      await tester.tap(find.byKey(const Key('settings_theme_system')));
      await tester.pumpAndSettle();

      expect(selectedMode, equals(ThemeMode.system));
      expect(testController.themeMode, equals(ThemeMode.system));
    });

    testWidgets(
        'Tapping Light segment after Dark updates ThemeController back to Light',
        (tester) async {
      testController.setThemeMode(ThemeMode.dark);

      await tester.pumpWidget(buildTestSettingsScreen());
      await tester.pumpAndSettle();

      expect(testController.themeMode, equals(ThemeMode.dark));

      // Tap Light
      await tester.tap(find.byKey(const Key('settings_theme_light')));
      await tester.pumpAndSettle();

      expect(testController.themeMode, equals(ThemeMode.light));
    });

    testWidgets(
        'About section starts collapsed and expands when tapped (Task 5A-3)',
        (tester) async {
      var aboutTapped = false;

      await tester.pumpWidget(
        buildTestSettingsScreen(
          onAboutTap: () => aboutTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      // Initially collapsed: expanded content not present
      expect(find.byKey(const Key('settings_about_app_name')), findsNothing);
      expect(find.byKey(const Key('settings_version_text')), findsNothing);
      expect(
          find.byKey(const Key('settings_check_update_button')), findsNothing);

      // Tap About card
      await tester.tap(find.byKey(const Key('settings_section_about')));
      await tester.pumpAndSettle();

      expect(aboutTapped, isTrue);

      // Now expanded: content is revealed
      expect(find.byKey(const Key('settings_about_app_name')), findsOneWidget);
      expect(find.text('Slice and Serve Admin'), findsOneWidget);
      expect(
        find.text(
            "Manage your shop's menu, loyalty program, and kitchen orders."),
        findsOneWidget,
      );
      expect(find.byKey(const Key('settings_version_text')), findsOneWidget);
      expect(find.text('Version 1.0.0 (build 1)'), findsOneWidget);
      expect(
          find.byKey(const Key('settings_check_update_button')), findsOneWidget);
    });

    testWidgets(
        'Tapping Check for update shows static placeholder message (Task 5A-3)',
        (tester) async {
      await tester.pumpWidget(
        buildTestSettingsScreen(initialAboutExpanded: true),
      );
      await tester.pumpAndSettle();

      // Verify button exists and no message yet
      final checkButton = find.byKey(const Key('settings_check_update_button'));
      expect(checkButton, findsOneWidget);
      expect(find.byKey(const Key('settings_update_message')), findsNothing);

      // Tap Check for update
      await tester.tap(checkButton);
      await tester.pumpAndSettle();

      // Confirms message is displayed
      expect(find.byKey(const Key('settings_update_message')), findsOneWidget);
      expect(find.text("You're on the latest version."), findsWidgets);
    });

    testWidgets(
        'Version display reads custom PackageInfo dynamically (Task 5A-3)',
        (tester) async {
      final customPackageInfo = PackageInfo(
        appName: 'Slice and Serve Admin',
        packageName: 'com.example.adminapp',
        version: '2.4.1',
        buildNumber: '42',
        buildSignature: '',
      );

      await tester.pumpWidget(
        buildTestSettingsScreen(
          packageInfo: customPackageInfo,
          initialAboutExpanded: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Version 2.4.1 (build 42)'), findsOneWidget);
    });

    testWidgets(
        'Report a Bug section starts collapsed and expands when tapped (Task 5A-4)',
        (tester) async {
      var reportBugTapped = false;

      await tester.pumpWidget(
        buildTestSettingsScreen(
          onReportBugTap: () => reportBugTapped = true,
        ),
      );
      await tester.pumpAndSettle();

      // Initially collapsed: expanded content not present
      expect(find.byKey(const Key('settings_report_bug_title')), findsNothing);
      expect(find.byKey(const Key('settings_contact_card')), findsNothing);
      expect(find.byKey(const Key('settings_contact_email')), findsNothing);

      // Tap Report a Bug row
      await tester.tap(find.byKey(const Key('settings_section_report_bug')));
      await tester.pumpAndSettle();

      expect(reportBugTapped, isTrue);

      // Now expanded: content is revealed
      expect(find.byKey(const Key('settings_report_bug_title')), findsOneWidget);
      expect(find.text('Found an Issue?'), findsOneWidget);
      expect(find.byKey(const Key('settings_report_bug_description')),
          findsOneWidget);
      expect(find.byKey(const Key('settings_contact_card')), findsOneWidget);
      expect(find.byKey(const Key('settings_contact_email')), findsOneWidget);
      expect(find.text('smrutiprakashrout3@gmail.com'), findsOneWidget);
      expect(find.byKey(const Key('settings_contact_hint')), findsOneWidget);
    });

    testWidgets(
        'Report a Bug renders custom contact email dynamically (Task 5A-4)',
        (tester) async {
      await tester.pumpWidget(
        buildTestSettingsScreen(
          contactEmail: 'custom-support@sliceandserve.com',
          initialReportBugExpanded: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('custom-support@sliceandserve.com'), findsOneWidget);
    });

    testWidgets('Renders properly in Dark Mode', (tester) async {
      testController.setThemeMode(ThemeMode.dark);

      await tester.pumpWidget(
        buildTestSettingsScreen(
          themeMode: ThemeMode.dark,
          initialAboutExpanded: true,
          initialReportBugExpanded: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_section_theme')), findsOneWidget);
      expect(find.byKey(const Key('settings_section_about')), findsOneWidget);
      expect(
          find.byKey(const Key('settings_section_report_bug')), findsOneWidget);
      expect(find.byKey(const Key('settings_theme_dark')), findsOneWidget);
      expect(find.byKey(const Key('settings_version_text')), findsOneWidget);
      expect(find.text('Version 1.0.0 (build 1)'), findsOneWidget);
      expect(find.byKey(const Key('settings_contact_email')), findsOneWidget);
      expect(find.text('smrutiprakashrout3@gmail.com'), findsOneWidget);
    });

    testWidgets('Renders standalone AppBar when showAppBar is true',
        (tester) async {
      await tester.pumpWidget(
        buildTestSettingsScreen(showAppBar: true),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('ThemeController Persistence & Unit Tests (Task 5A-2)', () {
    test('Default mode is Light on first launch (no SharedPreferences saved)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final controller = ThemeController.scoped();
      await controller.init(prefs);

      expect(controller.themeMode, equals(ThemeMode.light));
    });

    test('Initializes with persisted Dark mode if saved in SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({
        ThemeController.prefKey: 'dark',
      });
      final prefs = await SharedPreferences.getInstance();

      final controller = ThemeController.scoped();
      await controller.init(prefs);

      expect(controller.themeMode, equals(ThemeMode.dark));
    });

    test('Initializes with persisted System mode if saved in SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({
        ThemeController.prefKey: 'system',
      });
      final prefs = await SharedPreferences.getInstance();

      final controller = ThemeController.scoped();
      await controller.init(prefs);

      expect(controller.themeMode, equals(ThemeMode.system));
    });

    test('setThemeMode updates state and persists to SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final controller = ThemeController.scoped();
      await controller.init(prefs);

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, equals(ThemeMode.dark));
      expect(prefs.getString(ThemeController.prefKey), equals('dark'));

      await controller.setThemeMode(ThemeMode.system);
      expect(controller.themeMode, equals(ThemeMode.system));
      expect(prefs.getString(ThemeController.prefKey), equals('system'));

      await controller.setThemeMode(ThemeMode.light);
      expect(controller.themeMode, equals(ThemeMode.light));
      expect(prefs.getString(ThemeController.prefKey), equals('light'));
    });
  });
}
