import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/l10n/generated/app_localizations.dart';

/// Get Help screen with FAQ dropdown items and Contact Us button
class GetHelpScreen extends ConsumerStatefulWidget {
  const GetHelpScreen({super.key});

  @override
  ConsumerState<GetHelpScreen> createState() => _GetHelpScreenState();
}

class _GetHelpScreenState extends ConsumerState<GetHelpScreen> {
  // Track which FAQ items are expanded
  final Set<int> _expandedItems = {};

  /// Get localized FAQ items
  List<Map<String, String>> _getFaqItems(AppLocalizations l10n) {
    return [
      {
        'question': l10n.faqCreateAccountQuestion,
        'answer': l10n.faqCreateAccountAnswer,
      },
      {
        'question': l10n.faqResetPasswordQuestion,
        'answer': l10n.faqResetPasswordAnswer,
      },
      {
        'question': l10n.faqUpdateProfileQuestion,
        'answer': l10n.faqUpdateProfileAnswer,
      },
      {
        'question': l10n.faqPaymentMethodsQuestion,
        'answer': l10n.faqPaymentMethodsAnswer,
      },
      {
        'question': l10n.faqTrackOrdersQuestion,
        'answer': l10n.faqTrackOrdersAnswer,
      },
      {
        'question': l10n.faqContactSupportQuestion,
        'answer': l10n.faqContactSupportAnswer,
      },
      {
        'question': l10n.faqDataSecurityQuestion,
        'answer': l10n.faqDataSecurityAnswer,
      },
      {
        'question': l10n.faqChangeLanguageQuestion,
        'answer': l10n.faqChangeLanguageAnswer,
      },
      {
        'question': l10n.faqOfflineUseQuestion,
        'answer': l10n.faqOfflineUseAnswer,
      },
      {
        'question': l10n.faqDeleteAccountQuestion,
        'answer': l10n.faqDeleteAccountAnswer,
      },
    ];
  }

  void _toggleExpanded(int index) {
    setState(() {
      if (_expandedItems.contains(index)) {
        _expandedItems.remove(index);
      } else {
        _expandedItems.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context)!;
    final faqItems = _getFaqItems(l10n);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF1F1F1),
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            pinned: true,
            backgroundColor:
                isDark ? const Color(0xFF121212) : const Color(0xFFF1F1F1),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              l10n.getHelpTitle,
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),

          // FAQ Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.getHelpFaqTitle,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.neutralWhite
                          : AppColors.neutralBlack,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.getHelpFaqSubtitle,
                    style: AppTypography.bodySmall().copyWith(
                      color: isDark
                          ? AppColors.neutralGray400
                          : AppColors.neutralGray600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FAQ Items
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final faq = faqItems[index];
                  final isExpanded = _expandedItems.contains(index);
                  return _buildFaqItem(
                    isDark: isDark,
                    question: faq['question']!,
                    answer: faq['answer']!,
                    isExpanded: isExpanded,
                    onTap: () => _toggleExpanded(index),
                  );
                },
                childCount: faqItems.length,
              ),
            ),
          ),

          // Contact Us Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.xxxl,
                bottom: bottomPadding + AppSpacing.xxxl,
              ),
              child: Column(
                children: [
                  // Divider
                  Divider(
                    color: isDark
                        ? AppColors.neutralGray700
                        : AppColors.neutralGray300,
                    thickness: 1,
                  ),
                  SizedBox(height: AppSpacing.xxl),

                  // Still need help text
                  Text(
                    l10n.getHelpStillNeedHelp,
                    style: AppTypography.titleSmall.copyWith(
                      color: isDark
                          ? AppColors.neutralWhite
                          : AppColors.neutralBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.getHelpSupportTeamMessage,
                    style: AppTypography.bodySmall().copyWith(
                      color: isDark
                          ? AppColors.neutralGray400
                          : AppColors.neutralGray600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),

                  // Contact Us button
                  _buildContactUsButton(isDark, l10n.getHelpContactUs),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// FAQ item with expandable answer
  Widget _buildFaqItem({
    required bool isDark,
    required String question,
    required String answer,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          // Question row (always visible)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: AppTypography.bodyMedium().copyWith(
                        color: isDark
                            ? AppColors.neutralWhite
                            : AppColors.neutralBlack,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: isDark
                          ? AppColors.neutralGray400
                          : AppColors.neutralGray600,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Answer (expandable)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
              ),
              child: Text(
                answer,
                style: AppTypography.bodySmall().copyWith(
                  color: isDark
                      ? AppColors.neutralGray400
                      : AppColors.neutralGray600,
                  height: 1.5,
                ),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  /// Contact Us button with fully rounded (stadium) shape
  Widget _buildContactUsButton(bool isDark, String buttonText) {
    return GestureDetector(
      onTap: () {
        // Navigate to support chat or contact form
        // TODO: Implement contact support navigation
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100), // Fully rounded (stadium shape)
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: AppColors.themeRed.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(100), // Fully rounded (stadium shape)
              boxShadow: [
                BoxShadow(
                  color: AppColors.themeRed.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.support_agent_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                SizedBox(width: AppSpacing.md),
                Text(
                  buttonText,
                  style: AppTypography.bodyMedium().copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
