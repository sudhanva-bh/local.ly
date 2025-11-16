import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/models/orders/order_model.dart';
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';
import 'package:locally/common/providers/orders/order_providers.dart';
// New imports for providers
import 'package:locally/common/providers/product_service_providers.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/features/retail_seller/products/pages/view_product.dart';

// List of statuses for the tracker
const List<String> _orderStatuses = [
  'Pending',
  'Confirmed',
  'Shipped',
  'Delivered',
  'Received',
];
// Separate 'Cancelled' as it's a special state
const String _cancelledStatus = 'Cancelled';
// 'Received' status constant
const String _receivedStatus = 'Received';

class OrderDetailPage extends ConsumerWidget {
  final String orderId;
  final bool isWholesaleSeller;

  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.isWholesaleSeller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(wholesaleRetailOrderByIdProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found.'));
          }
          return _buildOrderDetails(context, ref, order);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      // (Unchanged) Floating Action Button for Retail Seller
      floatingActionButton: orderAsync.whenOrNull(
        data: (order) {
          if (order != null &&
              !isWholesaleSeller &&
              order.status == 'Delivered') {
            return FloatingActionButton.extended(
              onPressed: () {
                try {
                  final wholesaleRetailOrderService = ref.read(
                    wholesaleRetailOrderServiceProvider,
                  );
                  wholesaleRetailOrderService.updateOrderStatus(
                    order.orderId,
                    _receivedStatus,
                  );
                  wholesaleRetailOrderService.addOrderToRetailerInventory(
                    order,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update status: $e'),
                      backgroundColor: context.colors.error,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark as Received'),
            );
          }
          return null;
        },
      ),
    );
  }

  /// Main widget that builds the scrollable list of order details
  Widget _buildOrderDetails(
    BuildContext context,
    WidgetRef ref,
    WholesaleRetailOrder order,
  ) {
    final textTheme = Theme.of(context).textTheme;

    // ✅ --- NEW: Check if the order is in a final state ---
    final isOrderFinal =
        (order.status == _cancelledStatus || order.status == _receivedStatus);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Section 1: Main Info ---
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Order ID',
                  value: order.orderId,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  icon: Icons.monetization_on,
                  title: 'Total Amount',
                  value: '\$${order.totalAmount.toStringAsFixed(2)}',
                  valueStyle: textTheme.titleLarge?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),
                Text('Status', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                _OrderTracker(currentStatus: order.status),
                const Divider(height: 36),
                _buildInfoRow(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Date Created',
                  value: DateFormat.yMMMd().add_jm().format(order.createdAt),
                ),
                // ✅ --- MODIFIED: Show buttons only if seller AND order is not final ---
                if (isWholesaleSeller && !isOrderFinal) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // --- NEW: Cancel Button ---
                      TextButton(
                        onPressed: () =>
                            _showCancelConfirmationDialog(context, ref, order),
                        style: TextButton.styleFrom(
                          foregroundColor: context.colors.error,
                        ),
                        child: const Text('Cancel Order'),
                      ),
                      // --- Update Status Button ---
                      FilledButton.tonal(
                        onPressed: () =>
                            _showStatusUpdateSheet(context, ref, order),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: const Text('Update Status'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // --- Section 2: Items ---
        Text('Items', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            itemBuilder: (context, index) {
              final item = order.items[index];
              return _ItemTileWrapper(item: item);
            },
          ),
        ),

        const SizedBox(height: 16),

        // --- Section 3: Other Details ---
        Text('Other Details', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  icon: Icons.store,
                  title: 'Wholesale Shop',
                  customValue: _ProfileName(userId: order.wholesaleShopId),
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  icon: Icons.person,
                  title: 'Retail Seller',
                  customValue: _ProfileName(userId: order.retailSellerId),
                ),
              ],
            ),
          ),
        ),
        // Add padding at the bottom to avoid FAB overlap
        const SizedBox(height: 80),
      ],
    );
  }

  // ✅ --- NEW: Confirmation Dialog for Cancelling ---
  void _showCancelConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    WholesaleRetailOrder order,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Order?'),
          content: const Text(
            'Are you sure you want to cancel this order? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  ref
                      .read(wholesaleRetailOrderServiceProvider)
                      .updateOrderStatus(order.orderId, _cancelledStatus);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel order: $e'),
                      backgroundColor: context.colors.error,
                    ),
                  );
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.error,
                foregroundColor: context.colors.onError,
              ),
              child: const Text('Yes, Cancel Order'),
            ),
          ],
        );
      },
    );
  }

  /// (Unchanged) Modal sheet to update status (FOR WHOLESALE SELLER)
  void _showStatusUpdateSheet(
    BuildContext context,
    WidgetRef ref,
    WholesaleRetailOrder order,
  ) {
    // This list correctly OMITS 'Received'.
    const allStatuses = [
      'Pending',
      'Confirmed',
      'Shipped',
      'Delivered',
      'Cancelled',
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Order Status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Column(
                children: allStatuses.map((status) {
                  return ListTile(
                    title: Text(status),
                    trailing: (order.status == status)
                        ? Icon(
                            Icons.check_circle,
                            color: context.colors.primary,
                          )
                        : null,
                    onTap: () {
                      try {
                        ref
                            .read(wholesaleRetailOrderServiceProvider)
                            .updateOrderStatus(order.orderId, status);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update status: $e'),
                            backgroundColor: context.colors.error,
                          ),
                        );
                      }
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// (Unchanged) Helper widget to build consistent info rows
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? value,
    Widget? customValue,
    TextStyle? valueStyle,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.colors.onSurfaceVariant, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 4),
              customValue ??
                  Text(
                    value ?? 'N/A',
                    style: valueStyle ?? textTheme.bodyLarge,
                    softWrap: true,
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- (ALL WIDGETS BELOW ARE UNCHANGED) ---

/// (Unchanged) Order Tracker Widget
class _OrderTracker extends StatelessWidget {
  final String currentStatus;

  const _OrderTracker({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    // Handle 'Cancelled' state
    if (currentStatus == _cancelledStatus) {
      return Row(
        children: [
          Icon(Icons.cancel, color: context.colors.error),
          const SizedBox(width: 8),
          Text(
            'Order Cancelled',
            style: TextStyle(
              color: context.colors.error,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    // Get the index of the current status
    int currentIndex = _orderStatuses.indexOf(currentStatus);
    if (currentIndex == -1) {
      currentIndex = 0; // Default to first step if status is unknown
    }

    return Column(
      children: [
        Row(
          children: [
            _OrderTrackerStep(
              icon: Icons.pending_actions,
              title: 'Pending',
              isActive: currentIndex >= 0,
            ),
            _TrackerLine(isActive: currentIndex >= 1),
            _OrderTrackerStep(
              icon: Icons.check_circle,
              title: 'Confirmed',
              isActive: currentIndex >= 1,
            ),
            _TrackerLine(isActive: currentIndex >= 2),
            _OrderTrackerStep(
              icon: Icons.local_shipping,
              title: 'Shipped',
              isActive: currentIndex >= 2,
            ),
            _TrackerLine(isActive: currentIndex >= 3),
            _OrderTrackerStep(
              icon: Icons.inventory_2,
              title: 'Delivered',
              isActive: currentIndex >= 3,
            ),
            _TrackerLine(isActive: currentIndex >= 4),
            _OrderTrackerStep(
              icon: Icons.inventory,
              title: 'Received',
              isActive: currentIndex >= 4,
            ),
          ],
        ),
      ],
    );
  }
}

/// (Unchanged) Helper for the connecting line
class _TrackerLine extends StatelessWidget {
  final bool isActive;
  const _TrackerLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive
            ? context.colors.primary
            : context.colors.outlineVariant,
      ),
    );
  }
}

/// (Unchanged) Helper for each step in the tracker
class _OrderTrackerStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;

  const _OrderTrackerStep({
    required this.icon,
    required this.title,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? context.colors.primary
        : context.colors.onSurfaceVariant;

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          title,
          style: context.text.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// (Unchanged) Helper widget to fetch and display a profile's shop name
class _ProfileName extends ConsumerWidget {
  final String userId;
  const _ProfileName({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(getProfileByIdProvider(userId));

    return profileAsync.when(
      data: (seller) => Text(
        seller.shopName,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      loading: () => const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (e, s) => const Text(
        'Unknown User',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }
}

/// (Unchanged) Wrapper widget to fetch data for the tile
class _ItemTileWrapper extends ConsumerWidget {
  final Map<String, dynamic> item;
  const _ItemTileWrapper({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productId = item['productId'] as String;
    final quantity = item['quantity'] as int;

    final productAsync = ref.watch(wholesaleProductByIdProvider(productId));

    return productAsync.when(
      data: (product) {
        if (product == null) {
          return const ListTile(
            title: Text('Product not found'),
            leading: Icon(Icons.error_outline),
          );
        }
        return _ItemTile(product: product, quantity: quantity);
      },
      loading: () => const ListTile(
        title: Text('Loading product...'),
      ),
      error: (e, s) => const ListTile(
        title: Text('Error loading product'),
        leading: Icon(Icons.error_outline),
      ),
    );
  }
}

/// (Unchanged) _ItemTile is now a "dumb" StatelessWidget
class _ItemTile extends StatelessWidget {
  final WholesaleProduct product;
  final int quantity;

  const _ItemTile({
    required this.product,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = (product.imageUrls.isNotEmpty)
        ? product.imageUrls.first
        : null;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewProduct(productId: product.productId),
          ),
        );
        ViewProduct(productId: product.productId);
      },
      child: ListTile(
        leading: (imageUrl != null)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.shopping_basket_outlined, size: 40),
                ),
              )
            : const Icon(Icons.shopping_basket_outlined, size: 40),
        title: Text(
          product.productName,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Quantity: $quantity',
          style: context.text.bodyMedium,
        ),
      ),
    );
  }
}
