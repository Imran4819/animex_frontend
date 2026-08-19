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

class MedicalStoreScreen extends ConsumerStatefulWidget {
  const MedicalStoreScreen({super.key});

  @override
  ConsumerState<MedicalStoreScreen> createState() => _MedicalStoreScreenState();
}

class _MedicalStoreScreenState extends ConsumerState<MedicalStoreScreen> {
  final _searchController = TextEditingController();
  List<MedicalStore> _stores = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStores();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStores() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final api = ref.read(apiServiceProvider);
    try {
      final list = await api.getStores();
      if (mounted) {
        setState(() {
          _stores = list;
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

  Future<void> _deleteStore(MedicalStore store) async {
    final localContext = context;
    final ok = await showConfirmDialog(
      context,
      title: 'Delete store',
      message: 'Remove ${store.name} from the directory?',
      confirmLabel: 'Delete',
    );

    if (ok == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(apiServiceProvider).deleteStore(store.id ?? '');
        if (localContext.mounted) {
          ScaffoldMessenger.of(localContext).showSnackBar(
            SnackBar(
              content: Text('${store.name} deleted successfully.'),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _fetchStores();
      } catch (e) {
        setState(() => _isLoading = false);
        if (localContext.mounted) {
          ScaffoldMessenger.of(localContext).showSnackBar(
            SnackBar(
              content: Text('Failed to delete store: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Theme.of(localContext).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  List<MedicalStore> get _visibleStores {
    final query = _searchController.text.trim().toLowerCase();
    var list = List<MedicalStore>.from(_stores);

    if (query.isNotEmpty) {
      list = list.where((store) {
        return store.name.toLowerCase().contains(query) ||
            store.owner.toLowerCase().contains(query) ||
            store.address.toLowerCase().contains(query) ||
            store.phone.toLowerCase().contains(query);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final stores = _visibleStores;

    return StandardPageScaffold(
      title: 'Medical Stores',
      drawer: const AppDrawer(),
      bodyPadding: EdgeInsets.zero,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.addStore).then((_) => _fetchStores()),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addStore).then((_) => _fetchStores()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Store'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
          child: RefreshIndicator(
            onRefresh: _fetchStores,
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
                              onPressed: _fetchStores,
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
                          'Medical store directory',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Search and manage medical stores in your ANIMEX network.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SearchField(
                          controller: _searchController,
                          hint: 'Search store, owner, phone, or address',
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionHeader(
                    title: 'Stores',
                    subtitle: '${stores.length} records available',
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (stores.isEmpty)
                    const EmptyState(
                      title: 'No stores yet',
                      message: 'Tap + to add your first medical store.',
                      icon: Icons.local_pharmacy_rounded,
                    )
                  else if (Responsive.isCompact(context))
                    Column(
                      children: [
                        for (final store in stores)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StoreCard(
                              store: store,
                              onEdit: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Edit operation is handled in directory mode.')),
                                );
                              },
                              onDelete: () => _deleteStore(store),
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
                      childAspectRatio: 2.2,
                      children: [
                        for (final store in stores)
                          StoreCard(
                            store: store,
                            onEdit: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Edit operation is handled in directory mode.')),
                              );
                            },
                            onDelete: () => _deleteStore(store),
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
