import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/orders/order_model.dart';
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';
import 'package:locally/common/providers/orders/order_providers.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:uuid/uuid.dart';

class OrderBottomSheet extends ConsumerStatefulWidget {
  final WholesaleProduct product;

  const OrderBottomSheet({super.key, required this.product});

  @override
  ConsumerState<OrderBottomSheet> createState() => _OrderBottomSheetState();
}

class _OrderBottomSheetState extends ConsumerState<OrderBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late int _quantity;
  late double _totalPrice;

  bool get _isAtMin => _quantity <= widget.product.minOrderQuantity;
  bool get _isAtMax => _quantity >= widget.product.stock;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.minOrderQuantity;
    _quantityController = TextEditingController(text: _quantity.toString());
    _updateTotalPrice();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateTotalPrice() {
    _totalPrice = widget.product.price * _quantity;
  }

  void _increment() {
    if (_isAtMax) return;
    setState(() {
      _quantity++;
      _quantityController.text = _quantity.toString();
      _updateTotalPrice();
      _formKey.currentState?.validate();
    });
  }

  void _decrement() {
    if (_isAtMin) return;
    setState(() {
      _quantity--;
      _quantityController.text = _quantity.toString();
      _updateTotalPrice();
      _formKey.currentState?.validate();
    });
  }

  void _onQuantityChanged(String value) {
    int? newQuantity = int.tryParse(value);
    if (newQuantity == null) return;

    setState(() {
      _quantity = newQuantity;
      if (_quantity >= widget.product.minOrderQuantity &&
          _quantity <= widget.product.stock) {
        _updateTotalPrice();
      }
    });
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) return;

    // Fetch current logged-in user's profile
    final currentUserProfile = ref.read(currentUserProfileProvider).value;
    if (currentUserProfile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Your Order"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Product: ${widget.product.productName}"),
            Text("Quantity: $_quantity"),
            Text("Unit Price: ₹${widget.product.price.toStringAsFixed(2)}"),
            Text("Total: ₹${_totalPrice.toStringAsFixed(2)}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Create order with proper UUIDs
    final order = WholesaleRetailOrder(
      orderId: const Uuid().v4(),
      wholesaleShopId: widget.product.shopId, // must be UUID
      retailSellerId: currentUserProfile.uid, // UUID from profile
      items: [
        {'productId': widget.product.productId, 'quantity': _quantity},
      ],
      totalAmount: _totalPrice,
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await ref
        .read(createWholesaleRetailOrderProvider)
        .call(order);

    result.match(
      (error) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $error'))),
      (order) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order placed! ID: ${order.orderId}')),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Place Order", style: text.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.product.productName,
                style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Divider(color: colors.outline.withOpacity(0.3)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    context,
                    "Min Order: ${widget.product.minOrderQuantity}",
                    Icons.shopping_basket_outlined,
                  ),
                  _buildInfoChip(
                    context,
                    "In Stock: ${widget.product.stock}",
                    Icons.inventory_2_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                    icon: Icon(
                      Icons.remove,
                      color: _isAtMin
                          ? colors.onSurface.withOpacity(0.4)
                          : colors.onSurface,
                    ),
                    onPressed: _decrement,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: _quantityController,
                        textAlign: TextAlign.center,
                        style: text.displaySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          contentPadding: EdgeInsets.all(4),
                          isDense: true,
                        ),
                        onChanged: _onQuantityChanged,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter quantity';
                          }
                          final num = int.tryParse(value);
                          if (num == null) return 'Invalid';
                          if (num < widget.product.minOrderQuantity) {
                            return 'Min: ${widget.product.minOrderQuantity}';
                          }
                          if (num > widget.product.stock) {
                            return 'Stock: ${widget.product.stock}';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                    icon: Icon(
                      Icons.add,
                      color: _isAtMax
                          ? colors.onSurface.withOpacity(0.4)
                          : colors.onSurface,
                    ),
                    onPressed: _increment,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Price", style: text.bodyMedium),
                      Text(
                        "₹${_totalPrice.toStringAsFixed(2)}",
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _onContinue,
                    child: const Text("Continue"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, IconData icon) {
    final colors = context.colors;
    final text = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(label, style: text.bodyMedium),
        ],
      ),
    );
  }
}
