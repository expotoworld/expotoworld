enum StoreType {
  retailStore,        // 零售商店
  unmannedStore,      // 无人门店
  unmannedWarehouse,  // 无人仓店
  exhibitionStore,    // 展销商店
  exhibitionMall,     // 展销商城
  groupBuying,        // 团购团批
}

extension StoreTypeExtension on StoreType {
  String get displayName {
    switch (this) {
      case StoreType.retailStore:
        return '零售商店';
      case StoreType.unmannedStore:
        return '无人门店';
      case StoreType.unmannedWarehouse:
        return '无人仓店';
      case StoreType.exhibitionStore:
        return '展销商店';
      case StoreType.exhibitionMall:
        return '展销商城';
      case StoreType.groupBuying:
        return '团购团批';
    }
  }

  String get apiValue {
    switch (this) {
      case StoreType.retailStore:
        return 'RetailStore';
      case StoreType.unmannedStore:
        return 'UnmannedStore';
      case StoreType.unmannedWarehouse:
        return 'UnmannedWarehouse';
      case StoreType.exhibitionStore:
        return 'ExhibitionStore';
      case StoreType.exhibitionMall:
        return 'ExhibitionMall';
      case StoreType.groupBuying:
        return 'GroupBuying';
    }
  }

  String get chineseValue {
    switch (this) {
      case StoreType.retailStore:
        return '零售商店';
      case StoreType.unmannedStore:
        return '无人门店';
      case StoreType.unmannedWarehouse:
        return '无人仓店';
      case StoreType.exhibitionStore:
        return '展销商店';
      case StoreType.exhibitionMall:
        return '展销商城';
      case StoreType.groupBuying:
        return '团购团批';
    }
  }

  static StoreType fromApiValue(String apiValue) {
    switch (apiValue) {
      case 'RetailStore':
        return StoreType.retailStore;
      case 'UnmannedStore':
        return StoreType.unmannedStore;
      case 'UnmannedWarehouse':
        return StoreType.unmannedWarehouse;
      case 'ExhibitionStore':
        return StoreType.exhibitionStore;
      case 'ExhibitionMall':
        return StoreType.exhibitionMall;
      case 'GroupBuying':
        return StoreType.groupBuying;
      default:
        throw ArgumentError('Unknown StoreType: $apiValue');
    }
  }

  static StoreType fromChineseValue(String chineseValue) {
    switch (chineseValue) {
      case '零售商店':
        return StoreType.retailStore;
      case '无人门店':
      case '无人商店': // Keep backward compatibility
        return StoreType.unmannedStore;
      case '无人仓店':
        return StoreType.unmannedWarehouse;
      case '展销商店':
        return StoreType.exhibitionStore;
      case '展销商城':
        return StoreType.exhibitionMall;
      case '团购团批':
        return StoreType.groupBuying;
      default:
        throw ArgumentError('Unknown StoreType: $chineseValue');
    }
  }
}

enum StoreTypeAssociation {
  retail,
  unmanned,
  all,
}
