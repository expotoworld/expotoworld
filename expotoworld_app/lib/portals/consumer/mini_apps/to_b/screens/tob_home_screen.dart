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
  // FUTURE toB CUSTOMIZATIONS (uncomment when needed):
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
  //       // Add MOQ info banner
  //       const _MOQInfoBanner(),
  //     ],
  //   );
  // }
}

// /// MOQ Info Banner (uncomment when needed)
// class _MOQInfoBanner extends StatelessWidget {
//   const _MOQInfoBanner();
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade50,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.info_outline, color: Colors.blue.shade700),
//           const SizedBox(width: 8),
//           Text('MOQ applies to bulk orders'),
//         ],
//       ),
//     );
//   }
// }
