import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/screens/base_mini_app_home.dart';
import '../../core/widgets/mini_app_app_bar.dart';
import '../../core/providers/mini_app_providers.dart';
import '../../domain/enums/mini_app_type.dart';

/// toC Home Screen - Business to Consumer
/// 
/// Customizations specific to toC:
/// - Consumer reviews integration
/// - Wishlist functionality
/// - Personal recommendations
/// - Social sharing
/// 
/// Currently uses default implementation, 
/// override methods to add toC-specific features.
class ToCHomeScreen extends BaseMiniAppHome {
  const ToCHomeScreen({super.key});

  @override
  MiniAppType get miniAppType => MiniAppType.toC;

  @override
  ConsumerState<ToCHomeScreen> createState() => _ToCHomeScreenState();
}

class _ToCHomeScreenState extends BaseMiniAppHomeState<ToCHomeScreen> {
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
  // FUTURE toC CUSTOMIZATIONS (uncomment when needed):
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
  //       super.buildSectionHeader(context, categories, selectedCategoryId),
  //       // Add personalized recommendations
  //       const _PersonalizedSection(),
  //     ],
  //   );
  // }
}
