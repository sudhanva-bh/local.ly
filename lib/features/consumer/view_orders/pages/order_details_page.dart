import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/orders/consumer_order_model.dart';
import 'package:locally/common/providers/consumer_profile_provider.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/common/services/chat/chat_service.dart';
import 'package:locally/common/services/orders/consumer_order_service.dart'; // Contains singleOrderProvider
import 'package:locally/features/chat/pages/chat_screen.dart';
import 'package:locally/features/consumer/view_orders/services/invoice_service.dart';
import 'package:locally/features/consumer/view_orders/widgets/delivery_service.dart';
import 'package:locally/features/consumer/view_orders/widgets/order_detail_components.dart';
import 'package:locally/features/consumer/view_orders/widgets/order_tracker.dart';
import 'package:locally/features/consumer/view_orders/widgets/realtime_order_item_row.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  // ⚠️ CHANGE: Accepts ID only
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  bool _isGeneratingInvoice = false;
  bool _isStartingChat = false;

  @override
  Widget build(BuildContext context) {
    // 📡 WATCH THE STREAM: Fetch data by ID
    final orderAsync = ref.watch(singleOrderProvider(widget.orderId));

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: const Text("Order Details"),
        centerTitle: true,
        backgroundColor: context.colors.surface,
        surfaceTintColor: Colors.transparent,
        actions: const [
          DeliveryScanAction(),
        ],
      ),
      // 🔄 Handle States: Loading, Error, Data
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Failed to load order: $err", textAlign: TextAlign.center),
          ),
        ),
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(order),
              const SizedBox(height: 20),
              
              const SectionLabel(label: "Shipping Information"),
              const SizedBox(height: 8),
              AddressCard(address: order.deliveryAddress),
              const SizedBox(height: 24),
              
              const SectionLabel(label: "Items Ordered"),
              const SizedBox(height: 8),
              _buildItemsList(context, order),
              const SizedBox(height: 24),
              
              BillSummaryCard(totalAmount: order.totalAmount),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      // Only show bottom bar if we have data
      bottomNavigationBar: orderAsync.value != null 
          ? _buildBottomBar(context, orderAsync.value!) 
          : null,
    );
  }

  Widget _buildHeader(OrderModel order) {
    final dateStr = DateFormat('MMM dd, yyyy').format(order.createdAt);
    final timeStr = DateFormat('hh:mm a').format(order.createdAt);

    return OrderHeaderCard(
      orderId: order.id,
      sellerId: order.sellerId,
      date: dateStr,
      time: timeStr,
      status: order.status,
      child: OrderTracker(status: order.status),
    );
  }

  Widget _buildItemsList(BuildContext context, OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant.withOpacity(0.3)),
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
                    child: RealtimeOrderItemRow(item: item, isEmbedded: true),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: context.colors.outlineVariant.withOpacity(0.2),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, OrderModel order) {
    return Container(
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
            Expanded(child: _buildInvoiceButton(context, order)),
            const SizedBox(width: 12),
            Expanded(child: _buildSupportButton(context, order)),
          ],
        ),
      ),
    );
  }

  // ... _buildInvoiceButton and _buildSupportButton remain exactly the same as before ...
  
  Widget _buildInvoiceButton(BuildContext context, OrderModel order) {
    return OutlinedButton.icon(
      onPressed: _isGeneratingInvoice
          ? null
          : () async {
              setState(() => _isGeneratingInvoice = true);
              try {
                await InvoiceService.generateAndOpenInvoice(order);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              } finally {
                if (mounted) setState(() => _isGeneratingInvoice = false);
              }
            },
      icon: _isGeneratingInvoice
          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary))
          : const Icon(Icons.receipt_long),
      label: Text(_isGeneratingInvoice ? "Loading..." : "Invoice"),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSupportButton(BuildContext context, OrderModel order) {
    return FilledButton.icon(
      onPressed: _isStartingChat ? null : () => _handleSupportChat(order),
      icon: _isStartingChat
          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.onPrimary))
          : const Icon(Icons.support_agent),
      label: Text(_isStartingChat ? "Connecting..." : "Support"),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleSupportChat(OrderModel order) async {
    setState(() => _isStartingChat = true);
    try {
      final chatService = ref.read(chatServiceProvider);
      final sellerId = order.sellerId;
      final currentConsumer = ref.read(currentConsumerProfileProvider);

      final roomId = await chatService.createOrGetChatRoom(
        currentConsumer.value!.uid,
        sellerId,
        myType: "consumer",
        otherType: "seller",
      );

      final profileResult = await ref.read(profileServiceProvider).getProfile(sellerId);

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }
}