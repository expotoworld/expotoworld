/// ETW Store Types - physical store formats
enum StoreType {
  etwMega,    // ETWMega - Large format stores (maps to ETWtoB)
  etwMarket,  // ETWMarket - Market format stores (maps to ETWtoC)
  etwToGo,    // ETWtoGO - Convenience format (maps to ETWtoU)
  etwXpress,  // ETWXpress - Express format (maps to ETWtoU)
}

extension StoreTypeExtension on StoreType {
  String get displayName {
    switch (this) {
      case StoreType.etwMega:
        return 'ETW Mega';
      case StoreType.etwMarket:
        return 'ETW Market';
      case StoreType.etwToGo:
        return 'ETW to GO';
      case StoreType.etwXpress:
        return 'ETW Xpress';
    }
  }

  String get apiValue {
    switch (this) {
      case StoreType.etwMega:
        return 'ETWMega';
      case StoreType.etwMarket:
        return 'ETWMarket';
      case StoreType.etwToGo:
        return 'ETWtoGO';
      case StoreType.etwXpress:
        return 'ETWXpress';
    }
  }

  static StoreType fromApiValue(String apiValue) {
    switch (apiValue) {
      case 'ETWMega':
        return StoreType.etwMega;
      case 'ETWMarket':
        return StoreType.etwMarket;
      case 'ETWtoGO':
        return StoreType.etwToGo;
      case 'ETWXpress':
        return StoreType.etwXpress;
      default:
        throw ArgumentError('Unknown StoreType: $apiValue');
    }
  }
}

enum StoreTypeAssociation {
  retail,
  unmanned,
  all,
}
