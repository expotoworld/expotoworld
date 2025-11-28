/// MiniAppType represents the four ETW sub-applications.
/// Legacy names are preserved for backward compatibility, but ETW names are primary.
enum MiniAppType {
  // Legacy names (mapped to ETW types)
  retailStore,      // ETWtoB - B2B Exposition
  unmannedStore,    // ETWtoU - Automated Unstaffed Stores
  exhibitionSales,  // ETWtoC - B2C Exposition
  groupBuying,      // ETWtoG - Group Buying for Services
}

extension MiniAppTypeExtension on MiniAppType {
  /// Display name using ETW branding
  String get displayName {
    switch (this) {
      case MiniAppType.retailStore:
        return 'EXPO to WORLD to B';
      case MiniAppType.unmannedStore:
        return 'EXPO to WORLD to U';
      case MiniAppType.exhibitionSales:
        return 'EXPO to WORLD to C';
      case MiniAppType.groupBuying:
        return 'EXPO to WORLD to GATHER';
    }
  }

  /// Short display name for compact UI
  String get shortDisplayName {
    switch (this) {
      case MiniAppType.retailStore:
        return 'ETW to B';
      case MiniAppType.unmannedStore:
        return 'ETW to U';
      case MiniAppType.exhibitionSales:
        return 'ETW to C';
      case MiniAppType.groupBuying:
        return 'ETW to G';
    }
  }

  /// API value for backend communication (ETW values only)
  String get apiValue {
    switch (this) {
      case MiniAppType.retailStore:
        return 'ETWtoB';
      case MiniAppType.unmannedStore:
        return 'ETWtoU';
      case MiniAppType.exhibitionSales:
        return 'ETWtoC';
      case MiniAppType.groupBuying:
        return 'ETWtoG';
    }
  }

  /// ETW API value (same as apiValue, kept for explicit usage)
  String get etwApiValue => apiValue;

  /// Parse from API value (ETW values only)
  static MiniAppType fromApiValue(String apiValue) {
    switch (apiValue) {
      case 'ETWtoB':
        return MiniAppType.retailStore;
      case 'ETWtoU':
        return MiniAppType.unmannedStore;
      case 'ETWtoC':
        return MiniAppType.exhibitionSales;
      case 'ETWtoG':
        return MiniAppType.groupBuying;
      default:
        throw ArgumentError('Unknown MiniAppType: $apiValue');
    }
  }

  /// Try to parse from API value, returning null on failure
  static MiniAppType? tryFromApiValue(String? apiValue) {
    if (apiValue == null || apiValue.isEmpty) return null;
    try {
      return fromApiValue(apiValue);
    } catch (_) {
      return null;
    }
  }
}
