import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/store.dart';
import '../../core/enums/store_type.dart';

class StorageService {
  static const String _mainStoreIdKey = 'main_store_id';
  static const String _mainStoreNameKey = 'main_store_name';
  static const String _mainStoreCityKey = 'main_store_city';
  static const String _mainStoreAddressKey = 'main_store_address';
  static const String _mainStoreLatKey = 'main_store_latitude';
  static const String _mainStoreLngKey = 'main_store_longitude';

  // Save main store to local storage
  static Future<void> saveMainStore(Store store) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_mainStoreIdKey, store.id);
      await prefs.setString(_mainStoreNameKey, store.name);
      await prefs.setString(_mainStoreCityKey, store.city);
      await prefs.setString(_mainStoreAddressKey, store.address);
      await prefs.setDouble(_mainStoreLatKey, store.latitude);
      await prefs.setDouble(_mainStoreLngKey, store.longitude);
      
      debugPrint('Main store saved: ${store.name}');
    } catch (e) {
      debugPrint('Error saving main store: $e');
    }
  }

  // Load main store from local storage
  static Future<Store?> loadMainStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final storeId = prefs.getString(_mainStoreIdKey);
      final storeName = prefs.getString(_mainStoreNameKey);
      final storeCity = prefs.getString(_mainStoreCityKey);
      final storeAddress = prefs.getString(_mainStoreAddressKey);
      final storeLat = prefs.getDouble(_mainStoreLatKey);
      final storeLng = prefs.getDouble(_mainStoreLngKey);

      if (storeId != null &&
          storeName != null &&
          storeCity != null &&
          storeAddress != null &&
          storeLat != null &&
          storeLng != null) {

        final store = Store(
          id: storeId,
          name: storeName,
          city: storeCity,
          address: storeAddress,
          latitude: storeLat,
          longitude: storeLng,
          type: StoreType.unmannedStore, // Main stores are always unmanned stores
        );
        
        debugPrint('Main store loaded: ${store.name}');
        return store;
      }
    } catch (e) {
      debugPrint('Error loading main store: $e');
    }
    
    return null;
  }

  // Clear main store from local storage
  static Future<void> clearMainStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_mainStoreIdKey);
      await prefs.remove(_mainStoreNameKey);
      await prefs.remove(_mainStoreCityKey);
      await prefs.remove(_mainStoreAddressKey);
      await prefs.remove(_mainStoreLatKey);
      await prefs.remove(_mainStoreLngKey);
      
      debugPrint('Main store cleared');
    } catch (e) {
      debugPrint('Error clearing main store: $e');
    }
  }

  // Check if main store is saved
  static Future<bool> hasMainStore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_mainStoreIdKey);
    } catch (e) {
      debugPrint('Error checking main store: $e');
      return false;
    }
  }
}
