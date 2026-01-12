/// Contact Input Step
/// 
/// First step in auth flow - enter email or phone number.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_flow_provider.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/buttons.dart';
import '../../../../shared/widgets/country_code_picker.dart';

/// Contact input step widget
class ContactInputStep extends ConsumerStatefulWidget {
  const ContactInputStep({super.key});

  @override
  ConsumerState<ContactInputStep> createState() => _ContactInputStepState();
}

class _ContactInputStepState extends ConsumerState<ContactInputStep> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _focusNode = FocusNode();
  CountryCode _selectedCountry = defaultCountry;

  @override
  void initState() {
    super.initState();
    // Auto-focus the input field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _contactController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _validateContact(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your ${ref.read(authFlowProvider).contactType.label.toLowerCase()}';
    }

    final type = ref.read(authFlowProvider).contactType;
    
    if (type == ContactType.email) {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Invalid email address';
      }
    } else {
      // Phone validation using country-specific rules
      final phone = value.replaceAll(RegExp(r'[\s\-\(\)\.]+'), '');
      
      if (phone.isEmpty) {
        return 'Please enter a phone number';
      }
      
      if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
        return 'Phone number can only contain digits';
      }
      
      // Use country-specific validation
      return _selectedCountry.validateLength(phone);
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final type = ref.read(authFlowProvider).contactType;
    String contact = _contactController.text.trim();
    
    // For phone numbers, prepend the country code in E.164 format
    if (type == ContactType.phone) {
      // Remove any existing + and spaces
      contact = contact.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (!contact.startsWith('+')) {
        contact = '${_selectedCountry.fullDialCode}$contact';
      }
    }
    
    await ref.read(authFlowProvider.notifier).sendCode(contact);
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(authFlowProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,  // Top padding to clear close button (~48px)
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome text (no icon)
            Text(
              'Welcome to',
              style: AppTypography.bodyLarge(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'EXPO to WORLD',
              style: AppTypography.h3(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              'Enter your details to access your account.\nNew user? We\'ll set you up automatically.',
              style: AppTypography.bodyMedium(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            
            // Contact type toggle
            _ContactTypeToggle(
              selectedType: flowState.contactType,
              onChanged: (type) {
                ref.read(authFlowProvider.notifier).setContactType(type);
                _contactController.clear();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Contact input field
            if (flowState.contactType == ContactType.phone) ...[
              // Phone input with integrated country code dropdown
              PhoneInputField(
                controller: _contactController,
                focusNode: _focusNode,
                validator: _validateContact,
                onSubmitted: _submit,
                selectedCountry: _selectedCountry,
                onCountryChanged: (country) {
                  setState(() => _selectedCountry = country);
                },
                enabled: !flowState.isLoading,
              ),
            ] else ...[
              // Email input
              TextFormField(
                controller: _contactController,
                focusNode: _focusNode,
                validator: _validateContact,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: true,
                onFieldSubmitted: (_) => _submit(),
                style: AppTypography.bodyLarge(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: flowState.contactType.placeholder,
                  hintStyle: AppTypography.bodyLarge(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
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
                  borderSide: const BorderSide(
                    color: AppColors.themeRed,
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
            ],
            
            // Error message
            if (flowState.error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                flowState.error!,
                style: AppTypography.bodySmall(color: AppColors.themeRed),
                textAlign: TextAlign.center,
              ),
            ],
            
            const SizedBox(height: AppSpacing.xl),
            
            // Continue button
            PrimaryButton(
              label: 'Continue',
              isLoading: flowState.isLoading,
              isFullWidth: true,
              onPressed: flowState.isLoading ? null : _submit,
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Terms text
            Text(
              'By continuing, you agree to our Terms of Service and Privacy Policy.',
              style: AppTypography.caption(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Contact type toggle (Email/Phone)
class _ContactTypeToggle extends StatelessWidget {
  final ContactType selectedType;
  final ValueChanged<ContactType> onChanged;

  const _ContactTypeToggle({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: ContactType.values.map((type) {
          final isSelected = type == selectedType;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type == ContactType.email
                          ? Icons.email_outlined
                          : Icons.phone_outlined,
                      size: 18,
                      color: isSelected
                          ? AppColors.themeRed
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      type.label,
                      style: AppTypography.labelMedium(
                        color: isSelected
                            ? AppColors.themeRed
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
}
