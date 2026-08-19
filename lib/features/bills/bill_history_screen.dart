import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_overlays.dart';
import '../../widgets/standard_page_scaffold.dart';

enum _BillFilter { all, paid, pending, partiallyPaid, date, store }

extension _BillFilterX on _BillFilter {
  String get label {
    switch (this) {
      case _BillFilter.all:
        return 'All';
      case _BillFilter.paid:
        return 'Paid';
      case _BillFilter.pending:
        return 'Pending';
      case _BillFilter.partiallyPaid:
        return 'Partially Paid';
      case _BillFilter.date:
        return 'Date';
      case _BillFilter.store:
        return 'Medical Store';
    }
  }
}

class BillHistoryScreen extends ConsumerStatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  ConsumerState<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends ConsumerState<BillHistoryScreen> {
  final _searchController = TextEditingController();
  _BillFilter _filter = _BillFilter.all;
  List<BillRecord> _bills = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchInvoices());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final stores = await api.getStores();
      final list = await api.getInvoices(stores);
      if (mounted) {
        setState(() {
          _bills = list;
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

  Future<void> _deleteInvoice(BillRecord bill) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete invoice',
      message: 'Are you sure you want to delete ${bill.invoiceNumber}?',
      confirmLabel: 'Delete',
    );
    if (ok == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(apiServiceProvider).deleteInvoice(bill.id ?? '');
        _fetchInvoices();
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete invoice: ${e.toString().replaceAll('Exception: ', '')}')),
          );
        }
      }
    }
  }

  Future<void> _downloadAndShareInvoice(String invoiceId) async {
    setState(() => _isDownloading = true);
    try {
      final path = await ref.read(apiServiceProvider).downloadInvoicePdf(invoiceId);
      setState(() => _isDownloading = false);
      if (mounted) {
        if (path == 'web_download') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice PDF downloaded successfully!'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
          return;
        }
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            subject: 'ANIMEX Invoice PDF',
            text: 'Here is your ANIMEX supply invoice.',
          ),
        );
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        if (errorMsg.contains('MissingPluginException')) {
          showInfoSheet(
            context,
            title: 'Restart App Required',
            message: 'To print directly on this platform, please restart your running app (stop and run again).\n\nCopy download link:\n${ref.read(apiServiceProvider).getInvoicePdfUrl(invoiceId)}',
            actionLabel: 'Close',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to download invoice: $errorMsg'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    }
  }

  List<BillRecord> get _visibleBills {
    final query = _searchController.text.trim().toLowerCase();
    var bills = List<BillRecord>.from(_bills);

    if (query.isNotEmpty) {
      bills = bills.where((bill) {
        return bill.invoiceNumber.toLowerCase().contains(query) ||
            bill.storeName.toLowerCase().contains(query) ||
            bill.paymentType.toLowerCase().contains(query);
      }).toList();
    }

    switch (_filter) {
      case _BillFilter.paid:
        bills = bills.where((bill) => bill.status == BillStatus.paid).toList();
        break;
      case _BillFilter.pending:
        bills = bills.where((bill) => bill.status == BillStatus.pending).toList();
        break;
      case _BillFilter.partiallyPaid:
        bills = bills.where((bill) => bill.status == BillStatus.partiallyPaid).toList();
        break;
      case _BillFilter.date:
        bills.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _BillFilter.store:
        bills.sort((a, b) => a.storeName.compareTo(b.storeName));
        break;
      case _BillFilter.all:
        bills.sort((a, b) => b.date.compareTo(a.date));
        break;
    }

    return bills;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const StandardPageScaffold(
        title: 'Bill History',
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return StandardPageScaffold(
        title: 'Bill History',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load invoices: $_errorMessage',
                  style: GoogleFonts.poppins(color: AppColors.red),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchInvoices,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final bills = _visibleBills;

    return Stack(
      children: [
        StandardPageScaffold(
          title: 'Bill History',
          drawer: const AppDrawer(),
          bodyPadding: EdgeInsets.zero,
          actions: [
            IconButton(
              onPressed: () => context.push(AppRoutes.createBill).then((_) => _fetchInvoices()),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(AppRoutes.createBill).then((_) => _fetchInvoices()),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Bill'),
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 30,
                          offset: Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice Archive',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Search invoices, sort by date, and filter by payment status.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search invoice, store, or payment type',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final filterType in _BillFilter.values)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(filterType.label),
                                    selected: _filter == filterType,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _filter = filterType);
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Bills',
                            subtitle: '${bills.length} invoices found',
                          ),
                          const SizedBox(height: 12),
                          if (bills.isEmpty)
                            const EmptyState(
                              title: 'No bills found',
                              message: 'Create a new bill or adjust the filter.',
                              icon: Icons.receipt_long_rounded,
                            )
                          else
                            ...bills.map(
                              (bill) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: BillCard(
                                  bill: bill,
                                  onView: () => context.push(AppRoutes.invoicePreview, extra: bill),
                                  onPrint: () => _downloadAndShareInvoice(bill.id ?? ''),
                                  onShare: () => _downloadAndShareInvoice(bill.id ?? ''),
                                  onDelete: () => _deleteInvoice(bill),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isDownloading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange)),
                        const SizedBox(height: 16),
                        Text(
                          'PDF is downloading, please wait...',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
