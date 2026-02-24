import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/screens/base_mini_app_home.dart';
import '../../core/widgets/mini_app_app_bar.dart';
import '../../core/providers/mini_app_providers.dart';
import '../../domain/enums/mini_app_type.dart';

/// toB Home Screen - Business to Business
///
/// Customizations specific to toB:
/// - MOQ (Minimum Order Quantity) indicators
/// - Bulk pricing display
/// - B2B-specific filters
///
/// Currently uses default implementation,
/// override methods to add toB-specific features:
/// - [buildHeader] - Add MOQ badge to header
/// - [buildSectionHeader] - Show B2B-specific sections
class ToBHomeScreen extends BaseMiniAppHome {
  const ToBHomeScreen({super.key});

  @override
  MiniAppType get miniAppType => MiniAppType.toB;

  @override
  ConsumerState<ToBHomeScreen> createState() => _ToBHomeScreenState();
}

class _ToBHomeScreenState extends BaseMiniAppHomeState<ToBHomeScreen> {
  @override
  Widget buildHeader(BuildContext context) {
    final storesAsync = ref.watch(miniAppStoresProvider(widget.miniAppType));
    final selectedStore = ref.watch(selectedStoreProvider(widget.miniAppType));

    return MiniAppAppBar(
      miniAppType: widget.miniAppType,
      selectedStore: selectedStore,
      stores: storesAsync.value ?? [],
      onStoreChanged: handleStoreChanged,
      onClose: handleClose,
    );
  }
}
