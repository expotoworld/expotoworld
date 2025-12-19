import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/store_model.dart';
import '../../domain/models/product_model.dart';
import '../../core/providers/mini_app_providers.dart';
import '../../core/widgets/category_pills.dart';
import '../../core/widgets/subcategory_grid.dart';

/// Home screen for toX mini-app (services only, no cart/map)
/// Displays: Header → Category pills → Subcategory grid → Services
class ToXHomeScreen extends ConsumerStatefulWidget {
  const ToXHomeScreen({super.key});

  @override
  ConsumerState<ToXHomeScreen> createState() => _ToXHomeScreenState();
}

class _ToXHomeScreenState extends ConsumerState<ToXHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleClose() {
    context.go('/home');
  }

  void _handleCategorySelected(String? categoryId) {
    ref.read(selectedCategoryIdProvider(MiniAppType.toX).notifier).state = categoryId;
  }

  void _handleSubcategoryTap(MiniAppSubcategory subcategory) {
    // Navigate to subcategory services screen
    context.push('/mini-app/toX/services/${subcategory.id}');
  }

  // ignore: unused_element
  void _handleRequestQuote(MiniAppService service) {
    // Show quote request popup
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _QuoteRequestPopup(
        service: service,
        onSubmit: (details) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Quote request sent for ${service.name}!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final categories = ref.watch(miniAppCategoriesProvider(MiniAppType.toX));
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider(MiniAppType.toX));
    final subcategories = ref.watch(miniAppSubcategoriesProvider((
      miniAppType: MiniAppType.toX,
      categoryId: selectedCategoryId,
    )));

    return Scaffold(
      body: Column(
        children: [
          // Header (no store dropdown for toX)
          Container(
            padding: EdgeInsets.only(top: statusBarHeight),
            decoration: const BoxDecoration(
              color: AppColors.themeRed,
            ),
            child: _ToXHeader(onClose: _handleClose),
          ),
          
          // Scrollable content
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Category pills
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.lg,
                    ),
                    child: CategoryPills(
                      categories: categories,
                      selectedCategoryId: selectedCategoryId,
                      onCategorySelected: _handleCategorySelected,
                    ),
                  ),
                ),
                
                // Section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: _SectionHeader(
                      title: selectedCategoryId == null
                          ? 'Browse Services'
                          : 'Service Categories',
                      subtitle: selectedCategoryId == null
                          ? 'Find the best deals on services'
                          : _getCategoryName(categories, selectedCategoryId),
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),
                
                // Subcategory grid
                SliverSubcategoryGrid(
                  subcategories: subcategories,
                  onSubcategoryTap: _handleSubcategoryTap,
                ),
                
                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(List<MiniAppCategory> categories, String categoryId) {
    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => MiniAppCategory(id: '', name: '', imageUrl: null),
    );
    return category.name;
  }
}

/// toX specific header (no store dropdown, just title and close button)
class _ToXHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _ToXHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.appBarHeight + 52 + AppSpacing.md,
      child: Column(
        children: [
          // Main header row
          Container(
            height: AppSpacing.appBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Stack(
              children: [
                // Center - toX branding
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'to X',
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Group Buying Services',
                        style: AppTypography.caption(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Right side - Close button
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            child: _ToXSearchBar(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// toX search bar
class _ToXSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 18,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Search services...',
            style: AppTypography.bodySmall(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.foreground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppTypography.caption(
              color: AppColors.foregroundMuted(context),
            ),
          ),
        ],
      ],
    );
  }
}

/// Quote request popup for services
class _QuoteRequestPopup extends StatefulWidget {
  final MiniAppService service;
  final ValueChanged<Map<String, String>> onSubmit;

  const _QuoteRequestPopup({
    required this.service,
    required this.onSubmit,
  });

  @override
  State<_QuoteRequestPopup> createState() => _QuoteRequestPopupState();
}

class _QuoteRequestPopupState extends State<_QuoteRequestPopup> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      widget.onSubmit({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'notes': _notesController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request Quote',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.foreground(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.service.name,
                        style: AppTypography.bodySmall(
                          color: AppColors.foregroundMuted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.foregroundMuted(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Service info card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _ServiceInfoCard(service: widget.service),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Information',
                    style: AppTypography.labelMediumStyle.copyWith(
                      color: AppColors.foreground(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _QuoteTextField(
                    controller: _nameController,
                    label: 'Full Name *',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _QuoteTextField(
                    controller: _emailController,
                    label: 'Email *',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _QuoteTextField(
                    controller: _phoneController,
                    label: 'Phone *',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _QuoteTextField(
                    controller: _notesController,
                    label: 'Additional notes (optional)',
                    icon: Icons.note_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
          
          // Submit button
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.md,
              bottom: bottomPadding + AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: GestureDetector(
              onTap: _isSubmitting ? null : _handleSubmit,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.themeRed, Color(0xFFFF5252)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.themeRed.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Submit Quote Request',
                              style: AppTypography.labelMediumStyle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceInfoCard extends StatelessWidget {
  final MiniAppService service;

  const _ServiceInfoCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.themeRed.withValues(alpha: 0.1)
            : AppColors.themeRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.themeRed.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.themeRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              Icons.miscellaneous_services_rounded,
              color: AppColors.themeRed,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.themeRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    service.provider,
                    style: AppTypography.caption(
                      color: AppColors.themeRed,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.name,
                  style: AppTypography.labelMediumStyle.copyWith(
                    color: AppColors.foreground(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (service.priceRange != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    service.priceRange!,
                    style: AppTypography.caption(
                      color: AppColors.foregroundMuted(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const _QuoteTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: AppTypography.bodyMedium(
          color: AppColors.foreground(context),
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: AppTypography.bodyMedium(
            color: AppColors.foregroundMuted(context),
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: AppColors.foregroundMuted(context),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppSpacing.md),
        ),
      ),
    );
  }
}
