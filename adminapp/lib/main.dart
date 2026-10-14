import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/orders_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/brand_button.dart';
import 'widgets/brand_card.dart';
import 'widgets/confirmation_dialog.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.init();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[main] Firebase.initializeApp() skipped or failed: $e');
  }

  // Push-2: Unconditionally create high-importance notification channel with custom sound
  // BEFORE any notification can arrive (PRD §3.6 A-32).
  await NotificationService.setupNotificationChannel();

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  final ThemeController? controller;

  const AdminApp({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: _AdminAppView(controller: controller),
    );
  }
}

class _AdminAppView extends ConsumerStatefulWidget {
  final ThemeController? controller;

  const _AdminAppView({this.controller});

  @override
  ConsumerState<_AdminAppView> createState() => _AdminAppViewState();
}

class _AdminAppViewState extends ConsumerState<_AdminAppView> {
  StreamSubscription<void>? _unauthorizedSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final client = ref.read(apiClientProvider);
      _unauthorizedSub = client.onUnauthorized.listen((_) {
        ref.invalidate(authProvider);
        appNavigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (context) => LoginScreen(
              onToggleTheme: _toggleTheme,
            ),
          ),
          (route) => false,
        );
      });
      // Push-3: Wire message handlers across foreground, background, and cold start
      _setupNotificationHandlers();
    });
  }

  void _setupNotificationHandlers() {
    final notificationService = ref.read(notificationServiceProvider);

    void onNavigate() {
      navigateToOrdersPending(ref);
    }

    NotificationService.setNotificationResponseHandler(onNavigate);

    notificationService.setupMessageHandlers(
      onNavigateToPendingOrders: onNavigate,
      onShowInAppSignal: (title, body) {
        _showForegroundOrderBanner(title, body);
      },
      onOrderDataReceived: () {
        ref.read(ordersProvider.notifier).refreshOnTabVisit();
        ref.invalidate(pendingOrdersCountProvider);
      },
    );

    unawaited(
      notificationService.checkInitialNotification(
        onNavigateToPendingOrders: onNavigate,
      ),
    );
  }

  void _showForegroundOrderBanner(String title, String body) {
    final messenger = appScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF2C1810),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C1810),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2C1810).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFC043),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: const Color(0xFF2C1810),
          onPressed: () {
            navigateToOrdersPending(ref);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _unauthorizedSub?.cancel();
    super.dispose();
  }

  void _toggleTheme() {
    final themeCtrl = widget.controller ?? ThemeController.instance;
    themeCtrl.toggleTheme(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = widget.controller ?? ThemeController.instance;

    return ListenableBuilder(
      listenable: themeCtrl,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          scaffoldMessengerKey: appScaffoldMessengerKey,
          title: 'Slice and Serve Admin',
          debugShowCheckedModeBanner: false,
          themeMode: themeCtrl.themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: AuthGate(
            onToggleTheme: _toggleTheme,
          ),
        );
      },
    );
  }
}

/// Decides whether to show [MainShell] or [LoginScreen] on cold start and auth state changes.
///
/// Implements `PRD.md` §3.1 (A-4) and `TASKS.md` 1B-2.
class AuthGate extends ConsumerStatefulWidget {
  final VoidCallback onToggleTheme;

  const AuthGate({super.key, required this.onToggleTheme});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool? _hasSession;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final hasSession = await ref.read(authServiceProvider).hasValidSession();
    if (hasSession) {
      unawaited(
        ref.read(notificationServiceProvider).initializeAndRegister(),
      );
    }
    if (mounted) {
      setState(() {
        _hasSession = hasSession;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSession == null) {
      final theme = context.appTheme;
      return Scaffold(
        backgroundColor: theme.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.brandHighlight),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_hasSession!) {
      return MainShell(onToggleTheme: widget.onToggleTheme);
    }

    return LoginScreen(onToggleTheme: widget.onToggleTheme);
  }
}

/// Scratch / debug screen displaying all design tokens from DESIGN_TOKENS.md
/// and testing Task 0-3 shared foundational widgets (BrandButton, BrandCard, ConfirmationDialog).
class ThemeScratchScreen extends StatefulWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onModeChanged;

  const ThemeScratchScreen({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  State<ThemeScratchScreen> createState() => _ThemeScratchScreenState();
}

class _ThemeScratchScreenState extends State<ThemeScratchScreen> {
  bool _switchActive = true;
  bool _isButtonLoading = false;
  int _cardTapCount = 0;
  String? _dialogResult;

  void _triggerLoadingButton() {
    setState(() => _isButtonLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isButtonLoading = false);
      }
    });
  }

  Future<void> _showStandardDialog() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Confirm Order Batch',
      message:
          'Are you sure you want to mark all 3 pending orders as preparing?',
      confirmLabel: 'Confirm Batch',
      cancelLabel: 'Cancel',
      isDestructive: false,
    );
    if (mounted) {
      setState(() {
        _dialogResult = confirmed
            ? 'Standard Dialog: Confirmed'
            : 'Standard Dialog: Cancelled';
      });
    }
  }

  Future<void> _showDestructiveDialog() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Reject Order #SNS-104?',
      message:
          'This will permanently reject Order #SNS-104 and notify the customer. This action cannot be undone.',
      confirmLabel: 'Reject Order',
      cancelLabel: 'Keep Order',
      isDestructive: true,
    );
    if (mounted) {
      setState(() {
        _dialogResult = confirmed
            ? 'Destructive Dialog: Order Rejected'
            : 'Destructive Dialog: Cancelled';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    final textTheme = context.textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Slice and Serve Admin'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppTokens.space4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space3,
                  vertical: AppTokens.space1,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceCream,
                  borderRadius: AppTokens.borderRadiusPill,
                  border: Border.all(color: colors.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      size: 14,
                      color: colors.brandInk,
                    ),
                    const SizedBox(width: AppTokens.space1),
                    Text(
                      isDark ? 'Dark Mode' : 'Light Mode',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.brandInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space5,
            vertical: AppTokens.space4,
          ),
          children: [
            // Theme Mode Selector Segment
            _buildThemeSelector(colors, textTheme),
            const SizedBox(height: AppTokens.space6),

            // 1. Typography Hierarchy
            Text(
              'Typography Hierarchy',
              style: AppTypography.sectionHeader(color: colors.brandInk),
            ),
            const SizedBox(height: AppTokens.space3),
            BrandCard(
              radius: BrandCardRadius.large,
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Screen Title (Playfair Display 26)',
                    style: AppTypography.screenTitle(color: colors.brandInk),
                  ),
                  const SizedBox(height: AppTokens.space2),
                  Text(
                    'Section Header (Playfair Display 19)',
                    style: AppTypography.sectionHeader(color: colors.brandInk),
                  ),
                  const SizedBox(height: AppTokens.space2),
                  Text(
                    'Body Text (Inter 15): Artisan hand-stretched sourdough crust baked in an 800°F stone oven with San Marzano tomatoes and fresh fior di latte.',
                    style: AppTypography.body(color: colors.brandInk),
                  ),
                  const SizedBox(height: AppTokens.space2),
                  Text(
                    'Caption / Label (Inter 12): Ordered 2m ago • Table 4 • Token SNS-4082',
                    style:
                        AppTypography.labelCaption(color: colors.textSecondary),
                  ),
                  const SizedBox(height: AppTokens.space3),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stat / Price',
                            style: AppTypography.labelCaption(
                              color: colors.textSecondary,
                            ),
                          ),
                          Text(
                            '₹450',
                            style: AppTypography.statNumber(
                              color: colors.brandInk,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppTokens.space8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Loyalty Progress',
                            style: AppTypography.labelCaption(
                              color: colors.textSecondary,
                            ),
                          ),
                          Text(
                            '6 / 10',
                            style: AppTypography.statNumber(
                              color: colors.brandInk,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space6),

            // 2. Status Badges (15% opacity background)
            Text(
              'Status Badges (15% opacity bg + solid text)',
              style: AppTypography.sectionHeader(color: colors.brandInk),
            ),
            const SizedBox(height: AppTokens.space3),
            Wrap(
              spacing: AppTokens.space3,
              runSpacing: AppTokens.space2,
              children: [
                _buildBadge(
                  label: 'Completed / Accepted',
                  icon: Icons.check_circle_outline,
                  textColor: colors.success,
                  backgroundColor: colors.successBackground,
                ),
                _buildBadge(
                  label: 'Pending (Cooking)',
                  icon: Icons.access_time,
                  textColor: colors.warning,
                  backgroundColor: colors.warningBackground,
                ),
                _buildBadge(
                  label: 'Rejected / Cancelled',
                  icon: Icons.cancel_outlined,
                  textColor: colors.error,
                  backgroundColor: colors.errorBackground,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space6),

            // 3. BrandCard Foundational Widget Showcase
            Text(
              'BrandCard Shells (Task 0-3)',
              style: AppTypography.sectionHeader(color: colors.brandInk),
            ),
            const SizedBox(height: AppTokens.space3),
            Row(
              children: [
                Expanded(
                  child: BrandCard(
                    radius: BrandCardRadius.large,
                    surface: BrandCardSurface.base,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Base Card',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.brandInk,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space1),
                        Text(
                          'R24 Static',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: BrandCard(
                    radius: BrandCardRadius.medium,
                    surface: BrandCardSurface.alt,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alt Surface',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.brandInk,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space1),
                        Text(
                          'R16 Selected',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: BrandCard(
                    radius: BrandCardRadius.small,
                    surface: BrandCardSurface.alt2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alt2 Surface',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.brandInk,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space1),
                        Text(
                          'R12 Tertiary',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space3),

            // Interactive BrandCard with press feedback (scale 0.985)
            BrandCard(
              radius: BrandCardRadius.large,
              onTap: () {
                setState(() => _cardTapCount++);
              },
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTokens.brandHighlight,
                      borderRadius: AppTokens.borderRadiusMedium,
                    ),
                    child: const Icon(
                      Icons.touch_app_outlined,
                      color: AppTokens.brandInk,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Interactive BrandCard (Tappable)',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.brandInk,
                          ),
                        ),
                        Text(
                          'Taps: $_cardTapCount • Scales to 0.985 with spring',
                          style: AppTypography.labelCaption(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space6),

            // 4. BrandButton Foundational Widget Showcase
            Text(
              'BrandButton Variants & States (Task 0-3)',
              style: AppTypography.sectionHeader(color: colors.brandInk),
            ),
            const SizedBox(height: AppTokens.space3),
            BrandButton(
              text: 'Primary CTA (Press Scale 0.97)',
              icon: Icons.bolt,
              onPressed: () {},
            ),
            const SizedBox(height: AppTokens.space3),
            BrandButton.secondary(
              text: 'Secondary Variant (Soft Neutral Fill)',
              onPressed: () {},
            ),
            const SizedBox(height: AppTokens.space3),
            BrandButton.outlined(
              text: 'Outlined Variant (Divider Border)',
              onPressed: () {},
            ),
            const SizedBox(height: AppTokens.space3),
            BrandButton.destructive(
              text: 'Destructive Variant (Error Color)',
              icon: Icons.delete_outline,
              onPressed: () {},
            ),
            const SizedBox(height: AppTokens.space3),
            Row(
              children: [
                Expanded(
                  child: BrandButton(
                    text: _isButtonLoading ? 'Saving...' : 'Toggle Loading',
                    isLoading: _isButtonLoading,
                    onPressed: _triggerLoadingButton,
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                const Expanded(
                  child: BrandButton(
                    text: 'Disabled State',
                    isDisabled: true,
                    onPressed: null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space6),

            // 5. ConfirmationDialog Foundational Widget Showcase
            Text(
              'Confirmation Dialog (Task 0-3)',
              style: AppTypography.sectionHeader(color: colors.brandInk),
            ),
            const SizedBox(height: AppTokens.space3),
            if (_dialogResult != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space4,
                  vertical: AppTokens.space2,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceCreamAlt,
                  borderRadius: AppTokens.borderRadiusMedium,
                ),
                child: Text(
                  _dialogResult!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.brandInk,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space3),
            ],
            Row(
              children: [
                Expanded(
                  child: BrandButton.outlined(
                    text: 'Standard Dialog',
                    height: 48.0,
                    onPressed: _showStandardDialog,
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: BrandButton.destructive(
                    text: 'Destructive Dialog',
                    height: 48.0,
                    onPressed: _showDestructiveDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space6),

            // 6. Availability Switch demonstration
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space4,
                vertical: AppTokens.space3,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceCream,
                borderRadius: AppTokens.borderRadiusMedium,
                border: Border.all(color: colors.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item Availability',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.brandInk,
                        ),
                      ),
                      Text(
                        _switchActive ? 'In Stock (Accepting)' : 'Sold Out',
                        style: AppTypography.labelCaption(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _switchActive,
                    onChanged: (val) {
                      setState(() {
                        _switchActive = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space6),

            // 7. Order Card Preview using BrandCard & BrandButton
            Text(
              'Sample Order Card (Reusing Widgets)',
              style: AppTypography.sectionHeader(color: colors.brandInk),
            ),
            const SizedBox(height: AppTokens.space3),
            BrandCard(
              radius: BrandCardRadius.large,
              padding: const EdgeInsets.all(AppTokens.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #SNS-104',
                        style:
                            AppTypography.sectionHeader(color: colors.brandInk),
                      ),
                      _buildBadge(
                        label: 'Pending',
                        icon: Icons.access_time,
                        textColor: colors.warning,
                        backgroundColor: colors.warningBackground,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space2),
                  Text(
                    '2x Margherita Extra, 1x Truffle Garlic Bread',
                    style: AppTypography.body(color: colors.brandInk),
                  ),
                  const SizedBox(height: AppTokens.space3),
                  Divider(color: colors.divider),
                  const SizedBox(height: AppTokens.space3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount',
                            style: AppTypography.labelCaption(
                              color: colors.textSecondary,
                            ),
                          ),
                          Text(
                            '₹890',
                            style: AppTypography.statNumber(
                              color: colors.brandInk,
                            ),
                          ),
                        ],
                      ),
                      BrandButton(
                        text: 'Mark Preparing',
                        width: 160.0,
                        height: 48.0,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space8),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(AppThemeExtension colors, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.space2),
      decoration: BoxDecoration(
        color: colors.surfaceCream,
        borderRadius: AppTokens.borderRadiusPill,
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          _buildThemeTab(
            label: 'System',
            icon: Icons.brightness_auto,
            mode: ThemeMode.system,
            colors: colors,
          ),
          _buildThemeTab(
            label: 'Light',
            icon: Icons.light_mode,
            mode: ThemeMode.light,
            colors: colors,
          ),
          _buildThemeTab(
            label: 'Dark',
            icon: Icons.dark_mode,
            mode: ThemeMode.dark,
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTab({
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required AppThemeExtension colors,
  }) {
    final isSelected = widget.currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onModeChanged(mode),
        child: AnimatedContainer(
          duration: AppTokens.motionMicro,
          curve: AppTokens.curveSpring,
          padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
          decoration: BoxDecoration(
            color: isSelected ? AppTokens.brandHighlight : Colors.transparent,
            borderRadius: AppTokens.borderRadiusPill,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppTokens.brandInk : colors.textSecondary,
              ),
              const SizedBox(width: AppTokens.space1),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTokens.brandInk : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space3,
        vertical: AppTokens.space1,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppTokens.borderRadiusSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: AppTokens.space1),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
