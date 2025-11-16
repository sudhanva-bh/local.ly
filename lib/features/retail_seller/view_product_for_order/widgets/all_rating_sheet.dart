import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/ratings/rating_model.dart';
import 'package:locally/features/retail_seller/view_product_for_order/widgets/rating_card.dart';

/// This function shows the modal bottom sheet
void showAllRatingsSheet(BuildContext context, List<Rating> allRatings) {
  final text = context.text;
  final colors = context.colors;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allows sheet to take up more height
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false, // Content-sized
        initialChildSize: 0.6, // Start at 60%
        minChildSize: 0.4, // Min 40%
        maxChildSize: 0.9, // Max 90%
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // --- Sheet Header ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "All Reviews (${allRatings.length})",
                        style: text.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colors.outline.withOpacity(0.3)),

                // --- Scrollable List ---
                Expanded(
                  child: ListView.separated(
                    controller: scrollController, // Important for scrolling
                    padding: const EdgeInsets.all(20),
                    itemCount: allRatings.length,
                    itemBuilder: (context, index) {
                      return ProductRatingCard(rating: allRatings[index]);
                    },
                    separatorBuilder: (context, index) => Divider(
                      color: colors.outline.withOpacity(0.2),
                      height: 32,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}