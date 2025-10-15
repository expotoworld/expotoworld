import '../../core/enums/store_type.dart';
import '../../core/enums/mini_app_type.dart';
import 'subcategory.dart';

class Category {
  final String id;
  final String name;
  final StoreTypeAssociation storeTypeAssociation;
  final List<MiniAppType> miniAppAssociation;
  final List<Subcategory> subcategories;

  Category({
    required this.id,
    required this.name,
    required this.storeTypeAssociation,
    required this.miniAppAssociation,
    this.subcategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Parse mini_app_association array
    List<MiniAppType> miniAppTypes = [];
    if (json['mini_app_association'] != null) {
      List<dynamic> miniAppList = json['mini_app_association'] is List
          ? json['mini_app_association']
          : [json['mini_app_association']];

      miniAppTypes = miniAppList
          .map((e) => MiniAppTypeExtension.fromApiValue(e.toString()))
          .toList();
    }

    // Parse subcategories if present
    List<Subcategory> subcategories = [];
    if (json['subcategories'] != null) {
      subcategories = (json['subcategories'] as List)
          .map((subcategoryJson) => Subcategory.fromJson(subcategoryJson))
          .toList();
    }

    return Category(
      id: json['id'].toString(), // Convert int to string for compatibility
      name: json['name'],
      storeTypeAssociation: StoreTypeAssociation.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == json['store_type_association'].toString().toLowerCase(),
      ),
      miniAppAssociation: miniAppTypes,
      subcategories: subcategories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'store_type_association': storeTypeAssociation.toString().split('.').last,
      'mini_app_association': miniAppAssociation.map((e) => e.apiValue).toList(),
      'subcategories': subcategories.map((e) => e.toJson()).toList(),
    };
  }
}


