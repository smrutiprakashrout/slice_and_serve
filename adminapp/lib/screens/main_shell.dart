import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/navigation_provider.dart';
import '../providers/orders_provider.dart';
import '../theme/app_theme.dart';
import 'loyalty/loyalty_scanner_screen.dart';
import 'menu/menu_screen.dart';
import 'orders/orders_screen.dart';
import 'settings/settings_screen.dart';

/// Main navigation shell for the Slice & Serve Admin application.
///
/// Adheres to `PRD.md` §3.2 (A-5, A-6, A-7), §3.5 (A-28), §3.8 (A-41), and `polished-flutter-ui` Bottom Navigation:
/// - Four tabs in strict order: Menu, Loyalty, Orders, Settings
/// - Material 3 [NavigationBar] with themed surface, brandHighlight active indicator, and crisp labels
/// - [IndexedStack] body to preserve tab scroll states across switches
/// - Real pending order count badge on Orders tab wired to [pendingOrdersCountProvider] (Task 4B-3)
/// - Deep linking support via [shellTabProvider] (Task Push-3)
/// - First-class support for light and dark modes
class MainShell extends ConsumerStatefulWidget {
  final VoidCallback? onToggleTheme;
  final int initialIndex;

  const MainShell({
    super.key,
    this.onToggleTheme,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    if (widget.initialIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(shellTabProvider.notifier).setTab(widget.initialIndex);
      });
    }
  }

  void _onDestinationSelected(int index) {
    if (index == 2) {
      // PRD A-7, A-28: Refresh orders and pending badge on each visit to the Orders tab
      ref.read(ordersProvider.notifier).refreshOnTabVisit();
    }
    ref.read(shellTabProvider.notifier).setTab(index);
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Menu';
      case 1:
        return 'Loyalty';
      case 2:
        return 'Orders';
      case 3:
        return 'Settings';
      default:
        return 'Slice and Serve Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendingCount = ref.watch(pendingOrdersCountProvider);
    final activeTabIndex = ref.watch(shellTabProvider);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(activeTabIndex),
          style: AppTypography.screenTitle(color: theme.brandInk).copyWith(
            fontSize: 22,
          ),
        ),
        actions: [
          if (widget.onToggleTheme != null)
            IconButton(
              key: const Key('shell_theme_toggle_button'),
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: theme.brandInk,
                size: 20,
              ),
              tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
              onPressed: widget.onToggleTheme,
            ),
        ],
      ),
      body: IndexedStack(
        index: activeTabIndex,
        children: const [
          MenuScreen(
            key: Key('shell_tab_menu_view'),
          ),
          LoyaltyScannerScreen(
            key: Key('shell_tab_loyalty_view'),
          ),
          OrdersScreen(
            key: Key('shell_tab_orders_view'),
          ),
          SettingsScreen(
            key: Key('shell_tab_settings_view'),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.surfaceCream,
          border: Border(
            top: BorderSide(
              color: theme.divider,
              width: 1.0,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: activeTabIndex,
          onDestinationSelected: _onDestinationSelected,
          backgroundColor: theme.surfaceCream,
          elevation: 0,
          destinations: [
            const NavigationDestination(
              key: Key('shell_nav_menu'),
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant_rounded),
              label: 'Menu',
            ),
            const NavigationDestination(
              key: Key('shell_nav_loyalty'),
              icon: Icon(Icons.loyalty_outlined),
              selectedIcon: Icon(Icons.loyalty_rounded),
              label: 'Loyalty',
            ),
            NavigationDestination(
              key: const Key('shell_nav_orders'),
              icon: Badge.count(
                count: pendingCount,
                isLabelVisible: pendingCount > 0,
                backgroundColor: theme.warning,
                textColor: Colors.white,
                textStyle: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                child: const Icon(Icons.receipt_long_outlined),
              ),
              selectedIcon: Badge.count(
                count: pendingCount,
                isLabelVisible: pendingCount > 0,
                backgroundColor: theme.warning,
                textColor: Colors.white,
                textStyle: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                child: const Icon(Icons.receipt_long_rounded),
              ),
              label: 'Orders',
            ),
            const NavigationDestination(
              key: Key('shell_nav_settings'),
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

