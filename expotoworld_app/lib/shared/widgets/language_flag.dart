import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:circle_flags/circle_flags.dart';
import '../../core/providers/locale_provider.dart';

/// A widget that displays a language flag.
///
/// Uses custom language flag SVGs if available (e.g., en-us),
/// otherwise falls back to CircleFlag for country flags.
class LanguageFlag extends StatelessWidget {
  const LanguageFlag({
    super.key,
    required this.language,
    this.size = 24,
  });

  final AppLanguage language;
  final double size;

  /// Map of languages that have custom combined flag SVGs.
  /// Add more entries here as you add more custom language flag files.
  static const Map<AppLanguage, String> _customFlagPaths = {
    AppLanguage.english: 'assets/flags/language/circle-flags--lang-en-us.svg',
    // Add more custom language flags here as needed:
    // AppLanguage.chinese: 'assets/flags/language/zh-cn.svg',
  };

  @override
  Widget build(BuildContext context) {
    final customPath = _customFlagPaths[language];

    if (customPath != null) {
      // Use custom language flag SVG
      return ClipOval(
        child: SvgPicture.asset(
          customPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    // Fall back to CircleFlag (country flag)
    return CircleFlag(
      language.countryCode,
      size: size,
    );
  }
}
