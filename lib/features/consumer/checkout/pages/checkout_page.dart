import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/widgets/location_picker.dart';
import 'package:locally/features/consumer/cart/controllers/cart_controller.dart';
import 'package:locally/common/providers/consumer_profile_provider.dart';
import 'package:locally/features/consumer/checkout/controllers/checkout_controller.dart';
// Ensure you point to the file where you saved the controller above

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  static const double _cardElevation = 2.0;
  static const double _cardBorderRadius = 16.0;

  // --- Text Controllers for Payment Inputs ---
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = ref.read(currentConsumerProfileProvider);
      profileState.whenData((profile) {
        if (profile != null) {
          ref
              .read(checkoutControllerProvider.notifier)
              .initializeLocation(
                profile.address,
                profile.latitude,
                profile.longitude,
              );
        }
      });
    });
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final checkoutState = ref.watch(checkoutControllerProvider);
    final notifier = ref.read(checkoutControllerProvider.notifier);
    final profileAsync = ref.watch(currentConsumerProfileProvider);

    final subtotal = ref.watch(cartTotalProvider);
    final deliveryFee = ref.watch(deliveryFeeProvider);
    final grandTotal = ref.watch(grandTotalProvider);
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN');

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_cardBorderRadius),
    );
    final shadowColor = colors.shadow.withOpacity(0.1);

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: LOCATION ---
            _SectionHeader(
              title: "Delivery Location",
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 12),
            profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text("Error: $err"),
              data: (profile) {
                final lat = checkoutState.deliveryLatitude ?? profile?.latitude;
                final lng =
                    checkoutState.deliveryLongitude ?? profile?.longitude;
                final addr = checkoutState.deliveryAddress ?? profile?.address;

                return LocationPickerField(
                  latitude: lat,
                  longitude: lng,
                  address: addr,
                  onLocationPicked:
                      ({
                        required latitude,
                        required longitude,
                        required address,
                        required updateAddressField,
                      }) async {
                        notifier.setDeliveryLocation(
                          address,
                          latitude,
                          longitude,
                        );
                        if (updateAddressField && profile != null) {
                          // ... (Your Supabase update logic here)
                        }
                      },
                );
              },
            ),

            const SizedBox(height: 24),

            // --- SECTION 2: PAYMENT METHOD ---
            _SectionHeader(
              title: "Payment Method",
              icon: Icons.payment_outlined,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: _cardElevation,
              shadowColor: shadowColor,
              shape: cardShape,
              child: Column(
                children: [
                  _PaymentTile(
                    title: "UPI",
                    subtitle: "Google Pay, PhonePe",
                    icon: Icons.qr_code_scanner,
                    value: "UPI",
                    groupValue: checkoutState.selectedPaymentMethod,
                    onChanged: (val) => notifier.selectPaymentMethod(val!),
                  ),
                  // --- UPI INPUT ---
                  if (checkoutState.selectedPaymentMethod == 'UPI')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: TextField(
                        controller: _upiIdController,
                        decoration: InputDecoration(
                          labelText: "Enter UPI ID",
                          hintText: "example@okaxis",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          prefixIcon: const Icon(
                            Icons.alternate_email,
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                  const Divider(height: 1),

                  _PaymentTile(
                    title: "Card",
                    subtitle: "Credit / Debit Card",
                    icon: Icons.credit_card,
                    value: "CARD",
                    groupValue: checkoutState.selectedPaymentMethod,
                    onChanged: (val) => notifier.selectPaymentMethod(val!),
                  ),
                  // --- CARD INPUT ---
                  if (checkoutState.selectedPaymentMethod == 'CARD')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _cardNumberController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(16),
                            ],
                            decoration: _inputDecoration(
                              "Card Number",
                              Icons.numbers,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _expiryController,
                                  keyboardType: TextInputType.datetime,
                                  decoration: _inputDecoration(
                                    "MM/YY",
                                    Icons.calendar_today,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _cvvController,
                                  obscureText: true,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                  decoration: _inputDecoration(
                                    "CVV",
                                    Icons.lock_outline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const Divider(height: 1),

                  _PaymentTile(
                    title: "Cash on Delivery",
                    subtitle: "Pay when you receive",
                    icon: Icons.money,
                    value: "COD",
                    groupValue: checkoutState.selectedPaymentMethod,
                    onChanged: (val) => notifier.selectPaymentMethod(val!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- SECTION 3: BILL DETAILS ---
            _SectionHeader(
              title: "Bill Details",
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: _cardElevation,
              shape: cardShape,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _BillRow(
                      label: "Item Total",
                      value: currencyFormat.format(subtotal),
                    ),
                    const SizedBox(height: 8),
                    _BillRow(
                      label: "Delivery Fee",
                      value: currencyFormat.format(deliveryFee),
                      highlight: true,
                    ),
                    const Divider(height: 24),
                    _BillRow(
                      label: "To Pay",
                      value: currencyFormat.format(grandTotal),
                      isTotal: true,
                      color: colors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed:
                (checkoutState.isProcessing || !checkoutState.hasValidAddress)
                ? null
                : () => _validateAndPlaceOrder(
                    context,
                    ref,
                    grandTotal,
                    checkoutState.selectedPaymentMethod,
                  ),
            child: checkoutState.isProcessing
                ? CircularProgressIndicator(color: colors.onPrimary)
                : Text(
                    "Place Order · ${currencyFormat.format(grandTotal)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  // --- ORDER PROCESSING LOGIC ---

  Future<void> _validateAndPlaceOrder(
    BuildContext context,
    WidgetRef ref,
    double total,
    String method,
  ) async {
    // 1. Basic Validation
    if (method == 'UPI' && _upiIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid UPI ID")),
      );
      return;
    }
    if (method == 'CARD' &&
        (_cardNumberController.text.length < 16 ||
            _cvvController.text.length < 3)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please check card details")),
      );
      return;
    }

    // 2. Simulate specific Payment Flows
    bool paymentSuccess = false;

    if (method == 'COD') {
      paymentSuccess = true; // Instant success for COD
    } else if (method == 'CARD') {
      // Show OTP Dialog
      final otpResult = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _OtpDialog(),
      );
      paymentSuccess = otpResult ?? false;
    } else if (method == 'UPI') {
      // Show UPI Simulation Dialog
      final upiResult = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _UpiProcessingDialog(amount: total),
      );
      paymentSuccess = upiResult ?? false;
    }

    // 3. Finalize Order if payment was successful
    if (paymentSuccess && context.mounted) {
      final serverSuccess = await ref
          .read(checkoutControllerProvider.notifier)
          .placeOrder();

      if (serverSuccess && context.mounted) {
        _showSuccessDialog(context, ref);
      }
    }
  }

  void _showSuccessDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text("Order Placed!"),
        content: const Text("Your order has been successfully placed. You can view your orders in "),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cartControllerProvider.notifier).clearCart();
              Navigator.pop(c); // Close Dialog
              Navigator.pop(context); // Go back to previous screen (or home)
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }
}

// --- SIMULATION DIALOGS ---

class _OtpDialog extends StatefulWidget {
  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Enter OTP"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("A dummy OTP has been sent to your mobile number."),
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "OTP",
              hintText: "1234",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () => Navigator.pop(context, false), // Cancel
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_otpController.text.isNotEmpty) {
                    setState(() => _isLoading = true);
                    await Future.delayed(
                      const Duration(seconds: 2),
                    ); // Verify simulation
                    if (context.mounted)
                      Navigator.pop(context, true); // Success
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Submit"),
        ),
      ],
    );
  }
}

class _UpiProcessingDialog extends StatefulWidget {
  final double amount;
  const _UpiProcessingDialog({required this.amount});

  @override
  State<_UpiProcessingDialog> createState() => _UpiProcessingDialogState();
}

class _UpiProcessingDialogState extends State<_UpiProcessingDialog> {
  @override
  void initState() {
    super.initState();
    _simulateUpiProcess();
  }

  Future<void> _simulateUpiProcess() async {
    // Simulate user switching to UPI app and approving
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      Navigator.pop(context, true); // Auto-close with Success after 4 seconds
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            "Waiting for confirmation...",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text("Please approve request of ₹${widget.amount} in your UPI app."),
        ],
      ),
    );
  }
}

// --- REUSED WIDGETS (Header, BillRow) ---
// Paste the _SectionHeader, _PaymentTile (modified above), and _BillRow classes here.
// Note: _PaymentTile was modified inside the build method manually for layout simplicity,
// but you can keep the original generic one if you prefer not nesting inputs inside it.

// --- Helper Widgets (Same as before) ---

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 32.0),
        child: Text(subtitle, style: const TextStyle(fontSize: 12)),
      ),
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final bool highlight;
  final Color? color;

  const _BillRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.highlight = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              : textTheme.bodyMedium?.copyWith(
                  color: highlight
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                ),
        ),
        Text(
          value,
          style: isTotal
              ? textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                )
              : textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: highlight
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
        ),
      ],
    );
  }
}
