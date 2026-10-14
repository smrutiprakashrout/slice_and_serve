import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/menu_item.dart';
import '../../providers/menu_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_button.dart';
import '../../widgets/brand_card.dart';
import '../../widgets/confirmation_dialog.dart';
import 'menu_item_form.dart';

/// Available display modes for reviewing [MenuScreen] states in Stage A and tests.
enum MenuViewMode {
  list,
  loading,
  empty,
}

/// Menu list screen for Slice & Serve Admin application.
///
/// Implements PRD §3.3 (A-9, A-15, A-16) and Task 2B-1:
/// - Main list of menu items from [menuProvider] via `GET /api/menu`
/// - Item cards with left placeholder food icon, details, price, and availability switch
/// - Optimistic local availability toggle (Task 2B-2 wires backend PATCH)
/// - Skeleton loading and empty states
/// - Pull-to-refresh with visible indicator wired to [menuProvider.refresh]
/// - FloatingActionButton ("+") for creating items
class MenuScreen extends ConsumerStatefulWidget {
  final MenuViewMode initialViewMode;

  const MenuScreen({
    super.key,
    this.initialViewMode = MenuViewMode.list,
  });

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen>
    with SingleTickerProviderStateMixin {
  late MenuViewMode _viewMode;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialViewMode;
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (_viewMode == MenuViewMode.loading) {
      _shimmerController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _setViewMode(MenuViewMode mode) {
    if (_viewMode != mode) {
      setState(() {
        _viewMode = mode;
      });
      if (_viewMode == MenuViewMode.loading) {
        _shimmerController.repeat(reverse: true);
      } else {
        _shimmerController.stop();
      }
    }
  }

  Future<void> _toggleAvailability(String id, bool newStatus) async {
    HapticFeedback.lightImpact();
    final result = await ref
        .read(menuProvider.notifier)
        .toggleAvailability(id, newStatus);

    result.when(
      success: (_) {
        // Optimistic state was already correct
      },
      failure: (message, statusCode, errorCode) {
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        _showErrorSnackBar(
          'Failed to update availability: $message',
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    final theme = context.appTheme;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppTokens.space4),
        shape: const RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusMedium,
        ),
        backgroundColor: theme.error,
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await ref.read(menuProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Menu refreshed'),
          duration: Duration(milliseconds: 900),
        ),
      );
    }
  }

  void _resetMockItems() {
    setState(() {
      _viewMode = MenuViewMode.list;
    });
    _shimmerController.stop();
    ref.read(menuProvider.notifier).refresh();
  }

  IconData _getCategoryIcon(String categorySlug) {
    switch (categorySlug.toLowerCase()) {
      case 'pizza':
        return Icons.local_pizza_rounded;
      case 'burger':
        return Icons.lunch_dining_rounded;
      case 'sandwitch':
      case 'sandwich':
        return Icons.breakfast_dining_rounded;
      case 'staters':
      case 'starters':
      case 'sides':
        return Icons.bakery_dining_rounded;
      case 'drinks':
      case 'beverage':
      case 'beverages':
        return Icons.local_cafe_rounded;
      case 'dessert':
      case 'desserts':
        return Icons.cake_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  Future<void> _openCreateForm() async {
    HapticFeedback.lightImpact();
    final newItem = await MenuItemForm.show(context);
    if (newItem != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${newItem.name}" to menu'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openEditForm(MenuItem item) async {
    HapticFeedback.lightImpact();
    final updatedItem = await MenuItemForm.show(context, item: item);
    if (updatedItem != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated "${updatedItem.name}"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool> _confirmDeleteItem(MenuItem item) async {
    HapticFeedback.mediumImpact();
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete "${item.name}"?',
      message:
          'Are you sure you want to remove this item from the menu? This action cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed) return false;

    final result =
        await ref.read(menuProvider.notifier).deleteMenuItem(item.id);
    if (!mounted) return false;

    return result.when(
      success: (_) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${item.name}"'),
            duration: const Duration(seconds: 2),
          ),
        );
        return true;
      },
      failure: (message, statusCode, errorCode) {
        HapticFeedback.mediumImpact();
        final theme = context.appTheme;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppTokens.space4),
            shape: const RoundedRectangleBorder(
              borderRadius: AppTokens.borderRadiusMedium,
            ),
            backgroundColor: theme.error,
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        return false;
      },
    );
  }

  void _deleteItem(MenuItem item) {
    if (!mounted) return;
    ref.read(menuProvider.notifier).removeItem(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final menuAsync = ref.watch(menuProvider);
    final items = menuAsync.value ?? const <MenuItem>[];
    final activeCount = items.where((MenuItem i) => i.available).length;
    final totalCount = items.length;
    ref.listen<AsyncValue<List<MenuItem>>>(menuProvider, (previous, next) {
      if (next.isLoading && !next.hasValue) {
        if (!_shimmerController.isAnimating) {
          _shimmerController.repeat(reverse: true);
        }
      } else if (_viewMode != MenuViewMode.loading) {
        if (_shimmerController.isAnimating) {
          _shimmerController.stop();
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        key: const Key('menu_fab_add'),
        backgroundColor: AppTokens.brandHighlight,
        foregroundColor: AppTokens.brandInk,
        elevation: 3,
        shape: const CircleBorder(),
        tooltip: 'Add Menu Item',
        onPressed: _openCreateForm,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: Column(
        children: [
          // Sub-header / Review Toolbar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space4,
              AppTokens.space2,
              AppTokens.space4,
              AppTokens.space2,
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppTokens.space2,
              runSpacing: AppTokens.space1,
              children: [
                Text(
                  _viewMode == MenuViewMode.empty
                      ? '0/0 Active'
                      : '$activeCount/$totalCount Active',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ViewModeSelectorChip(
                      key: const Key('menu_view_mode_list'),
                      label: 'List',
                      isSelected: _viewMode == MenuViewMode.list,
                      onTap: () => _setViewMode(MenuViewMode.list),
                    ),
                    const SizedBox(width: AppTokens.space1),
                    _ViewModeSelectorChip(
                      key: const Key('menu_view_mode_loading'),
                      label: 'Loading',
                      isSelected: _viewMode == MenuViewMode.loading,
                      onTap: () => _setViewMode(MenuViewMode.loading),
                    ),
                    const SizedBox(width: AppTokens.space1),
                    _ViewModeSelectorChip(
                      key: const Key('menu_view_mode_empty'),
                      label: 'Empty',
                      isSelected: _viewMode == MenuViewMode.empty,
                      onTap: () => _setViewMode(MenuViewMode.empty),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main View Content depending on state
          Expanded(
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : AppTokens.motionStandard,
              child: _buildCurrentView(context, menuAsync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView(
      BuildContext context, AsyncValue<List<MenuItem>> menuAsync) {
    if (_viewMode == MenuViewMode.loading) {
      return _buildLoadingSkeleton(context);
    }
    if (_viewMode == MenuViewMode.empty) {
      return _buildEmptyState(context);
    }

    return menuAsync.when(
      loading: () => _buildLoadingSkeleton(context),
      error: (error, stackTrace) => _buildErrorState(context, error),
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildMenuList(context, items);
      },
    );
  }

  Widget _buildMenuList(BuildContext context, List<MenuItem> items) {
    return RefreshIndicator(
      key: const Key('menu_refresh_indicator'),
      color: AppTokens.brandInk,
      backgroundColor: context.appTheme.surfaceCream,
      onRefresh: _handleRefresh,
      child: ListView.builder(
        key: const Key('menu_list_view'),
        padding: const EdgeInsets.only(
          top: AppTokens.space3,
          bottom: AppTokens.space12 + AppTokens.space8, // Clear FAB
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _DismissibleMenuItemCard(
            key: Key('menu_item_${item.id}'),
            item: item,
            categoryIcon: _getCategoryIcon(item.categorySlug),
            onToggle: (newValue) => _toggleAvailability(item.id, newValue),
            onTap: () => _openEditForm(item),
            onConfirmDelete: () => _confirmDeleteItem(item),
            onDelete: () => _deleteItem(item),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    final theme = context.appTheme;

    return AnimatedBuilder(
      key: const Key('menu_loading_skeleton_view'),
      animation: _shimmerController,
      builder: (context, child) {
        final opacity = 0.38 + (_shimmerController.value * 0.44);

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            top: AppTokens.space3,
            bottom: AppTokens.space12,
          ),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space4,
                vertical: AppTokens.space2,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppTokens.space4),
                decoration: BoxDecoration(
                  color: theme.surfaceCream,
                  borderRadius: AppTokens.borderRadiusLarge,
                  border: Border.all(color: theme.divider),
                ),
                child: Row(
                  children: [
                    // Placeholder square
                    Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: theme.surfaceCreamAlt,
                          borderRadius: AppTokens.borderRadiusMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.space3),
                    // Lines
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Opacity(
                            opacity: opacity,
                            child: Container(
                              width: 140,
                              height: 14,
                              decoration: BoxDecoration(
                                color: theme.surfaceCreamAlt,
                                borderRadius: AppTokens.borderRadiusSmall,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTokens.space2),
                          Opacity(
                            opacity: opacity,
                            child: Container(
                              width: double.infinity,
                              height: 11,
                              decoration: BoxDecoration(
                                color: theme.surfaceCreamAlt,
                                borderRadius: AppTokens.borderRadiusSmall,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTokens.space3),
                          Opacity(
                            opacity: opacity,
                            child: Container(
                              width: 60,
                              height: 14,
                              decoration: BoxDecoration(
                                color: theme.surfaceCreamAlt,
                                borderRadius: AppTokens.borderRadiusSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTokens.space3),
                    // Switch dummy
                    Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 44,
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.surfaceCreamAlt,
                          borderRadius: AppTokens.borderRadiusPill,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = context.appTheme;

    return Center(
      key: const Key('menu_empty_view'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.space8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.surfaceCream,
                shape: BoxShape.circle,
                border: Border.all(color: theme.divider),
              ),
              child: Icon(
                Icons.restaurant_menu_outlined,
                size: 38,
                color: theme.brandInk,
              ),
            ),
            const SizedBox(height: AppTokens.space6),
            Text(
              'No Menu Items Found',
              textAlign: TextAlign.center,
              style: AppTypography.screenTitle(
                color: theme.brandInk,
              ).copyWith(fontSize: 22),
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              'Your menu catalog is currently empty. Tap below to reload the sample catalog or tap "+" to create an item.',
              textAlign: TextAlign.center,
              style: AppTypography.body(
                color: theme.textSecondary,
              ).copyWith(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: AppTokens.space8),
            BrandButton.secondary(
              key: const Key('menu_empty_reload_button'),
              text: 'Refresh Menu',
              width: 220,
              onPressed: _resetMockItems,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = context.appTheme;

    return Center(
      key: const Key('menu_error_view'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.space8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.errorBackground,
                shape: BoxShape.circle,
                border: Border.all(color: theme.error.withValues(alpha: 0.3)),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 38,
                color: theme.error,
              ),
            ),
            const SizedBox(height: AppTokens.space6),
            Text(
              'Unable to Load Menu',
              textAlign: TextAlign.center,
              style: AppTypography.screenTitle(
                color: theme.brandInk,
              ).copyWith(fontSize: 22),
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              error.toString().replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: AppTypography.body(
                color: theme.textSecondary,
              ).copyWith(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: AppTokens.space8),
            BrandButton.secondary(
              key: const Key('menu_error_retry_button'),
              text: 'Retry',
              width: 180,
              onPressed: () {
                ref.read(menuProvider.notifier).refresh();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated dismissible wrapper supporting both swipe-to-delete (end-to-start)
/// and long-press deletion, backed by the destructive [ConfirmationDialog].
class _DismissibleMenuItemCard extends StatefulWidget {
  final MenuItem item;
  final IconData categoryIcon;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final Future<bool> Function() onConfirmDelete;
  final VoidCallback onDelete;

  const _DismissibleMenuItemCard({
    super.key,
    required this.item,
    required this.categoryIcon,
    required this.onToggle,
    required this.onTap,
    required this.onConfirmDelete,
    required this.onDelete,
  });

  @override
  State<_DismissibleMenuItemCard> createState() =>
      _DismissibleMenuItemCardState();
}

class _DismissibleMenuItemCardState extends State<_DismissibleMenuItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _collapseController;
  late Animation<double> _sizeAnimation;
  late Animation<double> _fadeAnimation;
  bool _isManuallyDeleting = false;

  @override
  void initState() {
    super.initState();
    _collapseController = AnimationController(
      vsync: this,
      duration: AppTokens.motionStandard,
      value: 1.0,
    );
    _sizeAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeInOutCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _collapseController.dispose();
    super.dispose();
  }

  Future<void> _handleLongPressDelete() async {
    final confirmed = await widget.onConfirmDelete();
    if (confirmed && mounted) {
      setState(() => _isManuallyDeleting = true);
      await _collapseController.reverse();
      if (mounted) {
        widget.onDelete();
      }
    }
  }

  Widget _buildDismissBackground(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      key: Key('menu_dismiss_bg_${widget.item.id}'),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space6),
      decoration: BoxDecoration(
        color: theme.errorBackground,
        borderRadius: AppTokens.borderRadiusLarge,
        border: Border.all(
          color: theme.error.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delete_outline_rounded,
            color: theme.error,
            size: 24,
          ),
          const SizedBox(width: AppTokens.space2),
          Text(
            'Delete',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.error,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardWidget = _MenuItemCard(
      item: widget.item,
      categoryIcon: widget.categoryIcon,
      onToggle: widget.onToggle,
      onTap: widget.onTap,
      onLongPress: _handleLongPressDelete,
    );

    if (_isManuallyDeleting) {
      return SizeTransition(
        sizeFactor: _sizeAnimation,
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: cardWidget,
        ),
      );
    }

    return Dismissible(
      key: Key('menu_dismissible_${widget.item.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => widget.onConfirmDelete(),
      onDismissed: (direction) => widget.onDelete(),
      background: _buildDismissBackground(context),
      secondaryBackground: _buildDismissBackground(context),
      child: cardWidget,
    );
  }
}

/// Themed item card displaying details and availability toggle.
class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final IconData categoryIcon;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _MenuItemCard({
    required this.item,
    required this.categoryIcon,
    required this.onToggle,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return BrandCard(
      radius: BrandCardRadius.large,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space2,
      ),
      padding: const EdgeInsets.all(AppTokens.space4),
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedOpacity(
        duration: reduceMotion ? Duration.zero : AppTokens.motionStandard,
        opacity: item.available ? 1.0 : 0.48,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Food Graphic Placeholder (Permanent per PRD A-16)
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.surfaceCreamAlt,
                borderRadius: AppTokens.borderRadiusMedium,
                border: Border.all(
                  color: theme.divider,
                ),
              ),
              child: Icon(
                categoryIcon,
                size: 32,
                color: theme.brandInk,
              ),
            ),
            const SizedBox(width: AppTokens.space3),

            // Middle: Name, Subtitle, Price & Badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: AppTokens.space2,
                    runSpacing: 4,
                    children: [
                      _DietaryTag(type: item.type),
                      if (item.featured) _FeaturedTag(),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space1),
                  Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.brandInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space2),
                  Wrap(
                    spacing: AppTokens.space2,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: AppTypography.screenTitle(
                          color: theme.brandInk,
                        ).copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!item.available)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.space2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.errorBackground,
                            borderRadius: AppTokens.borderRadiusSmall,
                          ),
                          child: Text(
                            'Unavailable',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.space2),

            // Right: Availability Switch
            Switch(
              key: Key('menu_switch_${item.id}'),
              value: item.available,
              onChanged: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact dietary type pill indicator.
class _DietaryTag extends StatelessWidget {
  final String type;

  const _DietaryTag({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isVeg = type.toLowerCase() == 'veg';
    final color = isVeg ? theme.success : theme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isVeg ? theme.successBackground : theme.errorBackground,
        borderRadius: AppTokens.borderRadiusSmall,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isVeg ? 'VEG' : 'NON-VEG',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact featured badge for highlighted items.
class _FeaturedTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTokens.brandHighlight,
        borderRadius: AppTokens.borderRadiusSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 10,
            color: AppTokens.brandInk,
          ),
          const SizedBox(width: 2),
          Text(
            'FEATURED',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTokens.brandInk,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector chip for mock view mode switching during review.
class _ViewModeSelectorChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeSelectorChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : AppTokens.motionMicro,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.brandInk : theme.surfaceCream,
          borderRadius: AppTokens.borderRadiusPill,
          border: Border.all(
            color: isSelected ? theme.brandInk : theme.divider,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? theme.background : theme.textSecondary,
          ),
        ),
      ),
    );
  }
}
