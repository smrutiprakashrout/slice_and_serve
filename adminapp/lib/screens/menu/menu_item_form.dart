import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/result.dart';
import '../../models/category.dart';
import '../../models/menu_item.dart';
import '../../providers/menu_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_button.dart';

/// Shared Create / Edit form for menu items in Slice & Serve Admin.
///
/// Adheres to `PRD.md` §3.3 (A-11, A-12, A-13, A-16) and polished-flutter-ui §4 (Forms):
/// - Form fields in strict sequence:
///   1. Name (required)
///   2. Subtitle (optional)
///   3. Price (numeric, required, positive only)
///   4. Category picker (mock list for Stage A)
///   5. Veg / Non-Veg toggle (clear segmented control with labels)
///   6. Featured toggle (standard switch)
/// - NO image field or upload UI per PRD A-16 (permanent decision).
/// - Client-side validation with inline soft errors.
/// - Server-side validation errors surfaced inline with consistent styling.
/// - Cancel / close action without mutating state.
class MenuItemForm extends ConsumerStatefulWidget {
  /// The existing item being edited, or `null` when creating a new item.
  final MenuItem? item;

  /// Optional callback invoked upon successful validation and submission.
  final ValueChanged<MenuItem>? onSave;

  const MenuItemForm({
    super.key,
    this.item,
    this.onSave,
  });

  /// Presents the [MenuItemForm] in a brand-styled modal bottom sheet.
  ///
  /// Returns the newly created or updated [MenuItem], or `null` if cancelled.
  static Future<MenuItem?> show(
    BuildContext context, {
    MenuItem? item,
  }) {
    return showModalBottomSheet<MenuItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MenuItemForm(item: item),
    );
  }

  @override
  ConsumerState<MenuItemForm> createState() => _MenuItemFormState();
}

class _MenuItemFormState extends ConsumerState<MenuItemForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _priceController;

  late String _selectedCategorySlug;
  late String _selectedType; // 'veg' | 'non-veg'
  late bool _isFeatured;

  String? _nameError;
  String? _subtitleError;
  String? _priceError;
  String? _categoryError;
  String? _generalError;
  bool _isSubmitting = false;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final initialItem = widget.item;

    _nameController = TextEditingController(text: initialItem?.name ?? '');
    _subtitleController =
        TextEditingController(text: initialItem?.subtitle ?? '');
    _priceController = TextEditingController(
      text: initialItem != null ? initialItem.price.toStringAsFixed(0) : '',
    );

    _selectedCategorySlug = initialItem?.categorySlug ?? '';
    _selectedType = initialItem?.type ?? 'veg';
    _isFeatured = initialItem?.featured ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool isValid = true;
    final name = _nameController.text.trim();
    final priceStr = _priceController.text.trim();

    final categories = ref.read(categoriesProvider).value;
    final effectiveSlug = _selectedCategorySlug.isNotEmpty
        ? _selectedCategorySlug
        : (categories != null && categories.isNotEmpty
            ? categories.first.slug
            : '');

    setState(() {
      _generalError = null;

      if (name.isEmpty) {
        _nameError = 'Please enter an item name.';
        isValid = false;
      } else {
        _nameError = null;
      }

      if (priceStr.isEmpty) {
        _priceError = 'Please enter a price.';
        isValid = false;
      } else {
        final parsed = double.tryParse(priceStr);
        if (parsed == null || parsed <= 0) {
          _priceError = 'Please enter a valid price greater than ₹0.';
          isValid = false;
        } else {
          _priceError = null;
        }
      }

      if (effectiveSlug.isEmpty) {
        _categoryError = 'Please select a category.';
        isValid = false;
      } else {
        _categoryError = null;
      }
    });

    return isValid;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    if (!_validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _categoryError = null;
      _subtitleError = null;
      _generalError = null;
    });

    HapticFeedback.lightImpact();

    final categories = ref.read(categoriesProvider).value;
    final effectiveSlug = _selectedCategorySlug.isNotEmpty
        ? _selectedCategorySlug
        : (categories != null && categories.isNotEmpty
            ? categories.first.slug
            : '');

    final parsedPrice = double.parse(_priceController.text.trim());
    final itemToSubmit = MenuItem(
      id: widget.item?.id ?? '',
      name: _nameController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      price: parsedPrice,
      categorySlug: effectiveSlug,
      type: _selectedType,
      featured: _isFeatured,
      image: widget.item?.image,
      available: widget.item?.available ?? true,
    );

    final Result<MenuItem> result;
    if (isEditing) {
      result = await ref
          .read(menuProvider.notifier)
          .updateMenuItem(widget.item!.id, itemToSubmit);
    } else {
      result = await ref
          .read(menuProvider.notifier)
          .createMenuItem(itemToSubmit);
    }

    if (!mounted) return;

    result.when(
      success: (savedItem) {
        setState(() {
          _isSubmitting = false;
        });
        HapticFeedback.lightImpact();
        widget.onSave?.call(savedItem);
        Navigator.of(context).pop(savedItem);
      },
      failure: (message, statusCode, errorCode) {
        setState(() {
          _isSubmitting = false;
        });
        HapticFeedback.mediumImpact();

        final isValidation = statusCode == 400 ||
            errorCode == 'VALIDATION_ERROR' ||
            message.toLowerCase().contains('field') ||
            message.toLowerCase().contains('category');

        if (isValidation) {
          final lower = message.toLowerCase();
          setState(() {
            if (lower.contains('name')) {
              _nameError = message;
            } else if (lower.contains('price')) {
              _priceError = message;
            } else if (lower.contains('category')) {
              _categoryError = message;
            } else if (lower.contains('subtitle')) {
              _subtitleError = message;
            } else {
              _generalError = message;
            }
          });
        } else {
          setState(() {
            _generalError = message;
          });
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Category>>>(categoriesProvider, (prev, next) {
      next.whenData((categories) {
        if (_selectedCategorySlug.isEmpty && categories.isNotEmpty) {
          setState(() {
            _selectedCategorySlug = categories.first.slug;
          });
        }
      });
    });

    final theme = context.appTheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: AppTokens.space3),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.divider,
                    borderRadius: AppTokens.borderRadiusPill,
                  ),
                ),
              ),

              // Sheet Header with Title & Close Action
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space6,
                  AppTokens.space3,
                  AppTokens.space4,
                  AppTokens.space2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Menu Item' : 'New Menu Item',
                      style: AppTypography.screenTitle(color: theme.brandInk)
                          .copyWith(fontSize: 22),
                    ),
                    IconButton(
                      key: const Key('menu_form_close_button'),
                      icon: Icon(
                        Icons.close_rounded,
                        color: theme.brandInk,
                        size: 24,
                      ),
                      tooltip: 'Discard and close',
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop();
                            },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable Form Fields
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space6,
                    vertical: AppTokens.space4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Name Field (Required)
                      _buildFieldLabel(context, 'Item Name', isRequired: true),
                      const SizedBox(height: AppTokens.space2),
                      TextField(
                        key: const Key('menu_form_name_field'),
                        controller: _nameController,
                        enabled: !_isSubmitting,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: theme.brandInk,
                        ),
                        cursorColor: theme.brandInk,
                        decoration: InputDecoration(
                          hintText: 'e.g. Truffle Mushroom Pizza',
                          prefixIcon: Icon(
                            Icons.restaurant_rounded,
                            color: theme.textSecondary,
                            size: 20,
                          ),
                          errorText: _nameError,
                          errorStyle: GoogleFonts.inter(
                            color: theme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onChanged: (_) {
                          if (_nameError != null) {
                            setState(() => _nameError = null);
                          }
                        },
                      ),
                      const SizedBox(height: AppTokens.space5),

                      // 2. Subtitle Field (Optional)
                      _buildFieldLabel(context, 'Description / Subtitle',
                          isRequired: false),
                      const SizedBox(height: AppTokens.space2),
                      TextField(
                        key: const Key('menu_form_subtitle_field'),
                        controller: _subtitleController,
                        enabled: !_isSubmitting,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 2,
                        minLines: 1,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: theme.brandInk,
                        ),
                        cursorColor: theme.brandInk,
                        decoration: InputDecoration(
                          hintText: 'Short description or key ingredients',
                          prefixIcon: Icon(
                            Icons.notes_rounded,
                            color: theme.textSecondary,
                            size: 20,
                          ),
                          errorText: _subtitleError,
                          errorStyle: GoogleFonts.inter(
                            color: theme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onChanged: (_) {
                          if (_subtitleError != null) {
                            setState(() => _subtitleError = null);
                          }
                        },
                      ),
                      const SizedBox(height: AppTokens.space5),

                      // 3. Price Field (Required, numeric, positive)
                      _buildFieldLabel(context, 'Price (₹)', isRequired: true),
                      const SizedBox(height: AppTokens.space2),
                      TextField(
                        key: const Key('menu_form_price_field'),
                        controller: _priceController,
                        enabled: !_isSubmitting,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.brandInk,
                        ),
                        cursorColor: theme.brandInk,
                        decoration: InputDecoration(
                          hintText: '0',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '₹',
                              style: AppTypography.statNumber(
                                color: theme.brandInk,
                              ).copyWith(fontSize: 18),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 0,
                          ),
                          errorText: _priceError,
                          errorStyle: GoogleFonts.inter(
                            color: theme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onChanged: (_) {
                          if (_priceError != null) {
                            setState(() => _priceError = null);
                          }
                        },
                      ),
                      const SizedBox(height: AppTokens.space5),

                      // 4. Category Picker (Dropdown)
                      _buildFieldLabel(context, 'Category', isRequired: true),
                      const SizedBox(height: AppTokens.space2),
                      _buildCategoryPicker(context, theme),
                      const SizedBox(height: AppTokens.space5),

                      // 5. Veg / Non-Veg Segmented Toggle
                      _buildFieldLabel(context, 'Dietary Type',
                          isRequired: true),
                      const SizedBox(height: AppTokens.space2),
                      _buildDietarySegmentedToggle(context),
                      const SizedBox(height: AppTokens.space5),

                      // 6. Featured Toggle
                      _buildFeaturedToggle(context),
                      const SizedBox(height: AppTokens.space6),

                      // Inline General Error Banner if server returns unmapped validation error
                      if (_generalError != null) ...[
                        Container(
                          key: const Key('menu_form_general_error'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.space3,
                            vertical: AppTokens.space2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.errorBackground,
                            borderRadius: AppTokens.borderRadiusSmall,
                            border: Border.all(
                              color: theme.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: theme.error,
                                size: 16,
                              ),
                              const SizedBox(width: AppTokens.space2),
                              Expanded(
                                child: Text(
                                  _generalError!,
                                  style: GoogleFonts.inter(
                                    color: theme.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTokens.space4),
                      ],

                      // 7. Submit & Cancel Action Buttons
                      BrandButton(
                        key: const Key('menu_form_submit_button'),
                        text: isEditing ? 'Save Changes' : 'Add to Menu',
                        icon: isEditing
                            ? Icons.check_rounded
                            : Icons.add_circle_outline_rounded,
                        isLoading: _isSubmitting,
                        onPressed: _handleSubmit,
                      ),
                      const SizedBox(height: AppTokens.space3),
                      BrandButton.secondary(
                        key: const Key('menu_form_cancel_button'),
                        text: 'Cancel',
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                              },
                      ),
                      const SizedBox(height: AppTokens.space4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(BuildContext context, String label,
      {required bool isRequired}) {
    final theme = context.appTheme;

    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.brandInk,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: AppTokens.space1),
          Text(
            '*',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDietarySegmentedToggle(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      key: const Key('menu_form_type_toggle'),
      height: 48,
      padding: const EdgeInsets.all(AppTokens.space1),
      decoration: BoxDecoration(
        color: theme.surfaceCream,
        borderRadius: AppTokens.borderRadiusMedium,
        border: Border.all(color: theme.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDietaryOption(
              context: context,
              key: const Key('menu_form_type_veg'),
              label: 'Vegetarian',
              isSelected: _selectedType == 'veg',
              accentColor: theme.success,
              onTap: () {
                if (_selectedType != 'veg') {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedType = 'veg');
                }
              },
            ),
          ),
          const SizedBox(width: AppTokens.space1),
          Expanded(
            child: _buildDietaryOption(
              context: context,
              key: const Key('menu_form_type_non_veg'),
              label: 'Non-Vegetarian',
              isSelected: _selectedType == 'non-veg',
              accentColor: theme.error,
              onTap: () {
                if (_selectedType != 'non-veg') {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedType = 'non-veg');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryOption({
    required BuildContext context,
    required Key key,
    required String label,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final theme = context.appTheme;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return GestureDetector(
      key: key,
      onTap: _isSubmitting ? null : onTap,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : AppTokens.motionMicro,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? theme.background : Colors.transparent,
          borderRadius: AppTokens.borderRadiusSmall,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
          border: Border.all(
            color: isSelected ? theme.divider : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppTokens.space2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? theme.brandInk : theme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedToggle(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space3,
      ),
      decoration: BoxDecoration(
        color: theme.surfaceCream,
        borderRadius: AppTokens.borderRadiusMedium,
        border: Border.all(color: theme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _isFeatured
                  ? AppTokens.brandHighlight.withValues(alpha: 0.25)
                  : theme.surfaceCreamAlt,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star_rounded,
              size: 20,
              color: _isFeatured ? AppTokens.brandHighlight : theme.textSecondary,
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Featured Item',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.brandInk,
                  ),
                ),
                Text(
                  'Highlight in customer menu & promotions',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: const Key('menu_form_featured_switch'),
            value: _isFeatured,
            onChanged: _isSubmitting
                ? null
                : (val) {
                    HapticFeedback.lightImpact();
                    setState(() => _isFeatured = val);
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker(BuildContext context, AppThemeExtension theme) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => DropdownButtonFormField<String>(
        key: const Key('menu_form_category_picker'),
        initialValue: null,
        dropdownColor: theme.surfaceCream,
        borderRadius: AppTokens.borderRadiusMedium,
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: theme.brandInk,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.category_outlined,
            color: theme.textSecondary,
            size: 20,
          ),
          hintText: 'Loading categories...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: theme.textSecondary,
          ),
          errorText: _categoryError,
          errorStyle: GoogleFonts.inter(
            color: theme.error,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        items: const [],
        onChanged: null,
      ),
      error: (err, stack) => DropdownButtonFormField<String>(
        key: const Key('menu_form_category_picker'),
        initialValue: null,
        dropdownColor: theme.surfaceCream,
        borderRadius: AppTokens.borderRadiusMedium,
        icon: IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Retry loading categories',
          onPressed: () => ref.refresh(categoriesProvider),
        ),
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: theme.brandInk,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.category_outlined,
            color: theme.error,
            size: 20,
          ),
          hintText: 'Failed to load categories',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: theme.error,
          ),
          errorText: _categoryError,
          errorStyle: GoogleFonts.inter(
            color: theme.error,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        items: const [],
        onChanged: null,
      ),
      data: (fetchedCategories) {
        final categories = List<Category>.from(fetchedCategories);
        final effectiveCategorySlug = _selectedCategorySlug.isNotEmpty
            ? _selectedCategorySlug
            : (categories.isNotEmpty ? categories.first.slug : '');

        // If the item's slug is not present in fetched categories (e.g. legacy/custom),
        // insert a fallback option so the dropdown can safely pre-select and display it without crashing.
        if (effectiveCategorySlug.isNotEmpty &&
            !categories.any((c) => c.slug == effectiveCategorySlug)) {
          categories.insert(
            0,
            Category(
              id: 'fallback',
              name: effectiveCategorySlug[0].toUpperCase() +
                  effectiveCategorySlug.substring(1),
              slug: effectiveCategorySlug,
            ),
          );
        }

        return DropdownButtonFormField<String>(
          key: const Key('menu_form_category_picker'),
          initialValue:
              effectiveCategorySlug.isNotEmpty ? effectiveCategorySlug : null,
          dropdownColor: theme.surfaceCream,
          borderRadius: AppTokens.borderRadiusMedium,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: theme.brandInk,
          ),
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: theme.brandInk,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.category_outlined,
              color: theme.textSecondary,
              size: 20,
            ),
            errorText: _categoryError,
            errorStyle: GoogleFonts.inter(
              color: theme.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          items: categories.map((cat) {
            final iconPrefix = (cat.icon != null && cat.icon!.trim().isNotEmpty)
                ? '${cat.icon!.trim()}  '
                : '';
            return DropdownMenuItem<String>(
              value: cat.slug,
              child: Text('$iconPrefix${cat.name}'),
            );
          }).toList(),
          onChanged: _isSubmitting
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategorySlug = value;
                      _categoryError = null;
                    });
                  }
                },
        );
      },
    );
  }
}
