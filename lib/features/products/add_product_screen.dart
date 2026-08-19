import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_fields.dart';
import '../../widgets/standard_page_scaffold.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _nameController = TextEditingController();
  final _mrpController = TextEditingController();
  final _sellingController = TextEditingController();
  final _qtyController = TextEditingController(text: '0');

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  String _unit = 'Ltr';
  bool _isLoading = true;  // page-level: fetching categories
  bool _isSaving = false; // action-level: saving product
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mrpController.dispose();
    _sellingController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    final api = ref.read(apiServiceProvider);
    try {
      final cats = await api.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _selectedCategoryId = cats.isNotEmpty ? cats.first['id'] as String? : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback categories if offline
      final mockCats = [
        {'id': 'calcium', 'category_name': 'Calcium Supplements'},
        {'id': 'minerals', 'category_name': 'Mineral Mixtures'},
        {'id': 'liver', 'category_name': 'Liver Tonics'},
        {'id': 'rumen', 'category_name': 'Rumen & Gut Health'},
        {'id': 'uterine', 'category_name': 'Uterine & Fertility Boosters'},
        {'id': 'herbal', 'category_name': 'Herbal Veterinary Products'},
      ];
      if (mounted) {
        setState(() {
          _categories = mockCats;
          _selectedCategoryId = mockCats.first['id'];
          _isLoading = false;
          _isOffline = true;
        });
      }
    }
  }

  void _onSaveProduct() async {
    final localContext = context;
    final name = _nameController.text.trim();
    final mrpText = _mrpController.text.trim();
    final priceText = _sellingController.text.trim();
    final qtyText = _qtyController.text.trim();

    final qty = int.tryParse(qtyText) ?? 0;

    if (name.isEmpty) {
      _showError('Product Title is required');
      return;
    }
    if (_selectedCategoryId == null) {
      _showError('Product Category is required');
      return;
    }
    final mrp = double.tryParse(mrpText) ?? 0.0;
    final price = double.tryParse(priceText) ?? 0.0;

    if (price <= 0.0) {
      _showError('Price must be greater than zero');
      return;
    }

    if (_isOffline) {
      if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(
            content: Text('Product added in local demo mode.'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(localContext);
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(apiServiceProvider).createProduct(
            categoryId: _selectedCategoryId!,
            title: name,
            unit: _unit,
            mrp: mrp,
            sellingPrice: price,
            quantity: qty,
          );

      if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully to database!'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(localContext);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          SnackBar(
            content: Text('Failed to save product: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Theme.of(localContext).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StandardPageScaffold(
      title: 'Add Product',
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            child: AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New ANIMEX Product',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isOffline
                        ? 'Offline Mode: Catalog changes are local only.'
                        : 'Fill in the product details to add a new catalog item.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _isOffline ? AppColors.orange : AppColors.textMuted,
                      fontWeight: _isOffline ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth > 700;
                        final fieldWidth =
                            wide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

                        Widget field(Widget child) =>
                            SizedBox(width: fieldWidth, child: child);

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            field(
                              AppTextField(
                                controller: _nameController,
                                label: 'Product Title *',
                                prefixIcon: Icons.inventory_2_rounded,
                              ),
                            ),
                            field(
                              DropdownButtonFormField<String>(
                                initialValue: _selectedCategoryId,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  prefixIcon: Icon(Icons.category_rounded),
                                ),
                                items: _categories.map((cat) {
                                  return DropdownMenuItem<String>(
                                    value: cat['id'] as String?,
                                    child: Text(cat['category_name'] as String? ?? 'Category'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedCategoryId = value);
                                  }
                                },
                              ),
                            ),
                            field(
                              DropdownButtonFormField<String>(
                                initialValue: _unit,
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                  prefixIcon: Icon(Icons.straighten_rounded),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Ltr', child: Text('Ltr')),
                                  DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                                  DropdownMenuItem(value: 'Gm', child: Text('Gm')),
                                  DropdownMenuItem(value: 'Tab', child: Text('Tab')),
                                  DropdownMenuItem(value: 'Ml', child: Text('Ml')),
                                  DropdownMenuItem(value: 'Can', child: Text('Can')),
                                  DropdownMenuItem(value: 'Vial', child: Text('Vial')),
                                  DropdownMenuItem(value: 'Box', child: Text('Box')),
                                  DropdownMenuItem(value: 'Pkt', child: Text('Pkt')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _unit = value);
                                  }
                                },
                              ),
                            ),
                            field(
                              AppTextField(
                                controller: _mrpController,
                                label: 'MRP (₹)',
                                prefixIcon: Icons.currency_rupee_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            field(
                              AppTextField(
                                controller: _sellingController,
                                label: 'Price (₹) *',
                                prefixIcon: Icons.sell_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            field(
                              AppTextField(
                                controller: _qtyController,
                                label: 'Stock Quantity *',
                                prefixIcon: Icons.unarchive_rounded,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Cancel',
                          icon: Icons.close_rounded,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: _isSaving ? 'Saving...' : 'Save Product',
                          icon: _isSaving ? null : Icons.check_circle_rounded,
                          onPressed: _isSaving ? () {} : _onSaveProduct,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
