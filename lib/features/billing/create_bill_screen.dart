import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_fields.dart';
import '../../widgets/standard_page_scaffold.dart';
import '../../widgets/app_buttons.dart';

class CreateBillScreen extends ConsumerStatefulWidget {
  const CreateBillScreen({super.key});

  @override
  ConsumerState<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends ConsumerState<CreateBillScreen> {
  final _searchController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final List<_SelectedLine> _selected = [];
  
  List<MedicalStore> _stores = [];
  List<ProductItem> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedCustomerIndex = -1;
  String _paymentType = 'UPI';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final cats = await api.getCategories();
      final prods = await api.getProducts(cats);
      final stores = await api.getStores();

      if (mounted) {
        setState(() {
          _products = prods;
          _stores = stores;
          if (stores.isNotEmpty) {
            _selectedCustomerIndex = 0;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _submitInvoice() async {
    debugPrint('ANIMEX DEBUG: _submitInvoice called');
    debugPrint('ANIMEX DEBUG: _selectedCustomerIndex = $_selectedCustomerIndex, _stores.length = ${_stores.length}');
    debugPrint('ANIMEX DEBUG: _selected.length = ${_selected.length}');

    if (_selectedCustomerIndex < 0 || _selectedCustomerIndex >= _stores.length) {
      debugPrint('ANIMEX DEBUG: Validation failed - invalid customer selection');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer store first.')),
      );
      return;
    }
    if (_selected.isEmpty) {
      debugPrint('ANIMEX DEBUG: Validation failed - no products selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final store = _stores[_selectedCustomerIndex];
      final api = ref.read(apiServiceProvider);
      
      // Map payment types and received amount
      final receivedAmt = _paymentType == 'Credit' ? 0.0 : _grandTotal;

      final itemsPayload = _selected.map((item) => {
        'product_title': item.product.name,
        'quantity': item.quantity,
        'unit': item.product.unit,
        'mrp': item.product.mrp,
        'selling_price': item.isFree ? 0.0 : item.product.sellingPrice,
        'is_free': item.isFree,
      }).toList();

      debugPrint('ANIMEX DEBUG: Sending createInvoice request. Store ID: ${store.id}, clientID: ${api.clientId}');
      debugPrint('ANIMEX DEBUG: Payload: $itemsPayload');

      final createdInvoice = await api.createInvoice(
        medicalStoreId: store.id ?? '',
        date: DateTime.now(),
        discount: _discount,
        receivedAmount: receivedAmt,
        paymentType: _paymentType,
        notes: 'Invoice generated via ANIMEX mobile app.',
        items: itemsPayload,
      );

      final displayId = createdInvoice.companyInvoiceNumber != null
          ? '#${createdInvoice.companyInvoiceNumber}'
          : createdInvoice.invoiceNumber;

      debugPrint('ANIMEX DEBUG: Invoice created successfully. Invoice: $displayId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice $displayId created successfully!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        context.pop(); // Go back to history/dashboard
      }
    } catch (e, stack) {
      debugPrint('ANIMEX DEBUG: Error generating invoice: $e');
      debugPrint('ANIMEX DEBUG: StackTrace: $stack');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate invoice: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  List<ProductItem> get _visibleProducts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _products;
    return _products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.unit.toLowerCase().contains(query);
    }).toList();
  }

  double get _subtotal => _selected.fold(0, (sum, item) => sum + item.lineTotal);

  double get _discount {
    final parsed = double.tryParse(_discountController.text.trim()) ?? 0;
    return parsed.clamp(0, _subtotal).toDouble();
  }

  double get _taxable => (_subtotal - _discount).clamp(0, _subtotal).toDouble();

  double get _gst => _taxable * 0.05;

  double get _grandTotal => _taxable + _gst;

  void _addProduct(ProductItem product) {
    final index = _selected.indexWhere((item) => item.product.name == product.name);
    setState(() {
      if (index >= 0) {
        _selected[index].quantity += 1;
      } else {
        _selected.add(_SelectedLine(product: product, quantity: 1));
      }
    });
  }

  void _changeQuantity(int index, int delta) {
    setState(() {
      final item = _selected[index];
      item.quantity += delta;
      if (item.quantity <= 0) {
        _selected.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const StandardPageScaffold(
        title: 'Create Bill',
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return StandardPageScaffold(
        title: 'Create Bill',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load bill data: $_errorMessage',
                  style: GoogleFonts.poppins(color: AppColors.red),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final visibleProducts = _visibleProducts;

    return StandardPageScaffold(
      title: 'Create Bill',
      bodyPadding: EdgeInsets.zero,
      actions: [
        IconButton(
          onPressed: () {
            if (_selectedCustomerIndex < 0 || _selectedCustomerIndex >= _stores.length) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a customer store first.')),
              );
              return;
            }
            if (_selected.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please add at least one product.')),
              );
              return;
            }
            
            final store = _stores[_selectedCustomerIndex];
            final draftBill = BillRecord(
              invoiceNumber: 'DRAFT',
              storeName: store.name,
              medicalStoreId: store.id,
              date: DateTime.now(),
              amount: _grandTotal,
              status: BillStatus.pending,
              paymentType: _paymentType,
              discount: _discount,
              notes: 'Draft Preview',
              items: _selected.map((item) => {
                'product_title': item.product.name,
                'quantity': item.quantity,
                'unit': item.product.unit,
                'mrp': item.product.mrp,
                'selling_price': item.isFree ? 0.0 : item.product.sellingPrice,
                'is_free': item.isFree,
              }).toList(),
            );
            context.push(AppRoutes.invoicePreview, extra: draftBill);
          },
          icon: const Icon(Icons.visibility_rounded),
        ),
      ],
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 1020;

                final leftColumn = Column(
                  children: [
                    _CustomerSection(
                      stores: _stores,
                      selectedIndex: _selectedCustomerIndex,
                      onChanged: (value) => setState(() => _selectedCustomerIndex = value),
                    ),
                    const SizedBox(height: 14),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product selection',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Search a product and tap the card to add it to the invoice.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SearchField(
                            controller: _searchController,
                            hint: 'Search products for the invoice',
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 14),
                          if (visibleProducts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'No products found in catalog.',
                                  style: GoogleFonts.poppins(color: AppColors.textMuted),
                                ),
                              ),
                            )
                          else
                            ...visibleProducts.map(
                              (product) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _SelectableProductCard(
                                  product: product,
                                  onAdd: () => _addProduct(product),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Selected products',
                            subtitle: '${_selected.length} line items in the bill',
                          ),
                          const SizedBox(height: 8),
                          if (_selected.isEmpty)
                            const EmptyState(
                              title: 'No products selected',
                              message: 'Search and add products to build the invoice.',
                              icon: Icons.shopping_cart_outlined,
                            )
                          else
                            Column(
                              children: [
                                for (var index = 0; index < _selected.length; index++) ...[
                                  if (index > 0) const Divider(height: 24),
                                  _SelectedItemRow(
                                    item: _selected[index],
                                    onMinus: () => _changeQuantity(index, -1),
                                    onPlus: () => _changeQuantity(index, 1),
                                    onRemove: () => setState(() => _selected.removeAt(index)),
                                    onFreeChanged: (val) => setState(() => _selected[index].isFree = val),
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                );

                final summaryColumn = Column(
                  children: [
                    AppCard(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.orange.withValues(alpha: 0.14),
                          Theme.of(context).colorScheme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice summary',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SummaryRow(label: 'Subtotal', value: formatCurrency(_subtotal)),
                          const SizedBox(height: 10),
                          _SummaryRow(label: 'Discount', value: '- ${formatCurrency(_discount)}'),
                          const SizedBox(height: 10),
                          _SummaryRow(label: 'GST (5%)', value: formatCurrency(_gst)),
                          const Divider(height: 28),
                          _SummaryRow(
                            label: 'Grand Total',
                            value: formatCurrency(_grandTotal),
                            emphasized: true,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _discountController,
                            label: 'Discount Amount',
                            prefixIcon: Icons.discount_rounded,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Payment Type',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final type in const ['Cash', 'UPI', 'Card', 'Credit'])
                                ChoiceChip(
                                  label: Text(type),
                                  selected: _paymentType == type,
                                  onSelected: (_) => setState(() => _paymentType = type),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            label: 'Generate Invoice',
                            icon: Icons.receipt_long_rounded,
                            onPressed: _submitInvoice,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice preview',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.qr_code_2_rounded, size: 44, color: AppColors.orange),
                                const SizedBox(height: 8),
                                Text(
                                  'QR placeholder',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Payment mode: $_paymentType',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SummaryRow(label: 'Taxable', value: formatCurrency(_taxable)),
                          const SizedBox(height: 10),
                          _SummaryRow(label: 'Round off', value: '₹0'),
                          const SizedBox(height: 10),
                          _SummaryRow(label: 'Total', value: formatCurrency(_grandTotal), emphasized: true),
                        ],
                      ),
                    ),
                  ],
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: leftColumn),
                      const SizedBox(width: 14),
                      Expanded(child: summaryColumn),
                    ],
                  );
                }

                return Column(
                  children: [
                    leftColumn,
                    const SizedBox(height: 14),
                    summaryColumn,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({
    required this.stores,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<MedicalStore> stores;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasStores = stores.isNotEmpty;
    final selectedStore = hasStores && selectedIndex >= 0 && selectedIndex < stores.length
        ? stores[selectedIndex]
        : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer selection',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select the customer (Medical Store) who is receiving the bill.',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          if (!hasStores)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No medical stores found. Please register a store first.',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.red, fontWeight: FontWeight.w600),
              ),
            )
          else ...[
            DropdownButtonFormField<int>(
              initialValue: selectedIndex >= 0 ? selectedIndex : null,
              items: [
                for (var index = 0; index < stores.length; index++)
                  DropdownMenuItem(
                    value: index,
                    child: Text(stores[index].name),
                  ),
              ],
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
              decoration: const InputDecoration(
                labelText: 'Customer Store',
                prefixIcon: Icon(Icons.local_pharmacy_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InfoTile(
                    icon: Icons.phone_rounded,
                    title: 'Phone',
                    subtitle: selectedStore?.phone ?? '—',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InfoTile(
                    icon: Icons.location_on_rounded,
                    title: 'Address',
                    subtitle: selectedStore?.address ?? '—',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectableProductCard extends StatelessWidget {
  const _SelectableProductCard({
    required this.product,
    required this.onAdd,
  });

  final ProductItem product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onAdd,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.category} . ${product.unit}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(product.sellingPrice),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tap to add',
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedItemRow extends StatelessWidget {
  const _SelectedItemRow({
    required this.item,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
    required this.onFreeChanged,
  });

  final _SelectedLine item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;
  final ValueChanged<bool> onFreeChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;

        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.isFree
                  ? '₹0 (Free Product)'
                  : '${formatCurrency(item.product.sellingPrice)} per unit',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: item.isFree ? AppColors.orange : AppColors.textMuted,
                fontWeight: item.isFree ? FontWeight.w600 : null,
              ),
            ),
          ],
        );

        final quantityRow = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QtyButton(icon: Icons.remove_rounded, onTap: onMinus),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                item.quantity.toString(),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
            _QtyButton(icon: Icons.add_rounded, onTap: onPlus),
          ],
        );

        final freeToggle = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: item.isFree,
              onChanged: (val) => onFreeChanged(val ?? false),
              activeColor: AppColors.orange,
            ),
            Text(
              'Free Product',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: item.isFree ? AppColors.orange : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        );

        final removeButton = TextButton(
          onPressed: onRemove,
          child: const Text('Remove'),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              details,
              const SizedBox(height: 12),
              Row(
                children: [
                  quantityRow,
                  const Spacer(),
                  freeToggle,
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  removeButton,
                  Text(
                    item.isFree ? 'Free' : formatCurrency(item.lineTotal),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: item.isFree ? AppColors.orange : null,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  details,
                  const SizedBox(height: 6),
                  freeToggle,
                ],
              ),
            ),
            const SizedBox(width: 12),
            quantityRow,
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.isFree ? 'Free' : formatCurrency(item.lineTotal),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    color: item.isFree ? AppColors.orange : null,
                  ),
                ),
                removeButton,
              ],
            ),
          ],
        );
      },
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: emphasized ? 15 : 13,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: emphasized ? 18 : 13,
            fontWeight: FontWeight.w800,
            color: emphasized ? AppColors.orange : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SelectedLine {
  _SelectedLine({
    required this.product,
    required this.quantity,
  });

  final ProductItem product;
  int quantity;
  bool isFree = false;

  double get lineTotal => isFree ? 0.0 : product.sellingPrice * quantity;
}
