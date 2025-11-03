import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:locally/common/extensions/content_extensions.dart';
import 'package:locally/features/wholesale_seller/create_product/widgets/custom_text_field.dart';

class CreatePageUI extends StatefulWidget {
  const CreatePageUI({super.key});

  @override
  State<CreatePageUI> createState() => _CreatePageUIState();
}

class _CreatePageUIState extends State<CreatePageUI> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _brandController = TextEditingController();
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _imageController = TextEditingController();
  final _quantityController = TextEditingController();

  final List<File> _pickedImages = [];

  String? _validateNotEmpty(String? value) {
    if (value == null || value.trim().isEmpty)
      return "This field cannot be empty";
    return null;
  }

  String? _validateImageField(String? value) {
    if (_pickedImages.isEmpty) return "Please select at least one image";
    return null;
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(result.paths.map((path) => File(path!)).toList());
      });
    }
  }

  void _removeImage(int index) => setState(() => _pickedImages.removeAt(index));

  void _onSellPressed() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product submitted successfully!")),
      );
      // TODO: Call upload function here
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _itemController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _deliveryController.dispose();
    _minOrderController.dispose();
    _imageController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(
          "Add item",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.colors.onBackground,
          ),
        ),
        backgroundColor: context.colors.background,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle("Enter item details"),
              const SizedBox(height: 16),

              // --- Form fields (rounded white look) ---
              _buildField("Brand :", _brandController),
              _buildField("Item :", _itemController),
              _buildField(
                "Price :",
                _priceController,
                keyboardType: TextInputType.number,
              ),
              _buildField("Category :", _categoryController),
              const SizedBox(height: 12),

              const SectionTitle("Description"),
              const SizedBox(height: 8),
              _buildField(
                "Enter item description",
                _descriptionController,
                maxLines: 3,
              ),

              const SizedBox(height: 16),
              const SectionTitle("Delivery within kms"),
              const SizedBox(height: 8),
              _buildField(
                "kms :",
                _deliveryController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),
              const SectionTitle("Minimum order quantity"),
              const SizedBox(height: 8),
              _buildField(
                "",
                _minOrderController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),
              const SectionTitle("Image of the item"),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(25.0),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: _pickedImages.isEmpty
                      ? const Center(
                          child: Text(
                            "Tap to pick images",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _pickedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.all(8),
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(
                                      image: FileImage(_pickedImages[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black54,
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
                          },
                        ),
                ),
              ),

              const SizedBox(height: 16),
              const SectionTitle("Quantity"),
              const SizedBox(height: 8),
              _buildField(
                "",
                _quantityController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),
              _buildSellButton(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: _validateNotEmpty,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: context.colors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // --- Helper: Orange gradient sell button ---
  Widget _buildSellButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        gradient: LinearGradient(
          colors: [context.colors.primary, context.colors.primaryFixedDim],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: _onSellPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: Text(
          "Sell",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.colors.onPrimary,
          ),
        ),
      ),
    );
  }
}
