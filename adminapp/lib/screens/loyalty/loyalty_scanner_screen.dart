import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/result.dart';
import '../../models/loyalty_card.dart';
import '../../providers/loyalty_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_button.dart';
import 'loyalty_card_view.dart';

/// Operational mode for the loyalty QR scanner.
enum LoyaltyScanMode {
  stamp,
  redeem,
}

/// Represents mismatch details between active scanner mode and scanned token.
@immutable
class LoyaltyMismatchData {
  final String scannedAction; // 'stamp' or 'redeem'
  final String expectedAction; // 'stamp' or 'redeem'
  final String? scannedCustomerName;

  const LoyaltyMismatchData({
    required this.scannedAction,
    required this.expectedAction,
    this.scannedCustomerName,
  });

  bool get isExpectedStamp => expectedAction == 'stamp';
}

/// Represents error details for 404 or network/server failure during scan resolution.
@immutable
class LoyaltyScanErrorData {
  final bool isNotFound;
  final String title;
  final String message;
  final int? statusCode;
  final String? errorCode;
  final VoidCallback? onRetry;

  const LoyaltyScanErrorData({
    required this.isNotFound,
    required this.title,
    required this.message,
    this.statusCode,
    this.errorCode,
    this.onRetry,
  });
}

/// Represents confirmation details for celebratory success feedback.
@immutable
class LoyaltySuccessData {
  final String action; // 'stamp' or 'redeem'
  final String customerName;
  final int? stamps;
  final int? totalRequired;

  const LoyaltySuccessData({
    required this.action,
    required this.customerName,
    this.stamps,
    this.totalRequired,
  });

  bool get isRedeem => action == 'redeem';
}

/// Screen presenting the top-level loyalty QR scanner, mode switcher,
/// mock-triggerable result cards, mode-mismatch error state, and
/// celebratory success-feedback state.
///
/// Implements `PRD.md` §3.4 (A-17, A-19, A-20, A-21, A-22) and `TASKS.md` 3A-2, 3A-3, 3A-4:
/// - Mode switch at top: **Add Stamp** | **Redeem** (pill-shaped segmented control)
/// - Themed camera-preview viewfinder box (tappable to simulate scan)
/// - Mode mismatch error state: brand-styled inline error with gentle shake + red pulse,
///   explicit plain-language copy, zero result card reveal, returns to scanner
/// - Celebratory success-feedback state: checkmark scale animation (<600ms),
///   wired haptic feedback, returns to scanner with mode selection unchanged
/// - Review scaffolding trigger row allowing simulation of all mock scenarios
class LoyaltyScannerScreen extends ConsumerStatefulWidget {
  final LoyaltyScanMode initialMode;
  final LoyaltyScanResult? initialScanResult;
  final MobileScannerController? controller;

  const LoyaltyScannerScreen({
    super.key,
    this.initialMode = LoyaltyScanMode.stamp,
    this.initialScanResult,
    this.controller,
  });

  @override
  ConsumerState<LoyaltyScannerScreen> createState() =>
      _LoyaltyScannerScreenState();
}

class _LoyaltyScannerScreenState extends ConsumerState<LoyaltyScannerScreen>
    with WidgetsBindingObserver {
  late LoyaltyScanMode _selectedMode;
  LoyaltyScanResult? _currentScanResult;
  LoyaltyMismatchData? _mismatchError;
  LoyaltyScanErrorData? _scanError;
  LoyaltySuccessData? _successFeedback;
  Timer? _autoDismissTimer;
  Timer? _tokenDismissTimer;
  MobileScannerController? _scannerController;
  String? _lastScannedToken;
  DateTime? _lastScannedAt;
  bool _isPermissionDenied = false;
  bool _isResolving = false;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedMode = widget.initialMode;
    _currentScanResult = widget.initialScanResult;
    _scannerController = widget.controller ??
        MobileScannerController(
          formats: const [BarcodeFormat.qrCode],
          detectionSpeed: DetectionSpeed.normal,
          detectionTimeoutMs: 1500,
        );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isPermissionDenied) {
      _checkPermissionAndResume();
    }
  }

  Future<void> _checkPermissionAndResume() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      if (mounted) {
        setState(() {
          _isPermissionDenied = false;
        });
        await _scannerController?.start();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoDismissTimer?.cancel();
    _tokenDismissTimer?.cancel();
    if (widget.controller == null) {
      _scannerController?.dispose();
    }
    super.dispose();
  }

  void _handleBarcodeDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    final token = rawValue.trim();
    final now = DateTime.now();

    // If currently resolving or confirming or already displaying result card/mismatch/error/success, ignore
    if (_isResolving ||
        _isConfirming ||
        _currentScanResult != null ||
        _mismatchError != null ||
        _scanError != null ||
        _successFeedback != null) {
      return;
    }

    // Debounce: ignore repeated detections within 3s for identical token,
    // or within 1.5s for any scan
    if (_lastScannedToken == token &&
        _lastScannedAt != null &&
        now.difference(_lastScannedAt!) < const Duration(seconds: 3)) {
      return;
    }
    if (_lastScannedAt != null &&
        now.difference(_lastScannedAt!) < const Duration(milliseconds: 1500)) {
      return;
    }

    _lastScannedAt = now;
    HapticFeedback.mediumImpact();

    _tokenDismissTimer?.cancel();
    _tokenDismissTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _lastScannedToken = null;
        });
      }
    });

    setState(() {
      _lastScannedToken = token;
    });

    if (mounted) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          key: const Key('loyalty_scanned_token_snackbar'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          ),
          backgroundColor: context.appTheme.brandInk,
          content: Row(
            children: [
              Icon(
                Icons.qr_code_2_rounded,
                color: context.appTheme.brandHighlight,
                size: 22,
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Code Detected',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.appTheme.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      token,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    _processScannedToken(token);
  }

  Future<void> _processScannedToken(String token) async {
    final scanModeAtStart = _selectedMode;
    _autoDismissTimer?.cancel();
    setState(() {
      _isResolving = true;
      _currentScanResult = null;
      _mismatchError = null;
      _scanError = null;
      _successFeedback = null;
    });

    final result =
        await ref.read(loyaltyScanProvider.notifier).scanToken(token);

    if (!mounted || _selectedMode != scanModeAtStart) return;

    setState(() {
      _isResolving = false;
    });

    result.when(
      success: (scanResult) {
        final expectedAction =
            _selectedMode == LoyaltyScanMode.stamp ? 'stamp' : 'redeem';

        // PRD A-19 Guard: If token action doesn't match selected mode,
        // NEVER reveal 3A-3 result card, NEVER auto-switch modes, show mismatch error.
        if (scanResult.action != expectedAction) {
          HapticFeedback.heavyImpact();
          setState(() {
            _currentScanResult = null;
            _successFeedback = null;
            _scanError = null;
            _mismatchError = LoyaltyMismatchData(
              scannedAction: scanResult.action,
              expectedAction: expectedAction,
              scannedCustomerName: scanResult.customerName,
            );
          });
          return;
        }

        // PRD A-21 Guard: Redeem mode is only ever offered when rewardReady == true
        if (expectedAction == 'redeem' && !scanResult.rewardReady) {
          HapticFeedback.heavyImpact();
          setState(() {
            _currentScanResult = null;
            _successFeedback = null;
            _mismatchError = null;
            _scanError = LoyaltyScanErrorData(
              isNotFound: false,
              title: 'Reward Not Ready',
              message:
                  "This customer's card has ${scanResult.stamps}/${scanResult.totalRequired} stamps. Rewards can only be redeemed when the card is completely full.",
              statusCode: 409,
              errorCode: 'REWARD_NOT_READY',
              onRetry: null,
            );
          });
          return;
        }

        // Matching scan -> show 3A-3 result card
        HapticFeedback.mediumImpact();
        setState(() {
          _mismatchError = null;
          _scanError = null;
          _successFeedback = null;
          _currentScanResult = scanResult;
        });
      },
      failure: (message, statusCode, errorCode) {
        HapticFeedback.heavyImpact();
        final isNotFound = statusCode == 404 || errorCode == 'TOKEN_NOT_FOUND';
        setState(() {
          _currentScanResult = null;
          _mismatchError = null;
          _successFeedback = null;
          _scanError = LoyaltyScanErrorData(
            isNotFound: isNotFound,
            title: isNotFound ? 'QR Code Not Found' : 'Scan Resolution Failed',
            message: isNotFound
                ? "This QR code doesn't match any customer. Ask the customer to pull up their loyalty card in the customer app."
                : message,
            statusCode: statusCode,
            errorCode: errorCode,
            onRetry: () => _processScannedToken(token),
          );
        });
      },
    );
  }

  void _onSelectMode(LoyaltyScanMode mode) {
    if (_selectedMode != mode) {
      HapticFeedback.selectionClick();
      _autoDismissTimer?.cancel();
      ref.read(loyaltyScanProvider.notifier).clearScan();
      setState(() {
        _selectedMode = mode;
        _isResolving = false;
        _isConfirming = false;
        _currentScanResult = null;
        _mismatchError = null;
        _scanError = null;
        _successFeedback = null;
      });
    }
  }

  Future<void> _handleConfirmScan(LoyaltyScanResult result) async {
    if (_isConfirming || _isResolving) return;

    // PRD A-21 Guard: Redeem only reachable when rewardReady == true
    if (result.isRedeemAction && !result.rewardReady) {
      HapticFeedback.heavyImpact();
      setState(() {
        _currentScanResult = null;
        _mismatchError = null;
        _successFeedback = null;
        _scanError = LoyaltyScanErrorData(
          isNotFound: false,
          title: 'Reward Not Ready',
          message:
              "This customer's card isn't full yet (${result.stamps}/${result.totalRequired} stamps). Cannot redeem reward.",
          statusCode: 409,
          errorCode: 'REWARD_NOT_READY',
          onRetry: null,
        );
      });
      return;
    }

    _autoDismissTimer?.cancel();
    setState(() {
      _isConfirming = true;
    });

    final notifier = ref.read(loyaltyScanProvider.notifier);
    final Result<LoyaltyScanResult> actionResult;

    if (result.isRedeemAction) {
      actionResult = await notifier.confirmRedeem(result);
    } else {
      actionResult = await notifier.confirmStamp(result);
    }

    if (!mounted) return;

    setState(() {
      _isConfirming = false;
    });

    actionResult.when(
      success: (updated) {
        HapticFeedback.mediumImpact();
        notifier.clearScan();

        // Show brief visible celebratory feedback (<600ms) per PRD A-22 & Skill §3
        setState(() {
          _currentScanResult = null;
          _mismatchError = null;
          _scanError = null;
          _successFeedback = LoyaltySuccessData(
            action: result.action,
            customerName: updated.customerName,
            stamps: updated.stamps,
            totalRequired: updated.totalRequired,
          );
        });
      },
      failure: (message, statusCode, errorCode) {
        HapticFeedback.heavyImpact();
        final isConflict = statusCode == 409;
        final isNotFound = statusCode == 404;

        setState(() {
          _currentScanResult = null;
          _mismatchError = null;
          _successFeedback = null;
          _scanError = LoyaltyScanErrorData(
            isNotFound: isNotFound,
            title: isConflict
                ? (result.isRedeemAction
                    ? 'Redemption Conflict'
                    : 'Stamp Conflict')
                : (isNotFound ? 'Customer Not Found' : 'Operation Failed'),
            message: message,
            statusCode: statusCode,
            errorCode: errorCode,
            onRetry: !isConflict && !isNotFound
                ? () => _handleConfirmScan(result)
                : null,
          );
        });
      },
    );
  }

  void _dismissScan() {
    HapticFeedback.lightImpact();
    _autoDismissTimer?.cancel();
    ref.read(loyaltyScanProvider.notifier).clearScan();
    setState(() {
      _isConfirming = false;
      _currentScanResult = null;
      _mismatchError = null;
      _scanError = null;
      _successFeedback = null;
    });
  }

  void _dismissMismatch() {
    HapticFeedback.lightImpact();
    _autoDismissTimer?.cancel();
    ref.read(loyaltyScanProvider.notifier).clearScan();
    setState(() {
      _mismatchError = null;
    });
  }

  void _dismissScanError() {
    HapticFeedback.lightImpact();
    _autoDismissTimer?.cancel();
    ref.read(loyaltyScanProvider.notifier).clearScan();
    setState(() {
      _scanError = null;
    });
  }

  void _dismissSuccess() {
    _autoDismissTimer?.cancel();
    if (mounted) {
      setState(() {
        _successFeedback = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space5,
        vertical: AppTokens.space6,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top segmented mode switcher
              _buildModeSegmentedControl(theme),
              const SizedBox(height: AppTokens.space6),

              // Main body: Animated transition between Scanner, Mismatch Error,
              // Result Card, and Celebratory Success Feedback views
              AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : AppTokens.motionStandard,
                switchInCurve: AppTokens.curveEnter,
                switchOutCurve: AppTokens.curveExit,
                transitionBuilder: (child, animation) {
                  if (reduceMotion) return child;
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildCurrentMainView(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentMainView(AppThemeExtension theme) {
    if (_successFeedback != null) {
      return KeyedSubtree(
        key: const ValueKey('loyalty_success_view'),
        child: LoyaltySuccessFeedbackView(
          data: _successFeedback!,
          onCompleted: _dismissSuccess,
        ),
      );
    }

    if (_mismatchError != null) {
      return KeyedSubtree(
        key: const ValueKey('loyalty_mismatch_view'),
        child: LoyaltyMismatchErrorView(
          data: _mismatchError!,
          onDismiss: _dismissMismatch,
        ),
      );
    }

    if (_scanError != null) {
      return KeyedSubtree(
        key: const ValueKey('loyalty_scan_error_view'),
        child: LoyaltyScanErrorView(
          data: _scanError!,
          onDismiss: _dismissScanError,
        ),
      );
    }

    if (_currentScanResult != null) {
      return KeyedSubtree(
        key: const ValueKey('loyalty_result_card_view'),
        child: LoyaltyCardView(
          scanResult: _currentScanResult!,
          isLoading: _isConfirming,
          onConfirm: () => _handleConfirmScan(_currentScanResult!),
          onCancel: _dismissScan,
        ),
      );
    }

    return KeyedSubtree(
      key: const ValueKey('loyalty_viewfinder_view'),
      child: Column(
        children: [
          // Live camera preview viewfinder
          Center(
            child: _buildScannerPlaceholder(theme),
          ),
          if (_lastScannedToken != null) ...[
            const SizedBox(height: AppTokens.space4),
            _buildScannedTokenBanner(theme),
          ],
          const SizedBox(height: AppTokens.space6),

          // Instructional microcopy below viewfinder
          _buildInstructionText(theme),
        ],
      ),
    );
  }

  /// Segmented control pill switcher: Add Stamp | Redeem.
  Widget _buildModeSegmentedControl(AppThemeExtension theme) {
    return Container(
      key: const Key('loyalty_mode_switch'),
      height: 52,
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
        children: [
          Expanded(
            child: _ModeSegmentButton(
              key: const Key('loyalty_mode_stamp'),
              label: 'Add Stamp',
              icon: Icons.add_circle_outline_rounded,
              isSelected: _selectedMode == LoyaltyScanMode.stamp,
              onTap: () => _onSelectMode(LoyaltyScanMode.stamp),
            ),
          ),
          const SizedBox(width: AppTokens.space1),
          Expanded(
            child: _ModeSegmentButton(
              key: const Key('loyalty_mode_redeem'),
              label: 'Redeem',
              icon: Icons.card_giftcard_rounded,
              isSelected: _selectedMode == LoyaltyScanMode.redeem,
              onTap: () => _onSelectMode(LoyaltyScanMode.redeem),
            ),
          ),
        ],
      ),
    );
  }

  /// Banner displaying the raw scanned QR token (Task 3B-1 proof of detection).
  Widget _buildScannedTokenBanner(AppThemeExtension theme) {
    return Container(
      key: const Key('loyalty_scanned_token_banner'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space3,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceCream,
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        border: Border.all(
          color: theme.brandHighlight,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTokens.space1),
            decoration: BoxDecoration(
              color: theme.brandHighlight.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: 16,
              color: theme.brandInk,
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SCANNED QR TOKEN',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: theme.textSecondary,
                  ),
                ),
                Text(
                  _lastScannedToken!,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.brandInk,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: theme.textSecondary),
            onPressed: () {
              _tokenDismissTimer?.cancel();
              setState(() {
                _lastScannedToken = null;
              });
            },
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  /// Brand-styled permission-denied fallback view with open-settings affordance.
  Widget _buildPermissionDeniedView(AppThemeExtension theme) {
    return Container(
      key: const Key('loyalty_camera_permission_view'),
      color: theme.surfaceCream,
      padding: const EdgeInsets.all(AppTokens.space5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.surfaceCreamAlt2,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.divider,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.videocam_off_outlined,
              size: 26,
              color: theme.brandInk,
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          Text(
            'Camera Access Needed',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.brandInk,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          Text(
            'Camera access is needed to scan customer loyalty QR codes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: theme.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          SizedBox(
            height: 42,
            child: BrandButton(
              key: const Key('loyalty_open_settings_button'),
              text: 'Open Settings',
              icon: Icons.settings_outlined,
              height: 42,
              width: 180,
              onPressed: () async {
                await openAppSettings();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Initializing/placeholder visual inside viewfinder reticle.
  Widget _buildScannerInitializing(AppThemeExtension theme) {
    final isStamp = _selectedMode == LoyaltyScanMode.stamp;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: AppTokens.motionStandard,
            curve: AppTokens.curveEnter,
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.surfaceCreamAlt,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.brandHighlight.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            child: Icon(
              isStamp
                  ? Icons.qr_code_scanner_rounded
                  : Icons.redeem_rounded,
              size: 34,
              color: theme.brandInk,
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space3,
              vertical: AppTokens.space1 + 1,
            ),
            decoration: BoxDecoration(
              color: theme.surfaceCreamAlt2,
              borderRadius: AppTokens.borderRadiusPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 13,
                  color: theme.textSecondary,
                ),
                const SizedBox(width: AppTokens.space1),
                Text(
                  'Camera Preview',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Camera-preview viewfinder box with live MobileScanner and brand reticle overlay.
  Widget _buildScannerPlaceholder(AppThemeExtension theme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size =
            (constraints.maxWidth - AppTokens.space6 * 2).clamp(260.0, 300.0);

        return GestureDetector(
          onTap: () {
            if (kDebugMode) {
              final token = _selectedMode == LoyaltyScanMode.stamp
                  ? 'de431a6a-6282-498b-b8a2-835eb766036b'
                  : 'f6233460-2297-497f-8e5f-19a4dd240404';
              _processScannedToken(token);
            }
          },
          onDoubleTap: () {
            if (kDebugMode) {
              // Alternate token for testing 409 conflict
              final token = _selectedMode == LoyaltyScanMode.stamp
                  ? '6a9f79e1-d1e2-42c8-b1f7-088499aa6583'
                  : 'f6233460-2297-497f-8e5f-19a4dd240404';
              _processScannedToken(token);
            }
          },
          child: Container(
            key: const Key('loyalty_scanner_placeholder'),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.surfaceCream,
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            border: Border.all(
              color: theme.divider,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : theme.brandInk.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge - 1.5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Live Camera View
                MobileScanner(
                  controller: _scannerController,
                  fit: BoxFit.cover,
                  onDetect: _handleBarcodeDetect,
                  placeholderBuilder: (context) =>
                      _buildScannerInitializing(theme),
                  errorBuilder: (context, error) {
                    if (error.errorCode ==
                        MobileScannerErrorCode.permissionDenied) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_isPermissionDenied) {
                          setState(() {
                            _isPermissionDenied = true;
                          });
                        }
                      });
                      return _buildPermissionDeniedView(theme);
                    }
                    return _buildScannerInitializing(theme);
                  },
                ),

                // Subtle coordinate grid background pattern overlay
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ViewfinderGridPainter(
                        gridColor: theme.divider.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),

                // 4 Corner brackets (Viewfinder reticle overlay)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ViewfinderCornersPainter(
                        cornerColor: theme.brandHighlight,
                      ),
                    ),
                  ),
                ),

                // Brand-styled resolving overlay indicator while network call is in flight
                if (_isResolving)
                  Positioned.fill(
                    child: Container(
                      key: const Key('loyalty_scan_resolving_indicator'),
                      color: theme.brandInk.withValues(alpha: 0.70),
                      padding: const EdgeInsets.all(AppTokens.space4),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 38,
                              height: 38,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.brandHighlight,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTokens.space3),
                            Text(
                              'Resolving loyalty card...',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  /// Instructional text that transitions smoothly per mode.
  Widget _buildInstructionText(AppThemeExtension theme) {
    final isStamp = _selectedMode == LoyaltyScanMode.stamp;

    return AnimatedSwitcher(
      duration: AppTokens.motionStandard,
      switchInCurve: AppTokens.curveEnter,
      switchOutCurve: AppTokens.curveExit,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<LoyaltyScanMode>(_selectedMode),
        child: Column(
          children: [
            Text(
              isStamp ? 'Scan to Add Stamp' : 'Scan to Redeem Reward',
              key: const Key('loyalty_instruction_title'),
              textAlign: TextAlign.center,
              style: AppTypography.sectionHeader(color: theme.brandInk),
            ),
            const SizedBox(height: AppTokens.space2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                isStamp
                    ? 'Point the camera at the customer’s stamp QR code to add a stamp to their card.'
                    : 'Point the camera at the customer’s redeem QR code when their card has reached 10 stamps.',
                key: const Key('loyalty_instruction_text'),
                textAlign: TextAlign.center,
                style: AppTypography.body(color: theme.textSecondary).copyWith(
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual option button within the segmented mode switch.
class _ModeSegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeSegmentButton({
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
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          onTap: onTap,
          child: AnimatedContainer(
            duration: reduceMotion ? Duration.zero : AppTokens.motionMicro,
            curve: AppTokens.curveEnter,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? theme.brandHighlight : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.brandHighlight.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppTokens.brandInk : theme.textSecondary,
                ),
                const SizedBox(width: AppTokens.space2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTokens.brandInk : theme.textSecondary,
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

/// Custom painter for the 4 rounded corner brackets defining the camera viewfinder.
class _ViewfinderCornersPainter extends CustomPainter {
  final Color cornerColor;

  _ViewfinderCornersPainter({required this.cornerColor});

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 24.0;
    const length = 28.0;
    const strokeWidth = 3.5;

    final paint = Paint()
      ..color = cornerColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final left = padding;
    final top = padding;
    final right = size.width - padding;
    final bottom = size.height - padding;

    // Top-Left corner
    canvas.drawLine(Offset(left, top + length), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + length, top), paint);

    // Top-Right corner
    canvas.drawLine(Offset(right - length, top), Offset(right, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right, top + length), paint);

    // Bottom-Left corner
    canvas.drawLine(Offset(left, bottom - length), Offset(left, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left + length, bottom), paint);

    // Bottom-Right corner
    canvas.drawLine(Offset(right - length, bottom), Offset(right, bottom), paint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - length), paint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderCornersPainter oldDelegate) =>
      oldDelegate.cornerColor != cornerColor;
}

/// Custom painter rendering a subtle coordinate grid inside the viewfinder.
class _ViewfinderGridPainter extends CustomPainter {
  final Color gridColor;

  _ViewfinderGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final stepX = size.width / 3.0;
    final stepY = size.height / 3.0;

    // Vertical rule of thirds lines
    canvas.drawLine(Offset(stepX, 0), Offset(stepX, size.height), paint);
    canvas.drawLine(Offset(stepX * 2, 0), Offset(stepX * 2, size.height), paint);

    // Horizontal rule of thirds lines
    canvas.drawLine(Offset(0, stepY), Offset(size.width, stepY), paint);
    canvas.drawLine(Offset(0, stepY * 2), Offset(size.width, stepY * 2), paint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderGridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor;
}

/// Brand-styled inline error state for mode mismatch during loyalty scanning.
///
/// Implements `PRD.md` §3.4 (A-19) and `polished-flutter-ui` §3:
/// - Gentle horizontal shake animation on entrance
/// - Soft red pulse border and subtle ambient glow
/// - Explicit plain-language microcopy ("This code is for adding a stamp, not redeeming" etc.)
/// - Clear recovery guidance and "Back to Scanner" CTA
/// - Crucially: NEVER reveals 3A-3's result card, NEVER auto-switches modes
class LoyaltyMismatchErrorView extends StatefulWidget {
  final LoyaltyMismatchData data;
  final VoidCallback onDismiss;
  final Duration autoDismissDuration;

  const LoyaltyMismatchErrorView({
    super.key,
    required this.data,
    required this.onDismiss,
    this.autoDismissDuration = const Duration(seconds: 5),
  });

  @override
  State<LoyaltyMismatchErrorView> createState() =>
      _LoyaltyMismatchErrorViewState();
}

class _LoyaltyMismatchErrorViewState extends State<LoyaltyMismatchErrorView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    _shakeController.forward();
    HapticFeedback.heavyImpact();

    if (widget.autoDismissDuration > Duration.zero) {
      _autoDismissTimer = Timer(widget.autoDismissDuration, () {
        if (mounted) {
          widget.onDismiss();
        }
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpectedStamp = widget.data.isExpectedStamp;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        if (reduceMotion) return child!;
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0.0),
          child: child,
        );
      },
      child: Container(
        key: const Key('loyalty_mismatch_error_view'),
        decoration: BoxDecoration(
          color: theme.surfaceCream,
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          border: Border.all(
            color: theme.error,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.error.withValues(alpha: isDark ? 0.32 : 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppTokens.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: Mode mismatch badge + close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space3,
                    vertical: AppTokens.space1 + 1,
                  ),
                  decoration: BoxDecoration(
                    color: theme.errorBackground,
                    borderRadius: AppTokens.borderRadiusPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: theme.error,
                      ),
                      const SizedBox(width: AppTokens.space1),
                      Text(
                        'MODE MISMATCH',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: theme.error,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('loyalty_mismatch_close_button'),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: theme.textSecondary,
                  ),
                  tooltip: 'Dismiss error',
                  onPressed: widget.onDismiss,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space4),

            // Icon hero
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.errorBackground,
                  border: Border.all(
                    color: theme.error,
                    width: 2.0,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.sync_problem_rounded,
                    size: 36,
                    color: theme.error,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space3),

            // Title
            Center(
              child: Text(
                isExpectedStamp
                    ? 'Redeem Code Scanned'
                    : 'Stamp Code Scanned',
                key: const Key('loyalty_mismatch_title'),
                textAlign: TextAlign.center,
                style: AppTypography.screenTitle(color: theme.brandInk).copyWith(
                  fontSize: 22,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space2),

            // Plain-language message (per PRD A-19)
            Center(
              child: Text(
                isExpectedStamp
                    ? 'This code is for redeeming a reward, not adding a stamp.'
                    : 'This code is for adding a stamp, not redeeming.',
                key: const Key('loyalty_mismatch_message'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.error,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space4),

            // Recovery guidance card
            Container(
              padding: const EdgeInsets.all(AppTokens.space3 + 2),
              decoration: BoxDecoration(
                color: theme.surfaceCreamAlt,
                borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                border: Border.all(
                  color: theme.divider,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1.0),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: theme.brandInk,
                    ),
                  ),
                  const SizedBox(width: AppTokens.space2 + 2),
                  Expanded(
                    child: Text(
                      isExpectedStamp
                          ? 'To process a redemption, switch the scanner above to Redeem mode. Otherwise, ask the customer for their stamp QR code.'
                          : 'To add a stamp, switch the scanner above to Add Stamp mode. This customer card is not yet eligible for redemption.',
                      key: const Key('loyalty_mismatch_guidance'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.4,
                        color: theme.brandInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space5),

            // Recovery action button
            BrandButton(
              key: const Key('loyalty_mismatch_dismiss_button'),
              text: 'Back to Scanner',
              icon: Icons.qr_code_scanner_rounded,
              height: 52.0,
              onPressed: widget.onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

/// Celebratory success-feedback confirmation card with checkmark scale animation.
///
/// Implements `PRD.md` §3.4 (A-22) and `polished-flutter-ui` §3:
/// - Brief visible confirmation (<600ms, specifically 550ms total display)
/// - Checkmark scale entrance animation with spring curve
/// - Haptic feedback triggered alongside visual
/// - Returns cleanly to scanner with mode selection unchanged
class LoyaltySuccessFeedbackView extends StatefulWidget {
  final LoyaltySuccessData data;
  final VoidCallback onCompleted;
  final Duration duration;

  const LoyaltySuccessFeedbackView({
    super.key,
    required this.data,
    required this.onCompleted,
    this.duration = const Duration(milliseconds: 550),
  });

  @override
  State<LoyaltySuccessFeedbackView> createState() =>
      _LoyaltySuccessFeedbackViewState();
}

class _LoyaltySuccessFeedbackViewState extends State<LoyaltySuccessFeedbackView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onCompleted();
      }
    });

    _animController.forward();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRedeem = widget.data.isRedeem;
    final accentColor = isRedeem ? theme.brandHighlight : theme.success;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return GestureDetector(
      onTap: widget.onCompleted,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          if (reduceMotion) {
            return child!;
          }
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: Container(
          key: const Key('loyalty_success_feedback_view'),
          decoration: BoxDecoration(
            color: theme.surfaceCream,
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            border: Border.all(
              color: accentColor,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: isDark ? 0.38 : 0.22),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space5,
            vertical: AppTokens.space8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular animated badge
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRedeem
                      ? theme.brandHighlight
                      : theme.successBackground,
                  border: Border.all(
                    color: isRedeem ? AppTokens.brandInk : theme.success,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isRedeem
                        ? Icons.celebration_rounded
                        : Icons.check_rounded,
                    size: 48,
                    color: isRedeem ? AppTokens.brandInk : theme.success,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space4),

              // Title
              Text(
                isRedeem ? 'Reward Redeemed!' : 'Stamp Added!',
                key: const Key('loyalty_success_title'),
                textAlign: TextAlign.center,
                style: AppTypography.screenTitle(color: theme.brandInk).copyWith(
                  fontSize: 24,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppTokens.space2),

              // Customer Subtitle
              Text(
                isRedeem
                    ? '${widget.data.customerName} · 1x Artisan Pizza'
                    : '${widget.data.customerName} · Card updated',
                key: const Key('loyalty_success_subtitle'),
                textAlign: TextAlign.center,
                style: AppTypography.labelCaption(color: theme.textSecondary).copyWith(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppTokens.space4),

              // Micro Status Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space3,
                  vertical: AppTokens.space1 + 1,
                ),
                decoration: BoxDecoration(
                  color: theme.surfaceCreamAlt,
                  borderRadius: AppTokens.borderRadiusPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: accentColor,
                    ),
                    const SizedBox(width: AppTokens.space1),
                    Text(
                      isRedeem
                          ? 'Card reset to 0 stamps'
                          : 'Ready for next scan',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.brandInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand-styled error view displayed when scan resolution fails (e.g. 404 Token Not Found or network error).
///
/// Implements `PRD.md` §3.4 (A-18, A-19), `ARCHITECTURE.md` §4, and `TASKS.md` Phase 3B (3B-2):
/// - 404 state: "This QR code doesn't match any customer. Ask the customer to pull up their loyalty card in the customer app."
/// - Network/server error state with optional retry
/// - Clean dismissal back to active scanning
class LoyaltyScanErrorView extends StatelessWidget {
  final LoyaltyScanErrorData data;
  final VoidCallback onDismiss;

  const LoyaltyScanErrorView({
    super.key,
    required this.data,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNotFound = data.isNotFound;

    return Container(
      key: const Key('loyalty_scan_error_card'),
      decoration: BoxDecoration(
        color: theme.surfaceCream,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(
          color: theme.error,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.error.withValues(alpha: isDark ? 0.32 : 0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Badge + close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space3,
                  vertical: AppTokens.space1 + 1,
                ),
                decoration: BoxDecoration(
                  color: theme.errorBackground,
                  borderRadius: AppTokens.borderRadiusPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 14,
                      color: theme.error,
                    ),
                    const SizedBox(width: AppTokens.space1),
                    Text(
                      isNotFound ? '404 NOT FOUND' : 'RESOLUTION FAILED',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: theme.error,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('loyalty_error_close_button'),
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: theme.textSecondary,
                ),
                tooltip: 'Dismiss error',
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),

          // Icon hero
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.errorBackground,
                border: Border.all(
                  color: theme.error,
                  width: 2.0,
                ),
              ),
              child: Center(
                child: Icon(
                  isNotFound
                      ? Icons.search_off_rounded
                      : Icons.wifi_off_rounded,
                  size: 36,
                  color: theme.error,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space3),

          // Title
          Center(
            child: Text(
              data.title,
              key: const Key('loyalty_scan_error_title'),
              textAlign: TextAlign.center,
              style: AppTypography.screenTitle(color: theme.brandInk).copyWith(
                fontSize: 22,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space2),

          // Message
          Center(
            child: Text(
              data.message,
              key: const Key('loyalty_scan_error_message'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space5),

          // Action button(s)
          if (data.onRetry != null && !isNotFound) ...[
            Row(
              children: [
                Expanded(
                  child: BrandButton.secondary(
                    key: const Key('loyalty_error_retry_button'),
                    text: 'Try Again',
                    icon: Icons.refresh_rounded,
                    height: 52.0,
                    onPressed: data.onRetry,
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: BrandButton(
                    key: const Key('loyalty_error_dismiss_button'),
                    text: 'Back to Scanner',
                    icon: Icons.qr_code_scanner_rounded,
                    height: 52.0,
                    onPressed: onDismiss,
                  ),
                ),
              ],
            ),
          ] else ...[
            BrandButton(
              key: const Key('loyalty_error_dismiss_button'),
              text: 'Back to Scanner',
              icon: Icons.qr_code_scanner_rounded,
              height: 52.0,
              onPressed: onDismiss,
            ),
          ],
        ],
      ),
    );
  }
}


