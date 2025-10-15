enum MiniAppType {
  retailStore,
  unmannedStore,
  exhibitionSales,
  groupBuying,
}

extension MiniAppTypeExtension on MiniAppType {
  String get displayName {
    switch (this) {
      case MiniAppType.retailStore:
        return '零售门店';
      case MiniAppType.unmannedStore:
        return '无人商店';
      case MiniAppType.exhibitionSales:
        return '展销展消';
      case MiniAppType.groupBuying:
        return '团购团批';
    }
  }

  String get apiValue {
    switch (this) {
      case MiniAppType.retailStore:
        return 'RetailStore';
      case MiniAppType.unmannedStore:
        return 'UnmannedStore';
      case MiniAppType.exhibitionSales:
        return 'ExhibitionSales';
      case MiniAppType.groupBuying:
        return 'GroupBuying';
    }
  }

  static MiniAppType fromApiValue(String apiValue) {
    switch (apiValue) {
      case 'RetailStore':
        return MiniAppType.retailStore;
      case 'UnmannedStore':
        return MiniAppType.unmannedStore;
      case 'ExhibitionSales':
        return MiniAppType.exhibitionSales;
      case 'GroupBuying':
        return MiniAppType.groupBuying;
      default:
        throw ArgumentError('Unknown MiniAppType: $apiValue');
    }
  }
}
