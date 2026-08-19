import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/data/app_dummy_data.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_overlays.dart';
import '../../widgets/standard_page_scaffold.dart';

// ── Dashboard summary state ──────────────────────────────────────────────────

class _DashSummary {
  final int productCount;
  final int categoryCount;
  final int storeCount;
  final bool isLoading;
  final bool isError;

  const _DashSummary({
    this.productCount = 0,
    this.categoryCount = 0,
    this.storeCount = 0,
    this.isLoading = true,
    this.isError = false,
  });

  _DashSummary copyWith({
    int? productCount,
    int? categoryCount,
    int? storeCount,
    bool? isLoading,
    bool? isError,
  }) =>
      _DashSummary(
        productCount: productCount ?? this.productCount,
        categoryCount: categoryCount ?? this.categoryCount,
        storeCount: storeCount ?? this.storeCount,
        isLoading: isLoading ?? this.isLoading,
        isError: isError ?? this.isError,
      );
}

// ── Dashboard Screen ─────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  _DashSummary _summary = const _DashSummary();
  List<BillRecord> _recentInvoices = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSummary());
  }

  Future<void> _loadSummary() async {
    setState(() => _summary = const _DashSummary(isLoading: true));
    try {
      final api = ref.read(apiServiceProvider);

      // Fetch all three in parallel
      final results = await Future.wait([
        api.getCategories(),
        api.getProducts([]),
        api.getStores(),
      ]);

      final cats = results[0] as List<Map<String, dynamic>>;
      final prods = results[1] as List<ProductItem>;
      final stores = results[2] as List<MedicalStore>;
      
      // Fetch invoices using stores
      final invoices = await api.getInvoices(stores);

      if (mounted) {
        setState(() {
          _recentInvoices = invoices;
          _summary = _DashSummary(
            categoryCount: cats.length,
            productCount: prods.length,
            storeCount: stores.length,
            isLoading: false,
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _summary = _summary.copyWith(isLoading: false, isError: true));
      }
    }
  }

  Future<void> _downloadAndShareInvoice(String invoiceId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'PDF is downloading, please wait...',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final path = await ref.read(apiServiceProvider).downloadInvoicePdf(invoiceId);
      
      if (mounted) Navigator.pop(context);

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
        await Share.shareXFiles(
          [XFile(path)],
          subject: 'ANIMEX Invoice PDF',
          text: 'Here is your ANIMEX supply invoice.',
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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

  Future<void> _deleteInvoice(String invoiceId) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteInvoice(invoiceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice deleted successfully!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        _loadSummary(); // Reload dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete invoice: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.userName ?? 'Team';
    final isWide = Responsive.isWide(context);
    final contentWidth = Responsive.maxContentWidth(context);

    return StandardPageScaffold(
      title: 'Dashboard',
      drawer: const AppDrawer(),
      bodyPadding: EdgeInsets.zero,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createBill),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Bill'),
      ),
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.settings),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              onPressed: () => context.push(AppRoutes.profile),
              icon: const Icon(Icons.person_rounded),
            ),
          ),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Welcome hero card ─────────────────────────────────
                  AppCard(
                    gradient: AppGradients.brand,
                    borderColor: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.account_balance_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, $userName',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Here\'s a live snapshot of your ANIMEX data.',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(alpha: 0.88),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_summary.isLoading)
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _HeroStat(
                              title: 'Products',
                              value: _summary.isLoading ? '—' : '${_summary.productCount}',
                              subtitle: 'In catalog',
                            ),
                            const SizedBox(width: 12),
                            _HeroStat(
                              title: 'Categories',
                              value: _summary.isLoading ? '—' : '${_summary.categoryCount}',
                              subtitle: 'Product types',
                            ),
                            const SizedBox(width: 12),
                            _HeroStat(
                              title: 'Stores',
                              value: _summary.isLoading ? '—' : '${_summary.storeCount}',
                              subtitle: 'Medical stores',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Live stat cards ───────────────────────────────────
                  SectionHeader(
                    title: 'Live Summary',
                    subtitle: 'Real-time data from your account',
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: Responsive.isWide(context) ? 3 : Responsive.isMedium(context) ? 3 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: Responsive.isCompact(context) ? 1.65 : 1.75,
                    children: [
                      StatCard(
                        title: 'Total Products',
                        value: _summary.isLoading ? '…' : '${_summary.productCount}',
                        icon: Icons.inventory_2_rounded,
                        accentColor: AppColors.navy,
                        subtitle: 'In your catalog',
                      ),
                      StatCard(
                        title: 'Categories',
                        value: _summary.isLoading ? '…' : '${_summary.categoryCount}',
                        icon: Icons.category_rounded,
                        accentColor: AppColors.orange,
                        subtitle: 'Product groups',
                      ),
                      StatCard(
                        title: 'Medical Stores',
                        value: _summary.isLoading ? '…' : '${_summary.storeCount}',
                        icon: Icons.local_pharmacy_rounded,
                        accentColor: AppColors.amber,
                        subtitle: 'Registered stores',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Quick Actions ─────────────────────────────────────
                  SectionHeader(
                    title: 'Quick Actions',
                    subtitle: 'Most used flows in one tap',
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: Responsive.isWide(context)
                        ? 4
                        : Responsive.isMedium(context)
                            ? 4
                            : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: Responsive.isCompact(context) ? 1.15 : 1.25,
                    children: [
                      QuickActionCard(
                        title: 'Create Bill',
                        icon: Icons.receipt_long_rounded,
                        onTap: () => context.push(AppRoutes.createBill),
                      ),
                      QuickActionCard(
                        title: 'Products',
                        icon: Icons.inventory_2_rounded,
                        onTap: () => context.go(AppRoutes.products),
                      ),
                      QuickActionCard(
                        title: 'Categories',
                        icon: Icons.category_rounded,
                        onTap: () => context.go(AppRoutes.categories),
                      ),
                      QuickActionCard(
                        title: 'Medical Stores',
                        icon: Icons.local_pharmacy_rounded,
                        onTap: () => context.go(AppRoutes.stores),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Charts (decorative) ────────────────────────────────
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ChartPanel(
                            title: 'Monthly Revenue Chart',
                            subtitle: 'Revenue trend over the last 8 months',
                            data: revenueChart,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ChartPanel(
                            title: 'Pending Collection Chart',
                            subtitle: 'Outstanding value distribution',
                            data: pendingChart,
                            barColor: AppColors.orange,
                            secondaryColor: AppColors.navySoft,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _ChartPanel(
                          title: 'Monthly Revenue Chart',
                          subtitle: 'Revenue trend over the last 8 months',
                          data: revenueChart,
                        ),
                        const SizedBox(height: 14),
                        _ChartPanel(
                          title: 'Pending Collection Chart',
                          subtitle: 'Outstanding value distribution',
                          data: pendingChart,
                          barColor: AppColors.orange,
                          secondaryColor: AppColors.navySoft,
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // ── Recent Bills ───────────────────────────────────────
                  SectionHeader(
                    title: 'Recent Bills',
                    subtitle: 'Latest generated invoices',
                    actionText: 'View all',
                    onActionTap: () => context.go(AppRoutes.bills),
                  ),
                  if (_recentInvoices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No invoices created yet.',
                          style: GoogleFonts.poppins(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else
                    ..._recentInvoices.take(3).map(
                          (bill) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: BillCard(
                              bill: bill,
                              onView: () => context.push(AppRoutes.invoicePreview, extra: bill),
                              onPrint: () => _downloadAndShareInvoice(bill.id ?? ''),
                              onShare: () => _downloadAndShareInvoice(bill.id ?? ''),
                              onDelete: () => _deleteInvoice(bill.id ?? ''),
                            ),
                          ),
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

// ── _HeroStat ────────────────────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _ChartPanel ───────────────────────────────────────────────────────────────

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.subtitle,
    required this.data,
    this.barColor = AppColors.orange,
    this.secondaryColor = AppColors.navy,
  });

  final String title;
  final String subtitle;
  final List<ChartPoint> data;
  final Color barColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          MiniBarChart(
            data: data,
            barColor: barColor,
            secondaryColor: secondaryColor,
          ),
        ],
      ),
    );
  }
}
