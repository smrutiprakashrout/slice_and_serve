import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_button.dart';
import 'main_shell.dart';

/// Admin login screen adhering to `PRD.md` §3.1 (A-1, A-2), `DESIGN_TOKENS.md`,
/// and `polished-flutter-ui` form guidelines.
///
/// Features:
/// - Username and obscured password fields with toggle
/// - Primary CTA using [BrandButton] with loading state
/// - Non-interactive inputs during submission
/// - Brand-styled inline error banner for validation and server error responses
/// - Strictly NO forgot-password, NO signup, NO remember-me (per PRD.md A-2)
/// - Full light and dark mode support
class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback? onToggleTheme;
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.onToggleTheme,
    this.onLoginSuccess,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _clearErrorIfPresent() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    // Validation: Empty fields check
    if (username.isEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _errorMessage = 'Please enter your username.';
      });
      _usernameFocusNode.requestFocus();
      return;
    }

    if (password.isEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _errorMessage = 'Please enter your password.';
      });
      _passwordFocusNode.requestFocus();
      return;
    }

    // Dismiss keyboard and start loading state
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result =
        await ref.read(authProvider.notifier).login(username, password);

    if (!mounted) return;

    result.when(
      success: (token) {
        HapticFeedback.lightImpact();
        setState(() {
          _isLoading = false;
        });

        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (context) => MainShell(
                onToggleTheme: widget.onToggleTheme,
              ),
            ),
          );
        }
      },
      failure: (message, statusCode, errorCode) {
        HapticFeedback.mediumImpact();
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space6,
                  vertical: AppTokens.space4,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - (AppTokens.space4 * 2))
                        .clamp(0.0, double.infinity),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top bar with brand pill & optional theme toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTokens.space3,
                                vertical: AppTokens.space1,
                              ),
                              decoration: BoxDecoration(
                                color: theme.surfaceCream,
                                borderRadius: AppTokens.borderRadiusPill,
                                border: Border.all(
                                  color: theme.divider,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.restaurant_rounded,
                                    size: 14,
                                    color: theme.brandInk,
                                  ),
                                  const SizedBox(width: AppTokens.space1),
                                  Text(
                                    'Slice and Serve Admin',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.brandInk,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.onToggleTheme != null)
                              IconButton(
                                key: const Key('login_theme_toggle_button'),
                                icon: Icon(
                                  isDark
                                      ? Icons.light_mode_outlined
                                      : Icons.dark_mode_outlined,
                                  color: theme.brandInk,
                                  size: 20,
                                ),
                                tooltip: isDark
                                    ? 'Switch to light mode'
                                    : 'Switch to dark mode',
                                onPressed: widget.onToggleTheme,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.space8),

                        // Headline & Subtitle
                        Text(
                          'Welcome back',
                          style: AppTypography.screenTitle(
                            color: theme.brandInk,
                          ).copyWith(
                            fontSize: 30,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space2),
                        Text(
                          'Sign in to manage kitchen orders, menu items, and customer rewards.',
                          style: AppTypography.body(
                            color: theme.textSecondary,
                          ).copyWith(
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space8),

                        // Form Section
                        // Username Field
                        Text(
                          'Username',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.brandInk,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space2),
                        TextField(
                          key: const Key('login_username_field'),
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          enabled: !_isLoading,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.text,
                          autofillHints: const [AutofillHints.username],
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: theme.brandInk,
                          ),
                          cursorColor: theme.brandInk,
                          decoration: InputDecoration(
                            hintText: 'Enter your admin username',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: theme.textSecondary,
                              size: 20,
                            ),
                          ),
                          onChanged: (_) => _clearErrorIfPresent(),
                        ),
                        const SizedBox(height: AppTokens.space5),

                        // Password Field
                        Text(
                          'Password',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.brandInk,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space2),
                        TextField(
                          key: const Key('login_password_field'),
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          enabled: !_isLoading,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: theme.brandInk,
                          ),
                          cursorColor: theme.brandInk,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: theme.textSecondary,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              key: const Key('login_password_toggle'),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: theme.textSecondary,
                                size: 20,
                              ),
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                            ),
                          ),
                          onChanged: (_) => _clearErrorIfPresent(),
                          onSubmitted: (_) => _handleSubmit(),
                        ),
                        const SizedBox(height: AppTokens.space4),

                        // Inline Error State Banner
                        AnimatedSwitcher(
                          duration: reduceMotion
                              ? Duration.zero
                              : AppTokens.motionStandard,
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _errorMessage != null
                              ? Container(
                                  key: const Key('login_error_banner'),
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTokens.space4,
                                    vertical: AppTokens.space3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.errorBackground,
                                    borderRadius: AppTokens.borderRadiusMedium,
                                    border: Border.all(
                                      color:
                                          theme.error.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Icon(
                                          Icons.error_outline_rounded,
                                          color: theme.error,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: AppTokens.space3),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: theme.error,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Flexible spacing pushes CTA to the thumb zone
                        const Spacer(),
                        const SizedBox(height: AppTokens.space6),

                        // Primary CTA in thumb zone
                        BrandButton(
                          key: const Key('login_submit_button'),
                          text: 'Sign In',
                          icon: Icons.arrow_forward_rounded,
                          isLoading: _isLoading,
                          onPressed: _handleSubmit,
                          height: 56,
                        ),
                        const SizedBox(height: AppTokens.space4),

                        // Subdued footer text
                        Center(
                          child: Text(
                            'Internal Shop Management • Android Only',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTokens.space2),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

