import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/screens/base_mini_app_home.dart';
import '../../core/widgets/mini_app_app_bar.dart';
import '../../core/providers/mini_app_providers.dart';
import '../../domain/enums/mini_app_type.dart';

/// toU Home Screen - Business to User (Volume-based)
/// 
/// Customizations specific to toU:
/// - Volume tier indicators
/// - Usage-based pricing
/// - Subscription options
/// - Loyalty rewards display
/// 
/// Currently uses default implementation, 
/// override methods to add toU-specific features.
class ToUHomeScreen extends BaseMiniAppHome {
  const ToUHomeScreen({super.key});

  @override
  MiniAppType get miniAppType => MiniAppType.toU;

  @override
  ConsumerState<ToUHomeScreen> createState() => _ToUHomeScreenState();
}

class _ToUHomeScreenState extends BaseMiniAppHomeState<ToUHomeScreen> {
  @override
  Widget buildHeader(BuildContext context) {
    final stores = ref.watch(miniAppStoresProvider(widget.miniAppType));
    final selectedStore = ref.watch(selectedStoreProvider(widget.miniAppType));

    return MiniAppAppBar(
      miniAppType: widget.miniAppType,
      selectedStore: selectedStore,
      stores: stores,
      onStoreChanged: handleStoreChanged,
      onClose: handleClose,
    );
  }

  // 
  // FUTURE toU CUSTOMIZATIONS (uncomment when needed):
  //
  
  // @override
  // Widget buildSectionHeader(
  //   BuildContext context,
  //   List<MiniAppCategory> categories,
  //   String? selectedCategoryId,
  // ) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Show volume tier status
  //       const _VolumeTierBanner(),
  //       super.buildSectionHeader(context, categories, selectedCategoryId),
  //     ],
  //   );
  // }
}
