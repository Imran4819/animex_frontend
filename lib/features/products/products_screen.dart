import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_fields.dart';
import '../../widgets/app_overlays.dart';
import '../../widgets/standard_page_scaffold.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<ProductItem> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final api = ref.read(apiServiceProvider);
    try {
      // Fetch categories then products
      final cats = await api.getCategories();
      final prods = await api.getProducts(cats);

      if (mounted) {
        setState(() {
          _categories = cats;
          _products = prods;
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

  Future<void> _deleteProduct(ProductItem product) async {
    final localContext = context;
    final ok = await showConfirmDialog(
      context,
      title: 'Delete product',
      message: 'Are you sure you want to remove ${product.name} from the catalog?',
      confirmLabel: 'Delete',
    );

    if (ok == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(apiServiceProvider).deleteProduct(product.id ?? '');
        if (localContext.mounted) {
          ScaffoldMessenger.of(localContext).showSnackBar(
            SnackBar(
              content: Text('${product.name} deleted successfully.'),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _fetchData();
      } catch (e) {
        setState(() => _isLoading = false);
        if (localContext.mounted) {
          ScaffoldMessenger.of(localContext).showSnackBar(
            SnackBar(
              content: Text('Failed to delete product: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Theme.of(localContext).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  List<ProductItem> get _visibleProducts {
    final query = _searchController.text.trim().toLowerCase();
    var products = List<ProductItem>.from(_products);

    if (_selectedCategory != 'All') {
      products = products
          .where((product) => product.category == _selectedCategory)
          .toList();
    }

    if (query.isNotEmpty) {
      products = products.where((product) {
        return product.name.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query) ||
            product.unit.toLowerCase().contains(query);
      }).toList();
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    final products = _visibleProducts;
    final catNames = <String>{'All', ..._categories.map((e) => e['category_name'] as String? ?? '')}.toList();

    return StandardPageScaffold(
      title: 'Products',
      drawer: const AppDrawer(),
      bodyPadding: EdgeInsets.zero,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.addProduct).then((_) => _fetchData()),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
          child: RefreshIndicator(
            onRefresh: _fetchData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.red),
                              ),
                            ),
                            TextButton(
                              onPressed: _fetchData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product catalog',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Search and manage your veterinary product catalog.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SearchField(
                          controller: _searchController,
                          hint: 'Search products, categories, or units',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final category in catNames)
                                if (category.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: ChoiceChip(
                                      label: Text(category),
                                      selected: _selectedCategory == category,
                                      onSelected: (_) =>
                                          setState(() => _selectedCategory = category),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionHeader(
                    title: 'Catalog',
                    subtitle: '${products.length} products available',
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (products.isEmpty)
                    const EmptyState(
                      title: 'No products yet',
                      message: 'Tap + to add your first product.',
                      icon: Icons.inventory_2_rounded,
                    )
                  else if (Responsive.isCompact(context))
                    Column(
                      children: [
                        for (final product in products)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ProductCard(
                              product: product,
                              onEdit: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Edit operation is handled in catalog mode.')),
                                );
                              },
                              onDelete: () => _deleteProduct(product),
                            ),
                          ),
                      ],
                    )
                  else
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.1,
                      children: [
                        for (final product in products)
                          ProductCard(
                            product: product,
                            onEdit: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Edit operation is handled in catalog mode.')),
                              );
                            },
                            onDelete: () => _deleteProduct(product),
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
