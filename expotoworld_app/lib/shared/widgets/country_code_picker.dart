/// Country Code Picker Widget
/// 
/// Provides country code selection for phone authentication.
library;

import 'dart:ui';

import 'package:circle_flags/circle_flags.dart';
import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// Country data model with dial code, flag, and phone number length constraints
class CountryCode {
  final String name;
  final String isoCode;
  final String dialCode;
  final int minLength;  // Minimum phone number length (without country code)
  final int maxLength;  // Maximum phone number length (without country code)

  const CountryCode({
    required this.name,
    required this.isoCode,
    required this.dialCode,
    this.minLength = 7,   // Default minimum
    this.maxLength = 15,  // Default maximum (E.164 limit)
  });

  /// Get the full dial code with + prefix
  String get fullDialCode => '+$dialCode';
  
  /// Validate phone number length for this country
  String? validateLength(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    // Remove leading 0 if present (common in many countries)
    final normalizedDigits = digits.startsWith('0') ? digits.substring(1) : digits;
    
    if (normalizedDigits.isEmpty) {
      return 'Please enter a phone number';
    }
    if (normalizedDigits.length < minLength) {
      return 'Phone number is too short (min $minLength digits)';
    }
    if (normalizedDigits.length > maxLength) {
      return 'Phone number is too long (max $maxLength digits)';
    }
    return null;
  }
}

/// Common countries list with phone number length constraints
/// Data sourced from ITU-T E.164 and common usage patterns
const List<CountryCode> commonCountries = [
  CountryCode(name: 'United States', isoCode: 'US', dialCode: '1', minLength: 10, maxLength: 10),
  CountryCode(name: 'United Kingdom', isoCode: 'GB', dialCode: '44', minLength: 10, maxLength: 10),
  CountryCode(name: 'Canada', isoCode: 'CA', dialCode: '1', minLength: 10, maxLength: 10),
  CountryCode(name: 'Australia', isoCode: 'AU', dialCode: '61', minLength: 9, maxLength: 9),
  CountryCode(name: 'Germany', isoCode: 'DE', dialCode: '49', minLength: 10, maxLength: 11),
  CountryCode(name: 'France', isoCode: 'FR', dialCode: '33', minLength: 9, maxLength: 9),
  CountryCode(name: 'Italy', isoCode: 'IT', dialCode: '39', minLength: 9, maxLength: 11),
  CountryCode(name: 'Spain', isoCode: 'ES', dialCode: '34', minLength: 9, maxLength: 9),
  CountryCode(name: 'Netherlands', isoCode: 'NL', dialCode: '31', minLength: 9, maxLength: 9),
  CountryCode(name: 'Belgium', isoCode: 'BE', dialCode: '32', minLength: 8, maxLength: 9),
  CountryCode(name: 'Switzerland', isoCode: 'CH', dialCode: '41', minLength: 9, maxLength: 9),
  CountryCode(name: 'Austria', isoCode: 'AT', dialCode: '43', minLength: 10, maxLength: 13),
  CountryCode(name: 'Sweden', isoCode: 'SE', dialCode: '46', minLength: 9, maxLength: 9),
  CountryCode(name: 'Norway', isoCode: 'NO', dialCode: '47', minLength: 8, maxLength: 8),
  CountryCode(name: 'Denmark', isoCode: 'DK', dialCode: '45', minLength: 8, maxLength: 8),
  CountryCode(name: 'Finland', isoCode: 'FI', dialCode: '358', minLength: 9, maxLength: 11),
  CountryCode(name: 'Poland', isoCode: 'PL', dialCode: '48', minLength: 9, maxLength: 9),
  CountryCode(name: 'Czech Republic', isoCode: 'CZ', dialCode: '420', minLength: 9, maxLength: 9),
  CountryCode(name: 'Ireland', isoCode: 'IE', dialCode: '353', minLength: 9, maxLength: 9),
  CountryCode(name: 'Portugal', isoCode: 'PT', dialCode: '351', minLength: 9, maxLength: 9),
  CountryCode(name: 'Greece', isoCode: 'GR', dialCode: '30', minLength: 10, maxLength: 10),
  CountryCode(name: 'Japan', isoCode: 'JP', dialCode: '81', minLength: 10, maxLength: 10),
  CountryCode(name: 'South Korea', isoCode: 'KR', dialCode: '82', minLength: 9, maxLength: 10),
  CountryCode(name: 'China', isoCode: 'CN', dialCode: '86', minLength: 11, maxLength: 11),
  CountryCode(name: 'Hong Kong', isoCode: 'HK', dialCode: '852', minLength: 8, maxLength: 8),
  CountryCode(name: 'Taiwan', isoCode: 'TW', dialCode: '886', minLength: 9, maxLength: 9),
  CountryCode(name: 'Singapore', isoCode: 'SG', dialCode: '65', minLength: 8, maxLength: 8),
  CountryCode(name: 'India', isoCode: 'IN', dialCode: '91', minLength: 10, maxLength: 10),
  CountryCode(name: 'Brazil', isoCode: 'BR', dialCode: '55', minLength: 10, maxLength: 11),
  CountryCode(name: 'Mexico', isoCode: 'MX', dialCode: '52', minLength: 10, maxLength: 10),
  CountryCode(name: 'Argentina', isoCode: 'AR', dialCode: '54', minLength: 10, maxLength: 10),
  CountryCode(name: 'Colombia', isoCode: 'CO', dialCode: '57', minLength: 10, maxLength: 10),
  CountryCode(name: 'Chile', isoCode: 'CL', dialCode: '56', minLength: 9, maxLength: 9),
  CountryCode(name: 'Peru', isoCode: 'PE', dialCode: '51', minLength: 9, maxLength: 9),
  CountryCode(name: 'New Zealand', isoCode: 'NZ', dialCode: '64', minLength: 8, maxLength: 10),
  CountryCode(name: 'South Africa', isoCode: 'ZA', dialCode: '27', minLength: 9, maxLength: 9),
  CountryCode(name: 'United Arab Emirates', isoCode: 'AE', dialCode: '971', minLength: 9, maxLength: 9),
  CountryCode(name: 'Saudi Arabia', isoCode: 'SA', dialCode: '966', minLength: 9, maxLength: 9),
  CountryCode(name: 'Israel', isoCode: 'IL', dialCode: '972', minLength: 9, maxLength: 9),
  CountryCode(name: 'Turkey', isoCode: 'TR', dialCode: '90', minLength: 10, maxLength: 10),
  CountryCode(name: 'Russia', isoCode: 'RU', dialCode: '7', minLength: 10, maxLength: 10),
  CountryCode(name: 'Ukraine', isoCode: 'UA', dialCode: '380', minLength: 9, maxLength: 9),
  CountryCode(name: 'Thailand', isoCode: 'TH', dialCode: '66', minLength: 9, maxLength: 9),
  CountryCode(name: 'Malaysia', isoCode: 'MY', dialCode: '60', minLength: 9, maxLength: 10),
  CountryCode(name: 'Indonesia', isoCode: 'ID', dialCode: '62', minLength: 9, maxLength: 12),
  CountryCode(name: 'Philippines', isoCode: 'PH', dialCode: '63', minLength: 10, maxLength: 10),
  CountryCode(name: 'Vietnam', isoCode: 'VN', dialCode: '84', minLength: 9, maxLength: 10),
];

/// Default country (US)
const CountryCode defaultCountry = CountryCode(
  name: 'United States',
  isoCode: 'US',
  dialCode: '1',
  minLength: 10,
  maxLength: 10,
);

/// Unified phone input with integrated country code dropdown
class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final VoidCallback? onSubmitted;
  final CountryCode selectedCountry;
  final ValueChanged<CountryCode> onCountryChanged;
  final bool enabled;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.validator,
    this.onSubmitted,
    required this.selectedCountry,
    required this.onCountryChanged,
    this.enabled = true,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;
  final TextEditingController _searchController = TextEditingController();
  List<CountryCode> _filteredCountries = commonCountries;

  @override
  void dispose() {
    // Remove overlay without setState (widget is being disposed)
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _removeOverlay();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
      _filteredCountries = commonCountries;
      _searchController.clear();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isDropdownOpen = false;
      });
    }
  }

  void _selectCountry(CountryCode country) {
    widget.onCountryChanged(country);
    _removeOverlay();
    widget.focusNode?.requestFocus();
  }

  void _filterCountries(String query) {
    if (!mounted) return;
    if (query.isEmpty) {
      setState(() => _filteredCountries = commonCountries);
      _overlayEntry?.markNeedsBuild();
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredCountries = commonCountries.where((country) {
        return country.name.toLowerCase().contains(lowercaseQuery) ||
            country.dialCode.contains(query) ||
            country.isoCode.toLowerCase().contains(lowercaseQuery);
      }).toList();
    });
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Backdrop to close dropdown when tapping outside
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeOverlay,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
            // Dropdown
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                offset: Offset(0, size.height + 4),
                showWhenUnlinked: false,
                child: _CountryDropdown(
                  filteredCountries: _filteredCountries,
                  searchController: _searchController,
                  onFilter: _filterCountries,
                  onSelect: _selectCountry,
                  selectedCountry: widget.selectedCountry,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        validator: widget.validator,
        enabled: widget.enabled,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        autocorrect: false,
        onFieldSubmitted: (_) => widget.onSubmitted?.call(),
        style: AppTypography.bodyLarge(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Phone number',
          hintStyle: AppTypography.bodyLarge(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          // Country code prefix button with proper clip
          prefixIcon: ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(AppSpacing.radiusMd),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.enabled ? _toggleDropdown : null,
                splashColor: AppColors.themeRed.withValues(alpha: 0.1),
                highlightColor: AppColors.themeRed.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleFlag(
                        widget.selectedCountry.isoCode,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        widget.selectedCountry.fullDialCode,
                        style: AppTypography.bodyMedium(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      AnimatedRotation(
                        turns: _isDropdownOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 48),
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: _isDropdownOpen ? AppColors.themeRed : AppColors.themeRed,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: AppColors.themeRed.withValues(alpha: 0.5),
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(
              color: AppColors.themeRed,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}

/// Country dropdown widget with glassmorphic design
class _CountryDropdown extends StatelessWidget {
  final List<CountryCode> filteredCountries;
  final TextEditingController searchController;
  final ValueChanged<String> onFilter;
  final ValueChanged<CountryCode> onSelect;
  final CountryCode selectedCountry;

  const _CountryDropdown({
    required this.filteredCountries,
    required this.searchController,
    required this.onFilter,
    required this.onSelect,
    required this.selectedCountry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 320),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            color: isDark
                ? Colors.black.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.85),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.1),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: TextField(
                  controller: searchController,
                  onChanged: onFilter,
                  autofocus: true,
                  style: AppTypography.bodyMedium(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search country...',
                    hintStyle: AppTypography.bodyMedium(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                  ),
                ),
              ),
              
              // Divider
              Container(
                height: 0.5,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              
              // Country list
              Flexible(
                child: filteredCountries.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'No countries found',
                          style: AppTypography.bodyMedium(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                        itemCount: filteredCountries.length,
                        separatorBuilder: (context, index) => Container(
                          height: 0.5,
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                        itemBuilder: (context, index) {
                          final country = filteredCountries[index];
                          final isSelected = country.isoCode == selectedCountry.isoCode;
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => onSelect(country),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                splashColor: AppColors.themeRed.withValues(alpha: 0.1),
                                highlightColor: AppColors.themeRed.withValues(alpha: 0.05),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: isSelected
                                      ? BoxDecoration(
                                          color: AppColors.themeRed.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                        )
                                      : null,
                                  child: Row(
                                    children: [
                                      CircleFlag(
                                        country.isoCode,
                                        size: 28,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Text(
                                          country.name,
                                          style: AppTypography.bodyMedium(
                                            color: isSelected 
                                                ? AppColors.themeRed
                                                : Theme.of(context).colorScheme.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        country.fullDialCode,
                                        style: AppTypography.labelMedium(
                                          color: isSelected
                                              ? AppColors.themeRed.withValues(alpha: 0.8)
                                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Keep backward compatibility - old components for reference
/// Country code selector button (deprecated - use PhoneInputField instead)
@Deprecated('Use PhoneInputField for unified input')
class CountryCodeButton extends StatelessWidget {
  final CountryCode selectedCountry;
  final VoidCallback onTap;
  final bool isDark;

  const CountryCodeButton({
    super.key,
    required this.selectedCountry,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleFlag(
                selectedCountry.isoCode,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                selectedCountry.fullDialCode,
                style: AppTypography.bodyMedium(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Country picker bottom sheet (deprecated - use PhoneInputField instead)
@Deprecated('Use PhoneInputField for integrated dropdown')
Future<CountryCode?> showCountryPicker(BuildContext context) {
  return showModalBottomSheet<CountryCode>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _CountryPickerSheet(),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<CountryCode> _filteredCountries = commonCountries;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    if (query.isEmpty) {
      setState(() => _filteredCountries = commonCountries);
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredCountries = commonCountries.where((country) {
        return country.name.toLowerCase().contains(lowercaseQuery) ||
            country.dialCode.contains(query) ||
            country.isoCode.toLowerCase().contains(lowercaseQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Select Country',
              style: AppTypography.h5(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCountries,
              style: AppTypography.bodyMedium(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search country or dial code',
                hintStyle: AppTypography.bodyMedium(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Country list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: bottomPadding + AppSpacing.lg),
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                return _CountryListTile(
                  country: country,
                  onTap: () => Navigator.pop(context, country),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryListTile extends StatelessWidget {
  final CountryCode country;
  final VoidCallback onTap;

  const _CountryListTile({
    required this.country,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleFlag(
        country.isoCode,
        size: 32,
      ),
      title: Text(
        country.name,
        style: AppTypography.bodyMedium(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: Text(
        country.fullDialCode,
        style: AppTypography.bodyMedium(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
