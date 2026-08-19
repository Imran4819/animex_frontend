import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_fields.dart';
import '../../widgets/app_overlays.dart';
import '../../widgets/standard_page_scaffold.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  // ── Add form controllers ──────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _formSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchCategories());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final cats = await api.getCategories();
      if (mounted) setState(() { _categories = cats; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Failed to load categories: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
      }
    }
  }

  Future<void> _createCategory() async {
    final name = _nameCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (name.isEmpty) { _showSnack('Category name is required', isError: true); return; }
    if (code.isEmpty) { _showSnack('Category code is required', isError: true); return; }

    setState(() => _formSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      final created = await api.createCategory(name: name, code: code, description: desc);
      if (mounted) {
        setState(() {
          _categories.insert(0, created);
          _formSaving = false;
          _nameCtrl.clear();
          _codeCtrl.clear();
          _descCtrl.clear();
        });
        _showSnack('Category "$name" created!');
        Navigator.of(context).pop(); // close bottom sheet
      }
    } catch (e) {
      if (mounted) {
        setState(() => _formSaving = false);
        _showSnack('Failed: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
      }
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> cat) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Category',
      message: 'Remove "${cat['category_name']}"? Products in this category may be affected.',
      confirmLabel: 'Delete',
    );
    if (ok != true) return;

    try {
      await ref.read(apiServiceProvider).deleteCategory(cat['id'] as String);
      if (mounted) {
        setState(() => _categories.removeWhere((c) => c['id'] == cat['id']));
        _showSnack('Category deleted.');
      }
    } catch (e) {
      if (mounted) _showSnack('Failed: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
    }
  }

  void _showAddSheet() {
    _nameCtrl.clear();
    _codeCtrl.clear();
    _descCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCategorySheet(
        nameCtrl: _nameCtrl,
        codeCtrl: _codeCtrl,
        descCtrl: _descCtrl,
        isSaving: _formSaving,
        onSave: _createCategory,
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
    ));
  }

  List<Map<String, dynamic>> get _visible {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _categories;
    return _categories.where((c) {
      final name = (c['category_name'] as String? ?? '').toLowerCase();
      final code = (c['category_code'] as String? ?? '').toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cats = _visible;
    return StandardPageScaffold(
      title: 'Product Categories',
      drawer: const AppDrawer(),
      bodyPadding: EdgeInsets.zero,
      actions: [
        IconButton(
          onPressed: _showAddSheet,
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Add Category',
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Category'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCategories,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0x1F1A3A6B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.category_rounded, color: AppColors.navy, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Manage Categories',
                                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800)),
                              Text('Organize your products into categories',
                                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SearchField(
                      controller: _searchController,
                      hint: 'Search by name or code…',
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionHeader(
                title: 'Categories',
                subtitle: '${cats.length} found',
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (cats.isEmpty)
                const EmptyState(
                  title: 'No categories yet',
                  message: 'Tap the + button to add your first product category.',
                  icon: Icons.category_rounded,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cats.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final cat = cats[i];
                    final name = cat['category_name'] as String? ?? '—';
                    final code = cat['category_code'] as String? ?? '—';
                    final desc = cat['description'] as String? ?? '';
                    final active = cat['status'] as bool? ?? true;

                    return AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0x1F1A3A6B)
                                  : const Color(0x1A9E9E9E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: active ? AppColors.navy : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(name,
                                          style: GoogleFonts.poppins(
                                              fontSize: 15, fontWeight: FontWeight.w700)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                                            : Colors.grey.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        active ? 'Active' : 'Inactive',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: active ? const Color(0xFF16A34A) : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('Code: $code',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12, color: AppColors.textMuted)),
                                if (desc.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(desc,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => _deleteCategory(cat),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom sheet for adding a category ─────────────────────────────────────
class _AddCategorySheet extends StatefulWidget {
  final TextEditingController nameCtrl;
  final TextEditingController codeCtrl;
  final TextEditingController descCtrl;
  final bool isSaving;
  final VoidCallback onSave;

  const _AddCategorySheet({
    required this.nameCtrl,
    required this.codeCtrl,
    required this.descCtrl,
    required this.isSaving,
    required this.onSave,
  });

  @override
  State<_AddCategorySheet> createState() => AddCategorySheetState();
}

class AddCategorySheetState extends State<_AddCategorySheet> {
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category_rounded, color: AppColors.navy),
              const SizedBox(width: 10),
              Text('New Category',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AppTextField(
            controller: widget.nameCtrl,
            label: 'Category Name *',
            prefixIcon: Icons.label_rounded,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: widget.codeCtrl,
            label: 'Category Code *',
            prefixIcon: Icons.qr_code_rounded,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: widget.descCtrl,
            label: 'Description',
            prefixIcon: Icons.description_rounded,
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
                  label: widget.isSaving ? 'Saving…' : 'Save Category',
                  icon: widget.isSaving ? null : Icons.check_circle_rounded,
                  onPressed: widget.isSaving ? () {} : widget.onSave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
