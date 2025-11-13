import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/common/models/product_categories/product_categories.dart';
import 'package:locally/common/providers/product_service_providers.dart';
import 'package:locally/common/models/products/wholesale/wholesale_product_model.dart';
import 'package:locally/common/services/file_picker/file_picker_service.dart';
import 'package:locally/features/wholesale_seller/create_product/widgets/image_picker_grid.dart';
import 'package:locally/features/wholesale_seller/wholesale_nav_page.dart';

class EditProduct extends ConsumerStatefulWidget {
  final String productId;
  const EditProduct({super.key, required this.productId});

  @override
  ConsumerState<EditProduct> createState() => _EditProductState();
}

class _EditProductState extends ConsumerState<EditProduct> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController stockCtrl;
  late TextEditingController moqCtrl;
  late double latitude;
  late double longitude;

  final FilePickerService _filePicker = FilePickerService();

  List<File> _newImages = [];
  List<String> _existingImages = [];
  bool _isSaving = false;
  bool _initialized = false;

  ProductCategories? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;

    final productAsync = ref.watch(
      wholesaleProductByIdProvider(widget.productId),
    );

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Edit Product"),
      ),
      body: productAsync.when(
        data: (product) {
          if (product == null) {
            return const Center(child: Text("Product not found."));
          }

          if (!_initialized) {
            nameCtrl = TextEditingController(text: product.productName);
            descCtrl = TextEditingController(text: product.description);
            priceCtrl = TextEditingController(
              text: product.price.toStringAsFixed(2),
            );
            stockCtrl = TextEditingController(text: product.stock.toString());
            moqCtrl = TextEditingController(
              text: product.minOrderQuantity.toString(),
            );
            latitude = product.latitude;
            longitude = product.longitude;
            _existingImages = List.from(product.imageUrls);

            // 🧭 Match category from product string
            _selectedCategory = ProductCategories.values.firstWhere(
              (c) => c.name.toLowerCase() == product.category.toLowerCase(),
              orElse: () => ProductCategories.other,
            );

            _initialized = true;
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 📸 Image Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text("Product Images", style: text.titleMedium),
                        const SizedBox(height: 8),

                        if (_existingImages.isNotEmpty)
                          SizedBox(
                            height: 150,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: _existingImages.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final url = entry.value;
                                return Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        image: DecorationImage(
                                          image: NetworkImage(url),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _existingImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),

                        const SizedBox(height: 8),
                        ImagePickerGrid(
                          pickedImages: _newImages,
                          onPickImages: _pickImages,
                          onRemoveImage: (index) {
                            setState(() => _newImages.removeAt(index));
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 🧾 Editable fields
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.surfaceDim,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField("Product Name", nameCtrl, text, colors),
                        const SizedBox(height: 12),

                        /// 🧭 Category dropdown
                        Text(
                          "Category",
                          style: text.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<ProductCategories>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: colors.outline.withOpacity(0.2),
                              ),
                            ),
                          ),
                          items: ProductCategories.values
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(categoryDisplayName(c)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedCategory = value);
                          },
                          validator: (value) =>
                              value == null ? "Please select a category" : null,
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                "Price",
                                priceCtrl,
                                text,
                                colors,
                                keyboard: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                "Min Order",
                                moqCtrl,
                                text,
                                colors,
                                keyboard: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          "Stock",
                          stockCtrl,
                          text,
                          colors,
                          keyboard: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        _buildField(
                          "Description",
                          descCtrl,
                          text,
                          colors,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 24),

                        /// 💾 Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                              _isSaving ? "Saving..." : "Save Changes",
                            ),
                            onPressed: _isSaving
                                ? null
                                : () => _saveProduct(context, product),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete_rounded),
                            label: const Text("Delete Product"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isSaving
                                ? null
                                : () => _deleteProduct(context, product),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => Center(child: Text("Error: $error")),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    TextTheme text,
    ColorScheme colors, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.surface,
            hintText: "Enter $label",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.outline.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.outline.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final files = await _filePicker.pickImages();
      setState(() => _newImages.addAll(files));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _saveProduct(
    BuildContext context,
    WholesaleProduct original,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category")),
      );
      return;
    }

    setState(() => _isSaving = true);
    final productService = ref.read(wholesaleProductServiceProvider);
    final imageService = ref.read(supabaseImageServiceProvider);

    try {
      final uploadedUrls = <String>[];
      for (final file in _newImages) {
        final url = await imageService.uploadImage(file, widget.productId);
        uploadedUrls.add(url);
      }

      final removedImages = original.imageUrls
          .where((url) => !_existingImages.contains(url))
          .toList();

      for (final url in removedImages) {
        try {
          await imageService.deleteImage(url);
        } catch (_) {
          // Ignore "not found" or invalid URLs
        }
      }

      final allImageUrls = [..._existingImages, ...uploadedUrls];

      final updated = original.copyWith(
        productName: nameCtrl.text.trim(),
        description: descCtrl.text.trim(),
        category: categoryDisplayName(_selectedCategory!), // ✅ fixed
        price: double.tryParse(priceCtrl.text) ?? original.price,
        stock: int.tryParse(stockCtrl.text) ?? original.stock,
        minOrderQuantity:
            int.tryParse(moqCtrl.text) ?? original.minOrderQuantity,
        latitude: latitude,
        longitude: longitude,
        imageUrls: allImageUrls,
      );

      await productService.updateProduct(updated);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product updated successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update product: $e")),
      );
    }
  }

  Future<void> _deleteProduct(
    BuildContext context,
    WholesaleProduct product,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text(
          "Are you sure you want to delete this product? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    final productService = ref.read(wholesaleProductServiceProvider);

    try {
      await productService.deleteProduct(product.productId);
      ref.invalidate(userWholesaleProductsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product deleted successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WholesaleNavPage(
            initialIndex: 1,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete product: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
