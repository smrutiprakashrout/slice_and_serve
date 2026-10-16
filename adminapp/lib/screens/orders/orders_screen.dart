import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/orders_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_button.dart';
import '../../widgets/confirmation_dialog.dart';
import 'order_card.dart';

// Re-export OrderStatusSegment so existing consumers/tests have it accessible from orders_screen.dart
export '../../models/order.dart' show OrderStatusSegment;

/// Review mode state for Stage A/B evaluation and widget testing.
enum OrdersViewMode {
  list,
  loading,
  empty,
}

/// The main Orders tab screen in Slice & Serve Admin.
///
/// Implements `PRD.md` §3.5 (A-24, A-25, A-26, A-27, A-29), `ARCHITECTURE.md` §3, §4,
/// and `TASKS.md` 4B-1:
/// - 3 status segments: Pending · Preparing · Completed
/// - Consumes [ordersProvider] via `GET /api/orders?status=`
/// - Each segment queries only its respective real status value
/// - Defensively enforces that rejected orders never appear anywhere
/// - Action buttons per status (Accept/Reject, Complete, terminal absent)
/// - Confirmation dialog on Reject
/// - First-class loading, empty, and error states
/// - Pull-to-refresh wired to [OrdersNotifier.refresh]
class OrdersScreen extends ConsumerStatefulWidget {
  final OrdersViewMode initialViewMode;
  final OrderStatusSegment initialSegment;
  final DateTime? referenceTime;
  final List<Order>? initialOrders;

  const OrdersScreen({
    super.key,
    this.initialViewMode = OrdersViewMode.list,
    this.initialSegment = OrderStatusSegment.pending,
    this.referenceTime,
    this.initialOrders,
  });

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late OrderStatusSegment _selectedSegment;
  late OrdersViewMode _viewMode;
  late AnimationController _shimmerController;
  final Set<String> _processingOrderIds = {};

  @override
  void initState() {
    super.initState();
    _selectedSegment = widget.initialSegment;
    _viewMode = widget.initialViewMode;
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (_viewMode == OrdersViewMode.loading) {
      _shimmerController.repeat(reverse: true);
    }

    if (widget.initialOrders != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(ordersProvider.notifier).setInitialOrders(widget.initialOrders!);
      });
    } else if (widget.initialSegment != OrderStatusSegment.pending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(ordersProvider.notifier).fetchSegment(widget.initialSegment);
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _onSegmentChanged(OrderStatusSegment segment) {
    if (_selectedSegment != segment) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedSegment = segment;
      });
      ref.read(ordersSelectedSegmentProvider.notifier).setSegment(segment);
      ref.read(ordersProvider.notifier).fetchSegment(segment);
    }
  }

  void _setViewMode(OrdersViewMode mode) {
    if (_viewMode != mode) {
      HapticFeedback.lightImpact();
      setState(() {
        _viewMode = mode;
        if (_viewMode == OrdersViewMode.loading) {
          _shimmerController.repeat(reverse: true);
        } else {
          _shimmerController.stop();
        }
      });
    }
  }

  Future<void> _handleRefresh() async {
    await ref.read(ordersProvider.notifier).refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orders refreshed'),
          duration: Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Accepts a pending order via [OrdersNotifier.acceptOrder].
  Future<void> _acceptOrder(Order order) async {
    if (_processingOrderIds.contains(order.id)) return;
    HapticFeedback.lightImpact();
    setState(() {
      _processingOrderIds.add(order.id);
    });

    final result = await ref.read(ordersProvider.notifier).acceptOrder(order.id);

    if (mounted) {
      setState(() {
        _processingOrderIds.remove(order.id);
      });

      result.when(
        success: (updated) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order #${order.id} accepted'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        failure: (String message, int? statusCode, String? errorCode) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
      );
    }
  }

  /// Completes an accepted order via [OrdersNotifier.completeOrder].
  Future<void> _completeOrder(Order order) async {
    if (_processingOrderIds.contains(order.id)) return;
    HapticFeedback.lightImpact();
    setState(() {
      _processingOrderIds.add(order.id);
    });

    final result = await ref.read(ordersProvider.notifier).completeOrder(order.id);

    if (mounted) {
      setState(() {
        _processingOrderIds.remove(order.id);
      });

      result.when(
        success: (updated) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order #${order.id} completed'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        failure: (String message, int? statusCode, String? errorCode) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
      );
    }
  }

  /// Prompts rejection confirmation dialog, then calls [OrdersNotifier.rejectOrder].
  Future<void> _promptRejectOrder(Order order) async {
    if (_processingOrderIds.contains(order.id)) return;
    HapticFeedback.mediumImpact();
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Reject Order #${order.id}?',
      message:
          'Are you sure you want to reject this order from ${order.customerName}? This action cannot be undone.',
      confirmLabel: 'Reject Order',
      cancelLabel: 'Cancel',
      isDestructive: true,
      icon: Icons.cancel_outlined,
    );

    if (confirmed && mounted) {
      setState(() {
        _processingOrderIds.add(order.id);
      });

      final result = await ref.read(ordersProvider.notifier).rejectOrder(order.id);

      if (mounted) {
        setState(() {
          _processingOrderIds.remove(order.id);
        });

        result.when(
          success: (updated) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order #${order.id} rejected'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          failure: (String message, int? statusCode, String? errorCode) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OrderStatusSegment>(ordersSelectedSegmentProvider, (prev, next) {
      if (_selectedSegment != next) {
        setState(() {
          _selectedSegment = next;
        });
        ref.read(ordersProvider.notifier).fetchSegment(next);
      }
    });

    final theme = context.appTheme;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final ordersAsync = ref.watch(ordersProvider);
    final currentOrders = ordersAsync.value ?? const <Order>[];

    return Column(
      children: [
        // Top Bar: Segmented Status Control & Review Controls
        Container(
          color: theme.background,
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            AppTokens.space3,
            AppTokens.space4,
            AppTokens.space2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented Status Control (Pending · Preparing · Completed)
              _buildSegmentedControl(theme, currentOrders),
              const SizedBox(height: AppTokens.space2),

              // Review Header: Segment summary & View Mode chips
              _buildReviewHeader(theme, currentOrders),
            ],
          ),
        ),

        // Main Body: List, Loading Skeleton, Empty State, or Error View
        Expanded(
          child: AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : AppTokens.motionStandard,
            child: _buildCurrentBody(context, theme, ordersAsync),
          ),
        ),
      ],
    );
  }

  /// The 3-segment status control pill container
  Widget _buildSegmentedControl(
    AppThemeExtension theme,
    List<Order> currentOrders,
  ) {
    final notifier = ref.read(ordersProvider.notifier);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Container(
      key: const Key('orders_segmented_control'),
      height: 48,
      padding: const EdgeInsets.all(AppTokens.space1),
      decoration: BoxDecoration(
        color: theme.surfaceCream,
        borderRadius: AppTokens.borderRadiusPill,
        border: Border.all(
          color: theme.divider,
          width: 1.0,
        ),
      ),
      child: Row(
        children: OrderStatusSegment.values.map((segment) {
          final isSelected = _selectedSegment == segment;
          final count = isSelected
              ? currentOrders.length
              : notifier.countForSegment(segment);

          return Expanded(
            child: GestureDetector(
              key: Key('orders_segment_${segment.value}'),
              onTap: () => _onSegmentChanged(segment),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: reduceMotion ? Duration.zero : AppTokens.motionMicro,
                curve: AppTokens.curveEnter,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? theme.brandHighlight : Colors.transparent,
                  borderRadius: AppTokens.borderRadiusPill,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.brandHighlight.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        segment.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppTokens.brandInk : theme.textSecondary,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTokens.brandInk.withValues(alpha: 0.12)
                            : theme.surfaceCreamAlt,
                        borderRadius: AppTokens.borderRadiusPill,
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppTokens.brandInk : theme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Review Scaffolding bar for toggling List | Loading | Empty
  Widget _buildReviewHeader(
    AppThemeExtension theme,
    List<Order> currentOrders,
  ) {
    final count = currentOrders.length;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppTokens.space2,
      runSpacing: AppTokens.space1,
      children: [
        Text(
          '$count ${_selectedSegment.label} Orders',
          key: const Key('orders_status_header_count'),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.textSecondary,
          ),
        ),
        if (kDebugMode)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReviewChip(
                key: const Key('orders_mode_list'),
                label: 'List',
                isSelected: _viewMode == OrdersViewMode.list,
                onTap: () => _setViewMode(OrdersViewMode.list),
                theme: theme,
              ),
              const SizedBox(width: AppTokens.space1),
              _buildReviewChip(
                key: const Key('orders_mode_loading'),
                label: 'Loading',
                isSelected: _viewMode == OrdersViewMode.loading,
                onTap: () => _setViewMode(OrdersViewMode.loading),
                theme: theme,
              ),
              const SizedBox(width: AppTokens.space1),
              _buildReviewChip(
                key: const Key('orders_mode_empty'),
                label: 'Empty',
                isSelected: _viewMode == OrdersViewMode.empty,
                onTap: () => _setViewMode(OrdersViewMode.empty),
                theme: theme,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildReviewChip({
    required Key key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required AppThemeExtension theme,
  }) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return GestureDetector(
      key: key,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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

  Widget _buildCurrentBody(
    BuildContext context,
    AppThemeExtension theme,
    AsyncValue<List<Order>> ordersAsync,
  ) {
    if (_viewMode == OrdersViewMode.loading) {
      return _buildLoadingSkeleton(theme);
    }

    if (_viewMode == OrdersViewMode.empty) {
      return _buildEmptyState(theme);
    }

    if (ordersAsync.hasError && !ordersAsync.hasValue) {
      return _buildErrorView(theme, ordersAsync.error!);
    }

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState(theme);
        }
        return _buildOrdersList(theme, orders);
      },
      loading: () => _buildLoadingSkeleton(theme),
      error: (error, _) => _buildErrorView(theme, error),
    );
  }

  Widget _buildOrdersList(AppThemeExtension theme, List<Order> orders) {
    return RefreshIndicator(
      key: const Key('orders_refresh_indicator'),
      color: theme.brandHighlight,
      backgroundColor: theme.surfaceCream,
      onRefresh: _handleRefresh,
      child: ListView.separated(
        key: ValueKey('orders_list_${_selectedSegment.value}'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space3,
        ),
        itemCount: orders.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppTokens.space3),
        itemBuilder: (context, index) {
          final order = orders[index];
          return OrderCard(
            key: ValueKey('order_item_${order.id}'),
            order: order,
            referenceTime: widget.referenceTime,
            isProcessing: _processingOrderIds.contains(order.id),
            onTap: () {
              HapticFeedback.lightImpact();
            },
            onAccept: () => _acceptOrder(order),
            onReject: () => _promptRejectOrder(order),
            onComplete: () => _completeOrder(order),
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton(AppThemeExtension theme) {
    return AnimatedBuilder(
      key: const Key('orders_loading_skeleton_view'),
      animation: _shimmerController,
      builder: (context, child) {
        final opacity = 0.38 + (_shimmerController.value * 0.44);

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space4,
            vertical: AppTokens.space3,
          ),
          itemCount: 4,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppTokens.space3),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(AppTokens.space4),
              decoration: BoxDecoration(
                color: theme.surfaceCream,
                borderRadius: AppTokens.borderRadiusLarge,
                border: Border.all(color: theme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 80,
                          height: 22,
                          decoration: BoxDecoration(
                            color: theme.surfaceCreamAlt,
                            borderRadius: AppTokens.borderRadiusSmall,
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 70,
                          height: 22,
                          decoration: BoxDecoration(
                            color: theme.surfaceCreamAlt,
                            borderRadius: AppTokens.borderRadiusSmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space3),
                  Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 140,
                      height: 16,
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
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.surfaceCreamAlt,
                        borderRadius: AppTokens.borderRadiusSmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space3),
                  Divider(color: theme.divider, height: 1),
                  const SizedBox(height: AppTokens.space3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 80,
                          height: 20,
                          decoration: BoxDecoration(
                            color: theme.surfaceCreamAlt,
                            borderRadius: AppTokens.borderRadiusSmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(AppThemeExtension theme) {
    IconData icon;
    String title;
    String subtitle;

    switch (_selectedSegment) {
      case OrderStatusSegment.pending:
        icon = Icons.receipt_long_outlined;
        title = 'No Pending Orders';
        subtitle = 'New orders placed by customers will appear here for review.';
        break;
      case OrderStatusSegment.accepted:
        icon = Icons.soup_kitchen_outlined;
        title = 'No Accepted Orders';
        subtitle = 'Orders currently being prepared in the kitchen will show here.';
        break;
      case OrderStatusSegment.completed:
        icon = Icons.task_alt_outlined;
        title = 'No Completed Orders';
        subtitle =
            'Fulfilled orders that have been served or picked up will show here.';
        break;
    }

    return RefreshIndicator(
      key: Key('orders_empty_refresh_indicator_${_selectedSegment.value}'),
      color: theme.brandHighlight,
      backgroundColor: theme.surfaceCream,
      onRefresh: _handleRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          Center(
            key: Key('orders_empty_view_${_selectedSegment.value}'),
            child: Padding(
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
                      icon,
                      size: 38,
                      color: theme.brandInk,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style:
                        AppTypography.sectionHeader(color: theme.brandInk).copyWith(
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style:
                          AppTypography.body(color: theme.textSecondary).copyWith(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(AppThemeExtension theme, Object error) {
    final errorMessage = error.toString().replaceFirst('Exception: ', '');

    return RefreshIndicator(
      color: theme.brandHighlight,
      backgroundColor: theme.surfaceCream,
      onRefresh: _handleRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          Center(
            key: const Key('orders_error_view'),
            child: Padding(
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
                      Icons.error_outline_rounded,
                      size: 38,
                      color: theme.error,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space6),
                  Text(
                    'Unable to load orders',
                    textAlign: TextAlign.center,
                    style:
                        AppTypography.sectionHeader(color: theme.brandInk).copyWith(
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style:
                          AppTypography.body(color: theme.textSecondary).copyWith(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space6),
                  BrandButton(
                    text: 'Retry',
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(ordersProvider.notifier).refresh();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
