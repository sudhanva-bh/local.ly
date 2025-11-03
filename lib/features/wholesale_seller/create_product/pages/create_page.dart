import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:locally/common/providers/profile_provider.dart';
import 'package:locally/features/wholesale_seller/products/pages/products_page.dart';
import 'package:locally/features/wholesale_seller/wholesale_nav_page.dart';
import 'package:uuid/uuid.dart';

import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';
import 'package:locally/common/providers/auth_providers.dart';
import 'package:locally/common/providers/product_service_providers.dart';
import 'package:locally/features/wholesale_seller/create_product/widgets/custom_text_field.dart';
import 'package:locally/features/wholesale_seller/create_product/widgets/image_picker_grid.dart';
import 'package:locally/features/wholesale_seller/create_product/widgets/section_card.dart';
import 'package:locally/features/wholesale_seller/create_product/widgets/sell_button.dart';

class CreatePageUI extends ConsumerStatefulWidget {
  const CreatePageUI({super.key});

  @override
  ConsumerState<CreatePageUI> createState() => _CreatePageUIState();
}

class _CreatePageUIState extends ConsumerState<CreatePageUI> {
  final _formKey = GlobalKey<FormState>();

  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _quantityController = TextEditingController();

  final List<File> _pickedImages = [];
  bool _isSubmitting = false;

  ProductCategories? _selectedCategory;

  String? _validateNotEmpty(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "This field cannot be empty";
    }
    return null;
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(result.paths.map((p) => File(p!)).toList());
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  Future<void> _onSellPressed() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one image")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final imageService = ref.read(supabaseImageServiceProvider);
    final productService = ref.read(wholesaleProductServiceProvider);
    final user = ref.read(authStateProvider).value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final productId = const Uuid().v4();

      // ✅ Get the seller profile (with location)
      final seller = ref.read(currentUserProfileProvider).value;
      if (seller == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Seller profile not found")),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // Upload images
      final List<String> uploadedUrls = [];
      for (final image in _pickedImages) {
        final url = await imageService.uploadImage(image, productId);
        uploadedUrls.add(url);
      }

      // ✅ Create product with seller’s latitude & longitude
      final product = WholesaleProduct(
        productId: productId,
        shopId: user.id,
        minOrderQuantity: int.parse(_minOrderController.text),
        stock: int.parse(_quantityController.text),
        productName: _itemController.text.trim(),
        description: _descriptionController.text.trim(),
        category: categoryDisplayName(_selectedCategory!),
        price: double.parse(_priceController.text),
        imageUrls: uploadedUrls,
        latitude: seller.latitude ?? 0.0,
        longitude: seller.longitude ?? 0.0,
        ratings: const [],
      );

      // Save product
      final result = await productService.addProduct(product);

      result.match(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $failure")),
        ),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Product added successfully!")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WholesaleNavPage(initialIndex: 2),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        centerTitle: true,
        elevation: 1,
        title: Text(
          "Create Product",
          style: theme.textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.onSurface,
          ),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isSubmitting,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SectionCard(
                  title: "Item Details",
                  children: [
                    CustomTextField(
                      controller: _itemController,
                      label: "Item Name",
                      icon: Icons.inventory_2,
                      validator: _validateNotEmpty,
                    ),
                    CustomTextField(
                      controller: _priceController,
                      label: "Price",
                      keyboardType: TextInputType.number,
                      icon: Icons.currency_rupee_rounded,
                      validator: _validateNotEmpty,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DropdownButtonFormField<ProductCategories>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.category,
                            color: context.colors.primary,
                          ),
                          labelText: "Category",
                          labelStyle: TextStyle(
                            color: context.colors.onSurface.withAlpha(155),
                          ),
                          filled: true,
                          fillColor: context.colors.surfaceContainer,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: context.colors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: ProductCategories.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(categoryDisplayName(category)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value);
                        },
                        validator: (value) =>
                            value == null ? "Please select a category" : null,
                      ),
                    ),
                  ],
                ),
                SectionCard(
                  title: "Description",
                  children: [
                    CustomTextField(
                      controller: _descriptionController,
                      label: "Item Description",
                      maxLines: 3,
                      icon: Icons.description,
                      validator: _validateNotEmpty,
                    ),
                  ],
                ),
                SectionCard(
                  title: "Quantity",
                  children: [
                    CustomTextField(
                      controller: _minOrderController,
                      label: "Minimum Order Quantity",
                      keyboardType: TextInputType.number,
                      icon: Icons.production_quantity_limits,
                      validator: _validateNotEmpty,
                    ),
                    CustomTextField(
                      controller: _quantityController,
                      label: "Available Stock Quantity",
                      keyboardType: TextInputType.number,
                      icon: Icons.numbers,
                      validator: _validateNotEmpty,
                    ),
                  ],
                ),
                SectionCard(
                  title: "Product Images",
                  children: [
                    ImagePickerGrid(
                      pickedImages: _pickedImages,
                      onPickImages: _pickImages,
                      onRemoveImage: _removeImage,
                    ),
                  ],
                ),
                SellButton(
                  onPressed: _isSubmitting ? null : _onSellPressed,
                ),
                if (_isSubmitting) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
