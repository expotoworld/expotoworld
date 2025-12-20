import '../domain/enums/mini_app_type.dart';
import '../domain/models/store_model.dart';
import '../domain/models/product_model.dart';

/// Mock data repository for mini-apps
class MiniAppMockData {
  MiniAppMockData._();

  // ============================================
  // STORES - Mock data for each store type
  // ============================================

  static const List<MiniAppStore> megaStores = [
    MiniAppStore(
      id: 'mega-001',
      name: 'EXPO MEGA Lugano Centro',
      storeType: StoreType.mega,
      address: 'Via Nassa 15, 6900 Lugano, Switzerland',
      latitude: 46.0037,
      longitude: 8.9511,
      distanceMeters: 450,
    ),
    MiniAppStore(
      id: 'mega-002',
      name: 'EXPO MEGA Paradiso',
      storeType: StoreType.mega,
      address: 'Riva Paradiso 5, 6902 Paradiso, Switzerland',
      latitude: 45.9940,
      longitude: 8.9450,
      distanceMeters: 1200,
    ),
    MiniAppStore(
      id: 'mega-003',
      name: 'EXPO MEGA Convention Center',
      storeType: StoreType.mega,
      address: 'Via Cantonale 12, 6900 Lugano, Switzerland',
      latitude: 46.0050,
      longitude: 8.9530,
      distanceMeters: 2300,
    ),
    MiniAppStore(
      id: 'mega-004',
      name: 'EXPO MEGA Bellinzona',
      storeType: StoreType.mega,
      address: 'Viale Stazione 8, 6500 Bellinzona, Switzerland',
      latitude: 46.1952,
      longitude: 9.0231,
      distanceMeters: 28500,
    ),
  ];

  static const List<MiniAppStore> marketStores = [
    MiniAppStore(
      id: 'market-001',
      name: 'EXPO MARKET Piazza Riforma',
      storeType: StoreType.market,
      address: 'Piazza Riforma 1, 6900 Lugano, Switzerland',
      latitude: 46.0055,
      longitude: 8.9510,
      distanceMeters: 320,
    ),
    MiniAppStore(
      id: 'market-002',
      name: 'EXPO MARKET Cassarate',
      storeType: StoreType.market,
      address: 'Via Cassarate 22, 6900 Lugano, Switzerland',
      latitude: 46.0100,
      longitude: 8.9600,
      distanceMeters: 890,
    ),
    MiniAppStore(
      id: 'market-003',
      name: 'EXPO MARKET Molino Nuovo',
      storeType: StoreType.market,
      address: 'Via San Gottardo 45, 6900 Lugano, Switzerland',
      latitude: 46.0085,
      longitude: 8.9420,
      distanceMeters: 1500,
    ),
    MiniAppStore(
      id: 'market-004',
      name: 'EXPO MARKET Mendrisio',
      storeType: StoreType.market,
      address: 'Via Borromini 12, 6850 Mendrisio, Switzerland',
      latitude: 45.8699,
      longitude: 8.9818,
      distanceMeters: 15800,
    ),
  ];

  static const List<MiniAppStore> toGoStores = [
    MiniAppStore(
      id: 'togo-001',
      name: 'EXPO to GO Stazione FFS',
      storeType: StoreType.toGo,
      address: 'Piazzale Stazione, 6900 Lugano, Switzerland',
      latitude: 46.0060,
      longitude: 8.9470,
      distanceMeters: 250,
    ),
    MiniAppStore(
      id: 'togo-002',
      name: 'EXPO to GO LAC',
      storeType: StoreType.toGo,
      address: 'Piazza Bernardino Luini, 6900 Lugano, Switzerland',
      latitude: 46.0040,
      longitude: 8.9490,
      distanceMeters: 600,
    ),
    MiniAppStore(
      id: 'togo-003',
      name: 'EXPO to GO USI Campus',
      storeType: StoreType.toGo,
      address: 'Via Giuseppe Buffi 13, 6900 Lugano, Switzerland',
      latitude: 46.0115,
      longitude: 8.9580,
      distanceMeters: 1100,
    ),
  ];

  static const List<MiniAppStore> xpressStores = [
    MiniAppStore(
      id: 'xpress-001',
      name: 'EXPO XPRESS Centro',
      storeType: StoreType.xpress,
      address: 'Via Pessina 10, 6900 Lugano, Switzerland',
      latitude: 46.0045,
      longitude: 8.9505,
      distanceMeters: 180,
    ),
    MiniAppStore(
      id: 'xpress-002',
      name: 'EXPO XPRESS Parco Ciani',
      storeType: StoreType.xpress,
      address: 'Riva Caccia 5, 6900 Lugano, Switzerland',
      latitude: 46.0020,
      longitude: 8.9550,
      distanceMeters: 550,
    ),
    MiniAppStore(
      id: 'xpress-003',
      name: 'EXPO XPRESS Cornaredo',
      storeType: StoreType.xpress,
      address: 'Via Trevano 55, 6900 Lugano, Switzerland',
      latitude: 46.0150,
      longitude: 8.9350,
      distanceMeters: 1800,
    ),
  ];

  /// Get stores by mini-app type
  static List<MiniAppStore> getStoresForMiniApp(MiniAppType miniAppType) {
    switch (miniAppType) {
      case MiniAppType.toB:
        return megaStores;
      case MiniAppType.toC:
        return marketStores;
      case MiniAppType.toU:
        return [...toGoStores, ...xpressStores]
          ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      case MiniAppType.toX:
        return []; // No physical stores
    }
  }

  /// Get stores by store type
  static List<MiniAppStore> getStoresByType(StoreType storeType) {
    switch (storeType) {
      case StoreType.mega:
        return megaStores;
      case StoreType.market:
        return marketStores;
      case StoreType.toGo:
        return toGoStores;
      case StoreType.xpress:
        return xpressStores;
    }
  }

  // ============================================
  // CATEGORIES (Brands)
  // ============================================

  static const List<MiniAppCategory> productCategories = [
    // Food & Beverage brands
    MiniAppCategory(id: 'cat-barilla', name: 'Barilla'),
    MiniAppCategory(id: 'cat-borbone', name: 'Borbone'),
    MiniAppCategory(id: 'cat-levissima', name: 'Levissima'),
    MiniAppCategory(id: 'cat-evian', name: 'Evian'),
    MiniAppCategory(id: 'cat-lavazza', name: 'Lavazza'),
    MiniAppCategory(id: 'cat-illy', name: 'Illy'),
    MiniAppCategory(id: 'cat-ferrero', name: 'Ferrero'),
    MiniAppCategory(id: 'cat-mulino', name: 'Mulino Bianco'),
    MiniAppCategory(id: 'cat-sanpellegrino', name: 'San Pellegrino'),
    MiniAppCategory(id: 'cat-de-cecco', name: 'De Cecco'),
  ];

  static const List<MiniAppCategory> serviceCategories = [
    // Insurance providers
    MiniAppCategory(id: 'cat-axa', name: 'AXA'),
    MiniAppCategory(id: 'cat-generali', name: 'Assicurazioni Generali'),
    MiniAppCategory(id: 'cat-allianz', name: 'Allianz'),
    // Telecom providers
    MiniAppCategory(id: 'cat-vodafone', name: 'Vodafone'),
    MiniAppCategory(id: 'cat-swisscom', name: 'Swisscom'),
    MiniAppCategory(id: 'cat-sunrise', name: 'Sunrise'),
    // Utility providers
    MiniAppCategory(id: 'cat-aie', name: 'AIL (Aziende Industriali Lugano)'),
    MiniAppCategory(id: 'cat-eni', name: 'Eni'),
  ];

  // ============================================
  // SUBCATEGORIES
  // ============================================

  static const List<MiniAppSubcategory> productSubcategories = [
    // Barilla subcategories
    MiniAppSubcategory(id: 'sub-pasta', name: 'Pasta', categoryId: 'cat-barilla'),
    MiniAppSubcategory(id: 'sub-spaghetti', name: 'Spaghetti', categoryId: 'cat-barilla'),
    MiniAppSubcategory(id: 'sub-sugo', name: 'Sugo', categoryId: 'cat-barilla'),
    MiniAppSubcategory(id: 'sub-pesto', name: 'Pesto', categoryId: 'cat-barilla'),
    MiniAppSubcategory(id: 'sub-lasagne', name: 'Lasagne', categoryId: 'cat-barilla'),
    MiniAppSubcategory(id: 'sub-rigatoni', name: 'Rigatoni', categoryId: 'cat-barilla'),

    // Borbone subcategories
    MiniAppSubcategory(id: 'sub-espresso', name: 'Espresso Capsules', categoryId: 'cat-borbone'),
    MiniAppSubcategory(id: 'sub-cialde', name: 'Cialde', categoryId: 'cat-borbone'),
    MiniAppSubcategory(id: 'sub-macinato', name: 'Caffè Macinato', categoryId: 'cat-borbone'),

    // Levissima subcategories
    MiniAppSubcategory(id: 'sub-naturale', name: 'Acqua Naturale', categoryId: 'cat-levissima'),
    MiniAppSubcategory(id: 'sub-frizzante', name: 'Acqua Frizzante', categoryId: 'cat-levissima'),
    MiniAppSubcategory(id: 'sub-aromatizzata', name: 'Acqua Aromatizzata', categoryId: 'cat-levissima'),

    // Evian subcategories
    MiniAppSubcategory(id: 'sub-evian-nat', name: 'Natural Mineral Water', categoryId: 'cat-evian'),
    MiniAppSubcategory(id: 'sub-evian-sparkling', name: 'Sparkling Water', categoryId: 'cat-evian'),

    // Lavazza subcategories
    MiniAppSubcategory(id: 'sub-lavazza-beans', name: 'Coffee Beans', categoryId: 'cat-lavazza'),
    MiniAppSubcategory(id: 'sub-lavazza-ground', name: 'Ground Coffee', categoryId: 'cat-lavazza'),
    MiniAppSubcategory(id: 'sub-lavazza-pods', name: 'Coffee Pods', categoryId: 'cat-lavazza'),

    // Illy subcategories
    MiniAppSubcategory(id: 'sub-illy-classico', name: 'Classico', categoryId: 'cat-illy'),
    MiniAppSubcategory(id: 'sub-illy-intenso', name: 'Intenso', categoryId: 'cat-illy'),
    MiniAppSubcategory(id: 'sub-illy-deca', name: 'Decaffeinato', categoryId: 'cat-illy'),

    // Ferrero subcategories
    MiniAppSubcategory(id: 'sub-nutella', name: 'Nutella', categoryId: 'cat-ferrero'),
    MiniAppSubcategory(id: 'sub-rocher', name: 'Ferrero Rocher', categoryId: 'cat-ferrero'),
    MiniAppSubcategory(id: 'sub-kinder', name: 'Kinder', categoryId: 'cat-ferrero'),

    // Mulino Bianco subcategories
    MiniAppSubcategory(id: 'sub-biscotti', name: 'Biscotti', categoryId: 'cat-mulino'),
    MiniAppSubcategory(id: 'sub-fette', name: 'Fette Biscottate', categoryId: 'cat-mulino'),
    MiniAppSubcategory(id: 'sub-merendine', name: 'Merendine', categoryId: 'cat-mulino'),

    // San Pellegrino subcategories
    MiniAppSubcategory(id: 'sub-sp-sparkling', name: 'Sparkling Water', categoryId: 'cat-sanpellegrino'),
    MiniAppSubcategory(id: 'sub-sp-aranciata', name: 'Aranciata', categoryId: 'cat-sanpellegrino'),
    MiniAppSubcategory(id: 'sub-sp-limonata', name: 'Limonata', categoryId: 'cat-sanpellegrino'),

    // De Cecco subcategories
    MiniAppSubcategory(id: 'sub-dc-pasta', name: 'Pasta', categoryId: 'cat-de-cecco'),
    MiniAppSubcategory(id: 'sub-dc-semola', name: 'Semola', categoryId: 'cat-de-cecco'),
    MiniAppSubcategory(id: 'sub-dc-olio', name: 'Olio Extra Vergine', categoryId: 'cat-de-cecco'),
  ];

  static const List<MiniAppSubcategory> serviceSubcategories = [
    // AXA subcategories
    MiniAppSubcategory(id: 'sub-axa-health', name: 'Health Insurance', categoryId: 'cat-axa'),
    MiniAppSubcategory(id: 'sub-axa-car', name: 'Car Insurance', categoryId: 'cat-axa'),
    MiniAppSubcategory(id: 'sub-axa-home', name: 'Home Insurance', categoryId: 'cat-axa'),
    MiniAppSubcategory(id: 'sub-axa-travel', name: 'Travel Insurance', categoryId: 'cat-axa'),
    MiniAppSubcategory(id: 'sub-axa-life', name: 'Life Insurance', categoryId: 'cat-axa'),

    // Generali subcategories
    MiniAppSubcategory(id: 'sub-gen-health', name: 'Health Insurance', categoryId: 'cat-generali'),
    MiniAppSubcategory(id: 'sub-gen-car', name: 'Car Insurance', categoryId: 'cat-generali'),
    MiniAppSubcategory(id: 'sub-gen-home', name: 'Home Insurance', categoryId: 'cat-generali'),
    MiniAppSubcategory(id: 'sub-gen-business', name: 'Business Insurance', categoryId: 'cat-generali'),

    // Allianz subcategories
    MiniAppSubcategory(id: 'sub-all-health', name: 'Health Insurance', categoryId: 'cat-allianz'),
    MiniAppSubcategory(id: 'sub-all-car', name: 'Car Insurance', categoryId: 'cat-allianz'),
    MiniAppSubcategory(id: 'sub-all-pet', name: 'Pet Insurance', categoryId: 'cat-allianz'),

    // Vodafone subcategories
    MiniAppSubcategory(id: 'sub-voda-mobile', name: 'Mobile Plans', categoryId: 'cat-vodafone'),
    MiniAppSubcategory(id: 'sub-voda-home', name: 'Home Internet', categoryId: 'cat-vodafone'),
    MiniAppSubcategory(id: 'sub-voda-tv', name: 'TV & Entertainment', categoryId: 'cat-vodafone'),

    // Swisscom subcategories
    MiniAppSubcategory(id: 'sub-swiss-mobile', name: 'Mobile Plans', categoryId: 'cat-swisscom'),
    MiniAppSubcategory(id: 'sub-swiss-home', name: 'Home Internet', categoryId: 'cat-swisscom'),
    MiniAppSubcategory(id: 'sub-swiss-bundle', name: 'Bundle Packages', categoryId: 'cat-swisscom'),

    // Sunrise subcategories
    MiniAppSubcategory(id: 'sub-sun-mobile', name: 'Mobile Plans', categoryId: 'cat-sunrise'),
    MiniAppSubcategory(id: 'sub-sun-home', name: 'Home Internet', categoryId: 'cat-sunrise'),
    MiniAppSubcategory(id: 'sub-sun-5g', name: '5G Plans', categoryId: 'cat-sunrise'),

    // AIL subcategories
    MiniAppSubcategory(id: 'sub-ail-electricity', name: 'Electricity', categoryId: 'cat-aie'),
    MiniAppSubcategory(id: 'sub-ail-gas', name: 'Gas', categoryId: 'cat-aie'),
    MiniAppSubcategory(id: 'sub-ail-water', name: 'Water', categoryId: 'cat-aie'),

    // Eni subcategories
    MiniAppSubcategory(id: 'sub-eni-gas', name: 'Natural Gas', categoryId: 'cat-eni'),
    MiniAppSubcategory(id: 'sub-eni-electricity', name: 'Electricity', categoryId: 'cat-eni'),
    MiniAppSubcategory(id: 'sub-eni-green', name: 'Green Energy', categoryId: 'cat-eni'),
  ];

  /// Get subcategories for a category
  static List<MiniAppSubcategory> getSubcategoriesForCategory(String categoryId, {bool isService = false}) {
    final subcategories = isService ? serviceSubcategories : productSubcategories;
    return subcategories.where((sub) => sub.categoryId == categoryId).toList();
  }

  // ============================================
  // PRODUCTS
  // ============================================

  static List<MiniAppProduct> getProductsForSubcategory(
    String subcategoryId,
    String storeId,
  ) {
    // Get store info to include in products
    final store = _getStoreById(storeId);
    // Generate mock products based on subcategory
    return _generateMockProducts(subcategoryId, storeId, store);
  }

  /// Get store by ID from all store lists
  static MiniAppStore? _getStoreById(String storeId) {
    final allStores = [...megaStores, ...marketStores, ...toGoStores, ...xpressStores];
    try {
      return allStores.firstWhere((s) => s.id == storeId);
    } catch (_) {
      return null;
    }
  }

  static List<MiniAppProduct> _generateMockProducts(
    String subcategoryId, 
    String storeId,
    MiniAppStore? store,
  ) {
    // Mock product generation based on subcategory
    final products = <MiniAppProduct>[];

    switch (subcategoryId) {
      case 'sub-pasta':
        products.addAll([
          MiniAppProduct(
            id: 'prod-001',
            name: 'Farfalle N.65 BARILLA ALWAYS IS THE BEST',
            description: 'Pasta di semola di grano duro - Bronze die cut',
            originalPrice: 3.50,
            currentPrice: 2.89,
            stockLeft: 150,
            minimumOrderQuantity: 1,
            unit: 'g',
            quantity: 500,
            shelfCode: '01-02-03',
            categoryId: 'cat-barilla',
            subcategoryId: subcategoryId,
            storeId: storeId,
            storeName: store?.name,
            storeType: store?.storeType,
          ),
          MiniAppProduct(
            id: 'prod-002',
            name: 'Penne Rigate N.73 QUESTO SI CHE E\' IL BUONO',
            description: 'Pasta di semola di grano duro',
            originalPrice: 3.20,
            currentPrice: 2.79,
            stockLeft: 85,
            minimumOrderQuantity: 1,
            unit: 'g',
            quantity: 500,
            shelfCode: '01-02-04',
            categoryId: 'cat-barilla',
            subcategoryId: subcategoryId,
            storeId: storeId,
            storeName: store?.name,
            storeType: store?.storeType,
          ),
          MiniAppProduct(
            id: 'prod-003',
            name: 'Fusilli N.98 NON CI POSSO CREDERE QUANTO E\' BUONO',
            description: 'Pasta corta di semola di grano duro',
            originalPrice: 3.30,
            currentPrice: 2.85,
            stockLeft: 42,
            minimumOrderQuantity: 1,
            unit: 'g',
            quantity: 500,
            shelfCode: '01-02-05',
            categoryId: 'cat-barilla',
            subcategoryId: subcategoryId,
            storeId: storeId,
            storeName: store?.name,
            storeType: store?.storeType,
          ),
          MiniAppProduct(
            id: 'prod-004',
            name: 'Tagliatelle all\'Uovo',
            description: 'Pasta all\'uovo - Traditional recipe',
            originalPrice: 4.50,
            currentPrice: 3.99,
            stockLeft: 28,
            minimumOrderQuantity: 2,
            unit: 'g',
            quantity: 250,
            shelfCode: '01-03-01',
            categoryId: 'cat-barilla',
            subcategoryId: subcategoryId,
            storeId: storeId,
            storeName: store?.name,
            storeType: store?.storeType,
          ),
        ]);
        break;

      case 'sub-spaghetti':
        products.addAll([
          MiniAppProduct(
            id: 'prod-011',
            name: 'Spaghetti N.5',
            description: 'Classic Italian spaghetti - Perfect al dente',
            originalPrice: 2.90,
            currentPrice: 2.49,
            stockLeft: 200,
            minimumOrderQuantity: 1,
            unit: 'g',
            quantity: 500,
            shelfCode: '01-01-01',
            categoryId: 'cat-barilla',
            subcategoryId: subcategoryId,
            storeId: storeId,
            storeName: store?.name,
            storeType: store?.storeType,
          ),
          MiniAppProduct(
            id: 'prod-012',
            name: 'Spaghettini N.3',
            description: 'Thin spaghetti - Quick cooking',
            originalPrice: 2.90,
            currentPrice: 2.49,
            stockLeft: 120,
            minimumOrderQuantity: 1,
            unit: 'g',
            quantity: 500,
            shelfCode: '01-01-02',
            categoryId: 'cat-barilla',
            subcategoryId: subcategoryId,
            storeId: storeId,
            storeName: store?.name,
            storeType: store?.storeType,
          ),
          MiniAppProduct(
            id: 'prod-013',
            name: 'Spaghetti Integrale',
            description: 'Whole wheat spaghetti - Rich in fiber',
            originalPrice: 3.50,
            currentPrice: 2.99,
            stockLeft: 65,
            minimumOrderQuantity: 1,
            unit: 'g',
            quantity: 500,
            shelfCode: '01-01-03',
            categoryId: 'cat-barilla',
            subcategoryId: subcategoryId,
            storeId: storeId,
            storeName: store?.name,
            storeType: store?.storeType,
          ),
        ]);
        break;

      case 'sub-sugo':
        products.addAll([
          MiniAppProduct(
            id: 'prod-021',
            name: 'Sugo Basilico',
            description: 'Tomato sauce with fresh basil',
            originalPrice: 4.20,
            currentPrice: 3.49,
            stockLeft: 78,
            minimumOrderQuantity: 1,
            unit: 'g',
            quantity: 400,
            shelfCode: '02-01-01',
            categoryId: 'cat-barilla',
            subcategoryId: subcategoryId,
            storeId: storeId,
            storeName: store?.name,
            storeType: store?.storeType,
          ),
          MiniAppProduct(
            id: 'prod-022',
            name: 'Sugo Arrabbiata',
            description: 'Spicy tomato sauce with chili peppers',
            originalPrice: 4.50,
            currentPrice: 3.79,
            stockLeft: 45,
            minimumOrderQuantity: 1,
            unit: 'g',
            quantity: 400,
            shelfCode: '02-01-02',
            categoryId: 'cat-barilla',
            subcategoryId: subcategoryId,
            storeId: storeId,
            storeName: store?.name,
            storeType: store?.storeType,
          ),
          MiniAppProduct(
            id: 'prod-023',
            name: 'Sugo Bolognese',
            description: 'Traditional meat sauce - slow cooked',
            originalPrice: 5.90,
            currentPrice: 4.99,
            stockLeft: 32,
            minimumOrderQuantity: 1,
            unit: 'g',
            quantity: 400,
            shelfCode: '02-01-03',
            categoryId: 'cat-barilla',
            subcategoryId: subcategoryId,
            storeId: storeId,
            storeName: store?.name,
            storeType: store?.storeType,
          ),
        ]);
        break;

      case 'sub-espresso':
        products.addAll([
          MiniAppProduct(
            id: 'prod-031',
            name: 'Miscela Blu Capsules',
            description: 'Intense espresso - Compatible with Nespresso',
            originalPrice: 8.90,
            currentPrice: 7.49,
            stockLeft: 95,
            minimumOrderQuantity: 1,
            unit: 'capsule',
            quantity: 50,
            shelfCode: '03-01-01',
            categoryId: 'cat-borbone',
            subcategoryId: subcategoryId,
            storeId: storeId,
            storeName: store?.name,
            storeType: store?.storeType,
          ),
          MiniAppProduct(
            id: 'prod-032',
            name: 'Miscela Rossa Capsules',
            description: 'Full-bodied espresso - Rich and creamy',
            originalPrice: 8.90,
            currentPrice: 7.49,
            stockLeft: 88,
            minimumOrderQuantity: 1,
            unit: 'capsule',
            quantity: 50,
            multiplier: 2,
            shelfCode: '03-01-02',
            categoryId: 'cat-borbone',
            subcategoryId: subcategoryId,
            storeId: storeId,
            storeName: store?.name,
            storeType: store?.storeType,
          ),
          MiniAppProduct(
            id: 'prod-033',
            name: 'Miscela Oro Capsules',
            description: 'Premium blend - Smooth and balanced',
            originalPrice: 9.90,
            currentPrice: 8.49,
            stockLeft: 62,
            minimumOrderQuantity: 1,
            unit: 'capsule',
            quantity: 50,
            multiplier: 5,
            shelfCode: '03-01-03',
            categoryId: 'cat-borbone',
            subcategoryId: subcategoryId,
            storeId: storeId,
            storeName: store?.name,
            storeType: store?.storeType,
          ),
        ]);
        break;

      default:
        // Generate generic products for other subcategories
        for (int i = 1; i <= 6; i++) {
          products.add(
            MiniAppProduct(
              id: 'prod-gen-$subcategoryId-$i',
              name: 'Product $i',
              description: 'Premium quality product from this subcategory',
              originalPrice: 5.99 + (i * 0.5),
              currentPrice: 4.99 + (i * 0.3),
              stockLeft: 50 + (i * 10),
              minimumOrderQuantity: i % 3 == 0 ? 2 : 1,
              unit: 'g',
              quantity: 250 + (i * 50),
              shelfCode: '0$i-01-0$i',
              categoryId: subcategoryId.split('-')[1],
              subcategoryId: subcategoryId,
              storeId: storeId,
              storeName: store?.name,
              storeType: store?.storeType,
            ),
          );
        }
    }

    return products;
  }

  // ============================================
  // SERVICES (for to X)
  // ============================================

  static List<MiniAppService> getServicesForSubcategory(String subcategoryId) {
    return _generateMockServices(subcategoryId);
  }

  static List<MiniAppService> _generateMockServices(String subcategoryId) {
    final services = <MiniAppService>[];

    switch (subcategoryId) {
      case 'sub-axa-health':
        services.addAll([
          MiniAppService(
            id: 'serv-001',
            name: 'AXA Health Basic',
            description: 'Essential health coverage with hospital and specialist visits',
            originalPrice: 299,
            currentPrice: 249,
            provider: 'AXA',
            categoryId: 'cat-axa',
            subcategoryId: subcategoryId,
            features: ['Hospital coverage', 'Specialist visits', '24/7 helpline'],
          ),
          MiniAppService(
            id: 'serv-002',
            name: 'AXA Health Plus',
            description: 'Comprehensive coverage including dental and vision',
            originalPrice: 499,
            currentPrice: 429,
            provider: 'AXA',
            categoryId: 'cat-axa',
            subcategoryId: subcategoryId,
            features: ['All Basic features', 'Dental coverage', 'Vision care', 'Mental health'],
          ),
          MiniAppService(
            id: 'serv-003',
            name: 'AXA Health Premium',
            description: 'Full coverage with worldwide protection and private rooms',
            priceRange: '€599 - €899/month',
            provider: 'AXA',
            categoryId: 'cat-axa',
            subcategoryId: subcategoryId,
            features: ['Worldwide coverage', 'Private rooms', 'No waiting period', 'Free checkups'],
          ),
        ]);
        break;

      case 'sub-axa-car':
        services.addAll([
          MiniAppService(
            id: 'serv-011',
            name: 'AXA Auto Basic',
            description: 'Third party liability coverage',
            originalPrice: 89,
            currentPrice: 69,
            provider: 'AXA',
            categoryId: 'cat-axa',
            subcategoryId: subcategoryId,
          ),
          MiniAppService(
            id: 'serv-012',
            name: 'AXA Auto Plus',
            description: 'Partial casco with theft and natural damage protection',
            originalPrice: 159,
            currentPrice: 129,
            provider: 'AXA',
            categoryId: 'cat-axa',
            subcategoryId: subcategoryId,
          ),
          MiniAppService(
            id: 'serv-013',
            name: 'AXA Auto Premium',
            description: 'Full casco coverage with roadside assistance',
            priceRange: '€199 - €349/month',
            provider: 'AXA',
            categoryId: 'cat-axa',
            subcategoryId: subcategoryId,
          ),
        ]);
        break;

      case 'sub-voda-mobile':
        services.addAll([
          MiniAppService(
            id: 'serv-021',
            name: 'Vodafone Smart S',
            description: '5GB data, unlimited calls & SMS - EU roaming included',
            originalPrice: 29.99,
            currentPrice: 19.99,
            provider: 'Vodafone',
            categoryId: 'cat-vodafone',
            subcategoryId: subcategoryId,
          ),
          MiniAppService(
            id: 'serv-022',
            name: 'Vodafone Smart M',
            description: '15GB data, unlimited calls & SMS - EU roaming included',
            originalPrice: 39.99,
            currentPrice: 29.99,
            provider: 'Vodafone',
            categoryId: 'cat-vodafone',
            subcategoryId: subcategoryId,
          ),
          MiniAppService(
            id: 'serv-023',
            name: 'Vodafone Unlimited',
            description: 'Unlimited data, calls & SMS - 5G included',
            originalPrice: 59.99,
            currentPrice: 49.99,
            provider: 'Vodafone',
            categoryId: 'cat-vodafone',
            subcategoryId: subcategoryId,
          ),
        ]);
        break;

      case 'sub-voda-home':
        services.addAll([
          MiniAppService(
            id: 'serv-031',
            name: 'Vodafone Home 100',
            description: '100 Mbps fiber connection - Router included',
            originalPrice: 49.99,
            currentPrice: 39.99,
            provider: 'Vodafone',
            categoryId: 'cat-vodafone',
            subcategoryId: subcategoryId,
          ),
          MiniAppService(
            id: 'serv-032',
            name: 'Vodafone Home 500',
            description: '500 Mbps fiber connection - Premium router',
            originalPrice: 69.99,
            currentPrice: 54.99,
            provider: 'Vodafone',
            categoryId: 'cat-vodafone',
            subcategoryId: subcategoryId,
          ),
          MiniAppService(
            id: 'serv-033',
            name: 'Vodafone Home Giga',
            description: '1 Gbps fiber - WiFi 6 router - Priority support',
            originalPrice: 89.99,
            currentPrice: 69.99,
            provider: 'Vodafone',
            categoryId: 'cat-vodafone',
            subcategoryId: subcategoryId,
          ),
        ]);
        break;

      default:
        // Generate generic services
        for (int i = 1; i <= 4; i++) {
          services.add(
            MiniAppService(
              id: 'serv-gen-$subcategoryId-$i',
              name: 'Service Plan $i',
              description: 'Quality service with excellent customer support',
              originalPrice: 49.99 + (i * 20),
              currentPrice: 39.99 + (i * 15),
              provider: 'Provider',
              categoryId: subcategoryId.split('-')[1],
              subcategoryId: subcategoryId,
            ),
          );
        }
    }

    return services;
  }

  // ============================================
  // RECOMMENDED PRODUCTS
  // ============================================

  static List<MiniAppProduct> getRecommendedProducts(String storeId) {
    // Get store info to include in products
    final store = _getStoreById(storeId);
    
    // Return a mix of products from different categories
    final recommended = <MiniAppProduct>[];
    
    recommended.addAll(_generateMockProducts('sub-pasta', storeId, store).take(2));
    recommended.addAll(_generateMockProducts('sub-espresso', storeId, store).take(2));
    recommended.addAll(_generateMockProducts('sub-sugo', storeId, store).take(2));
    
    return recommended;
  }
}
