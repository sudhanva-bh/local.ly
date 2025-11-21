import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/extensions/content_extensions.dart';

import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/common/models/orders/order_item_model.dart';
import 'package:locally/common/models/users/seller_model.dart';
import 'package:locally/common/providers/consumer_profile_provider.dart';
import 'package:locally/common/providers/product_service_providers.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/common/services/chat/chat_service.dart';
import 'package:locally/common/services/orders/consumer_order_service.dart';
import 'package:locally/features/chat/pages/chat_screen.dart';
import 'package:locally/features/consumer/view_orders/services/invoice_service.dart';
import 'package:locally/features/consumer/view_product/pages/consumer_view_product.dart';
import 'package:locally/features/view_seller/pages/view_seller_page.dart';

// -----------------------------------------------------------------------------
// 📄 PAGE: MY ORDERS (List View)
// -----------------------------------------------------------------------------
class ConsumerOrdersPage extends ConsumerWidget {
  const ConsumerOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: context.colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: context.colors.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: context.text.headlineSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your order history will appear here.',
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.outline,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16).copyWith(bottom: 160),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              // Now using the Expandable Card
              return OrderExpandableCard(order: order);
            },
          );
        },
        error: (err, stack) =>
            Center(child: Text('Something went wrong: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🃏 WIDGET: EXPANDABLE ORDER CARD
// -----------------------------------------------------------------------------
class OrderExpandableCard extends StatelessWidget {
  final OrderModel order;

  const OrderExpandableCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'MMM dd, yyyy • hh:mm a',
    ).format(order.createdAt);
    final totalStr = NumberFormat.currency(
      symbol: '₹',
    ).format(order.totalAmount);

    return Card(
      elevation: 0,
      color: context.colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colors.outlineVariant.withOpacity(0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Remove the default divider lines of ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: Border.all(color: Colors.transparent),
          collapsedShape: Border.all(color: Colors.transparent),

          // --- Header (Always Visible) ---
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Order #${order.id.substring(0, 8).toUpperCase()}",
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              StatusChip(status: order.status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalStr,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.colors.primary,
                  ),
                ),
              ],
            ),
          ),

          // --- Body (Expanded Content) ---
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 8),

                  // Real-time Items List
                  if (order.items != null && order.items!.isNotEmpty)
                    ...order.items!.map(
                      (item) => RealtimeOrderItemRow(item: item),
                    ),

                  if (order.items == null || order.items!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "No items info available",
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.outline,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // "View Full Details" Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderDetailsScreen(order: order),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long),
                      label: const Text("View Full Details"),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final OrderStatus status;
  const StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      OrderStatus.pending => (context.colors.onSurface, "Pending"),
      OrderStatus.accepted => (context.colors.onSurface, "Accepted"),
      OrderStatus.shipped => (context.colors.onSurface, "Shipped"),
      OrderStatus.delivered => (Colors.green, "Delivered"),
      OrderStatus.cancelled => (context.colors.error, "Cancelled"),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderTracker extends StatelessWidget {
  final OrderStatus status;
  const OrderTracker({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // 2. Cancelled State Handling
    if (status == OrderStatus.cancelled) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.errorContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.error.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, color: context.colors.error),
            const SizedBox(width: 12),
            Text(
              "Order Cancelled",
              style: context.text.titleMedium?.copyWith(
                color: context.colors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // 3. Define Steps
    final steps = [
      (OrderStatus.pending, 'Placed', Icons.receipt_long_rounded),
      (OrderStatus.accepted, 'Accepted', Icons.store_rounded),
      (OrderStatus.shipped, 'Shipped', Icons.local_shipping_rounded),
      (OrderStatus.delivered, 'Delivered', Icons.check_circle_rounded),
    ];

    final currentIndex = steps.indexWhere((s) => s.$1 == status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length, (index) {
          final isCompleted = index < currentIndex;
          final isCurrent = index == currentIndex;
          final isActive = index <= currentIndex;

          final primaryColor = context.colors.primary;
          final greyColor = context.colors.outlineVariant;
          final onPrimary = context.colors.onPrimary;

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- The Stepper Row (Fixed Height Wrapper) ---
                // We wrap the entire line+icon row in a SizedBox of height 40.
                // This ensures alignment is consistent regardless of icon animation.
                SizedBox(
                  height: 40,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left Line
                      Expanded(
                        child: Container(
                          height: 4,
                          color: index == 0
                              ? Colors.transparent
                              : (isActive
                                    ? primaryColor
                                    : greyColor.withOpacity(0.3)),
                        ),
                      ),

                      // The Icon Node
                      // Wrapper prevents layout shift when inner container grows
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: isCurrent ? 40 : 32,
                            height: isCurrent ? 40 : 32,
                            decoration: BoxDecoration(
                              color: isCompleted || isCurrent
                                  ? primaryColor
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive ? primaryColor : greyColor,
                                width: 2,
                              ),
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Icon(
                                isCompleted ? Icons.check : steps[index].$3,
                                size: isCurrent ? 20 : 16,
                                color: isCompleted || isCurrent
                                    ? onPrimary
                                    : greyColor,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Right Line
                      Expanded(
                        child: Container(
                          height: 4,
                          color: index == steps.length - 1
                              ? Colors.transparent
                              : (index < currentIndex
                                    ? primaryColor
                                    : greyColor.withOpacity(0.3)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // --- The Text Label ---
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: isCurrent
                      ? context.text.labelLarge!.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                        )
                      : context.text.labelMedium!.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                  child: Text(
                    steps[index].$2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 📄 PAGE: ORDER DETAILS SCREEN (Modern & Full)
// -----------------------------------------------------------------------------
class OrderDetailsScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  // 2. Add state variables for loading indicators
  bool _isGeneratingInvoice = false;
  bool _isStartingChat = false;

  @override
  Widget build(BuildContext context) {
    // Access widget properties via 'widget.order'
    final order = widget.order;

    final dateStr = DateFormat('MMM dd, yyyy').format(order.createdAt);
    final timeStr = DateFormat('hh:mm a').format(order.createdAt);

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: const Text("Order Details"),
        centerTitle: true,
        backgroundColor: context.colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO HEADER
            OrderHeaderCard(
              orderId: order.id,
              sellerId: order.sellerId,
              date: dateStr,
              time: timeStr,
              status: order.status,
              child: OrderTracker(status: order.status),
            ),
            const SizedBox(height: 20),

            // 2. DELIVERY INFO CARD
            SectionLabel(label: "Shipping Information"),
            const SizedBox(height: 8),
            AddressCard(address: order.deliveryAddress),
            const SizedBox(height: 24),

            // 3. ITEMS LIST
            SectionLabel(label: "Items Ordered"),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.colors.outlineVariant.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  if (order.items != null)
                    ...order.items!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isLast = index == order.items!.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: RealtimeOrderItemRow(
                              item: item,
                              isEmbedded: true,
                            ),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: context.colors.outlineVariant.withOpacity(
                                0.2,
                              ),
                            ),
                        ],
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. BILL SUMMARY
            BillSummaryCard(totalAmount: order.totalAmount),

            const SizedBox(height: 40),
          ],
        ),
      ),
      // 5. BOTTOM ACTION BAR
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // --- INVOICE BUTTON ---
              Expanded(
                child: OutlinedButton.icon(
                  // Disable button while loading to prevent double-taps
                  onPressed: _isGeneratingInvoice
                      ? null
                      : () async {
                          setState(() => _isGeneratingInvoice = true);
                          try {
                            await InvoiceService.generateAndOpenInvoice(order);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Could not generate invoice: $e",
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isGeneratingInvoice = false);
                            }
                          }
                        },
                  // Switch icon to spinner if loading
                  icon: _isGeneratingInvoice
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colors.primary,
                          ),
                        )
                      : const Icon(Icons.receipt_long),
                  label: Text(_isGeneratingInvoice ? "Loading..." : "Invoice"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // --- SUPPORT BUTTON ---
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isStartingChat
                      ? null
                      : () async {
                          setState(() => _isStartingChat = true);
                          try {
                            final chatService = ref.read(chatServiceProvider);
                            final sellerId = order.sellerId;
                            final currentConsumer = ref.read(
                              currentConsumerProfileProvider,
                            );

                            final roomId = await chatService
                                .createOrGetChatRoom(
                                  currentConsumer.value!.uid,
                                  sellerId,
                                  myType: "consumer",
                                  otherType: "seller",
                                );

                            final profileResult = await ref
                                .read(profileServiceProvider)
                                .getProfile(sellerId);

                            final sellerProfile = profileResult.match(
                              (error) => throw Exception("Failed: $error"),
                              (seller) => seller,
                            );

                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    roomId: roomId,
                                    otherUser: sellerProfile,
                                    myId: currentConsumer.value!.uid,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error starting chat: $e"),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isStartingChat = false);
                            }
                          }
                        },
                  icon: _isStartingChat
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context
                                .colors
                                .onPrimary, // High contrast on filled button
                          ),
                        )
                      : const Icon(Icons.support_agent),
                  label: Text(_isStartingChat ? "Connecting..." : "Support"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🧱 MODERN UI COMPONENTS
// -----------------------------------------------------------------------------

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: context.text.labelMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class OrderHeaderCard extends StatelessWidget {
  final String orderId;
  final String sellerId;
  final String date;
  final String time;
  final OrderStatus status;
  final Widget child; // The Tracker

  const OrderHeaderCard({
    required this.orderId,
    required this.sellerId,
    required this.date,
    required this.time,
    required this.status,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer, // Slightly darker than bg
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order #${orderId.substring(0, 8).toUpperCase()}",
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$date • $time",
                        style: context.text.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(status: status), // Reusing your existing StatusChip
              ],
            ),
          ),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewSellerPage(sellerId: sellerId),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.storefront, color: context.colors.primary),
                  const SizedBox(width: 26),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sold by",
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        // 🌟 UPDATED SELLER FETCH LOGIC 🌟
                        Consumer(
                          builder: (context, ref, _) {
                            return ref
                                .watch(
                                  getProfileByIdProvider(
                                    sellerId,
                                  ),
                                )
                                .when(
                                  data: (seller) => Text(
                                    seller
                                        .shopName, // Assuming Shop Name for sellers
                                    style: context.text.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  loading: () => const SizedBox(
                                    height: 10,
                                    width: 50,
                                    child: LinearProgressIndicator(),
                                  ),
                                  error: (_, __) =>
                                      const Text("Unknown Seller"),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Divider that fades out
          Divider(
            height: 8,
            color: context.colors.outlineVariant.withOpacity(0.2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: child, // The Tracker Widget
          ),
        ],
      ),
    );
  }
}

class AddressCard extends StatelessWidget {
  final String address;
  const AddressCard({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Delivery Address",
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: context.text.bodyMedium?.copyWith(height: 1.3),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BillSummaryCard extends StatelessWidget {
  final double totalAmount;
  const BillSummaryCard({required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer.withOpacity(
          0.2,
        ), // Subtle tint
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.colors.outlineVariant.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // Mock Data for "Fuller" look
          _buildSummaryRow(
            context,
            "Subtotal",
            "₹${totalAmount.toStringAsFixed(2)}",
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(context, "Delivery Fee", "Free", isSuccess: true),
          const SizedBox(height: 8),
          _buildSummaryRow(
            context,
            "GST (Included 18%)",
            "₹${(totalAmount * 0.18).toStringAsFixed(2)}",
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: context.colors.onSurfaceVariant.withOpacity(0.2),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Paid",
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "₹${totalAmount.toStringAsFixed(2)}",
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isSuccess = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSuccess ? Colors.green : null,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ⚡ MODIFIED REALTIME ITEM ROW
// Added `isEmbedded` to toggle container styling vs transparent styling
// -----------------------------------------------------------------------------
class RealtimeOrderItemRow extends ConsumerWidget {
  final OrderItemModel item;
  final bool isEmbedded; // New Parameter

  const RealtimeOrderItemRow({
    super.key,
    required this.item,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(retailProductByIdProvider(item.productId));

    return Container(
      // Conditional Styling: If embedded, no margin/decoration. If standalone, use card style.
      margin: isEmbedded ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: isEmbedded
          ? null
          : BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.colors.outlineVariant.withOpacity(0.3),
              ),
            ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ConsumerViewProduct(productId: item.productId),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Section ---
            Container(
              width: 56, // Slightly larger
              height: 56,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: productAsync.when(
                data: (product) {
                  if (product != null && product.imageUrls.isNotEmpty) {
                    return Hero(
                      tag: 'product_img_${item.productId}',
                      child: Image.network(
                        product.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 20),
                      ),
                    );
                  }
                  return Icon(
                    Icons.shopping_bag_outlined,
                    color: context.colors.outline,
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Icon(Icons.error_outline, size: 20),
              ),
            ),
            const SizedBox(width: 16),

            // --- Details Section ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  productAsync.when(
                    data: (product) => Text(
                      product?.name ?? item.productName ?? "Unknown Product",
                      style: context.text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => Container(
                      height: 14,
                      width: 80,
                      color: context.colors.surfaceContainerHigh,
                    ),
                    error: (_, __) => Text(item.productName ?? "Unknown"),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${item.quantity} unit(s)",
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // --- Total Price ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₹${(item.priceAtPurchase * item.quantity).toStringAsFixed(2)}",
                  style: context.text.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "₹${item.priceAtPurchase}/ea",
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
