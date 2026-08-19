import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/app_dummy_data.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_overlays.dart';
import '../../widgets/standard_page_scaffold.dart';


class InvoicePreviewScreen extends ConsumerStatefulWidget {
  const InvoicePreviewScreen({super.key, this.bill});

  final BillRecord? bill;

  @override
  ConsumerState<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends ConsumerState<InvoicePreviewScreen> {
  bool _isDownloading = false;

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  Future<void> _downloadPdf(String invoiceId) async {
    setState(() => _isDownloading = true);

    try {
      final api = ref.read(apiServiceProvider);
      final path = await api.downloadInvoicePdf(invoiceId);
      
      setState(() => _isDownloading = false);

      if (path == 'web_download') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice PDF downloaded successfully!'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
        }
        return;
      }

      await Share.shareXFiles(
        [XFile(path)],
        subject: 'ANIMEX Invoice PDF',
        text: 'Here is your ANIMEX supply invoice.',
      );
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

  @override
  Widget build(BuildContext context) {
    final invoice = widget.bill ?? dummyBills.first;
    final List<InvoiceLineItem> lineItems;

    if (widget.bill != null) {
      lineItems = (widget.bill!.items).map((item) {
        final map = item is Map ? item : {};
        final double mrpVal = _toDouble(map['mrp']);
        final double sellingPriceVal = _toDouble(map['selling_price'] ?? map['price_per_unit']);
        final bool isFreeVal = map['is_free'] == true || sellingPriceVal == 0.0;
        final String nameVal = map['product_title'] ?? map['name'] ?? '';
        final String unitVal = map['unit'] ?? '';
        final int qtyVal = (map['quantity'] ?? 0) as int;

        return InvoiceLineItem(
          product: ProductItem(
            name: isFreeVal ? '$nameVal (Free)' : nameVal,
            category: '',
            unit: unitVal,
            mrp: mrpVal,
            sellingPrice: isFreeVal ? 0.0 : sellingPriceVal,
            gst: 5.0,
            description: '',
            quantity: qtyVal,
          ),
          quantity: qtyVal,
        );
      }).toList();
    } else {
      lineItems = [
        InvoiceLineItem(product: dummyProducts[0], quantity: 2),
        InvoiceLineItem(product: dummyProducts[1], quantity: 1),
        InvoiceLineItem(product: dummyProducts[3], quantity: 3),
      ];
    }

    final double subtotal;
    final double discount;
    final double taxable;
    final double gst;
    final double grandTotal;

    if (widget.bill != null) {
      grandTotal = widget.bill!.amount;
      discount = widget.bill!.discount;
      subtotal = lineItems.fold<double>(0, (sum, item) => sum + item.lineTotal);
      taxable = (subtotal - discount).clamp(0, subtotal).toDouble();
      gst = taxable * 0.05;
    } else {
      subtotal = lineItems.fold<double>(0, (sum, item) => sum + item.lineTotal);
      discount = 450.0;
      taxable = (subtotal - discount).clamp(0, subtotal).toDouble();
      gst = taxable * 0.05;
      grandTotal = taxable + gst;
    }

    final String? invoiceId = invoice.id;
    final VoidCallback onActionPressed = invoiceId == null
        ? () => showInfoSheet(
              context,
              title: 'Action Unavailable',
              message: 'This action is not available for draft/dummy invoices.',
              actionLabel: 'Close',
            )
        : () => _downloadPdf(invoiceId);

    return Stack(
      children: [
        StandardPageScaffold(
          title: 'Invoice Preview',
          bodyPadding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          actions: [
            IconButton(
              onPressed: onActionPressed,
              icon: const Icon(Icons.print_rounded),
            ),
            IconButton(
              onPressed: onActionPressed,
              icon: const Icon(Icons.share_rounded),
            ),
          ],
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppLogo(size: 70, showLabel: false),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ANIMEX Animal Health Care Pvt. Ltd.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Prahlad Nagar, Ahmedabad, Gujarat',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(status: invoice.status),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _MetaPanel(
                                    title: 'Customer',
                                    lines: [
                                      invoice.storeName.isNotEmpty ? invoice.storeName : 'Shree Vet Clinic',
                                      'C.G. Road, Ahmedabad',
                                      '+91 98765 43210',
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MetaPanel(
                                    title: 'Invoice Details',
                                    lines: [
                                      invoice.invoiceNumber,
                                      formatDate(invoice.date),
                                      'Payment: ${invoice.paymentType}',
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 760),
                                  child: Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(3.2),
                                      1: FlexColumnWidth(1),
                                      2: FlexColumnWidth(1.2),
                                      3: FlexColumnWidth(1.2),
                                    },
                                    children: [
                                      TableRow(
                                        decoration: BoxDecoration(
                                          color: AppColors.navy.withValues(alpha: 0.06),
                                        ),
                                        children: const [
                                          _TableCell(label: 'Product'),
                                          _TableCell(label: 'Qty'),
                                          _TableCell(label: 'Rate'),
                                          _TableCell(label: 'Amount'),
                                        ],
                                      ),
                                      for (final item in lineItems)
                                        TableRow(
                                          children: [
                                            _TableCell(label: item.product.name),
                                            _TableCell(label: item.quantity.toString()),
                                            _TableCell(
                                              label: (item.product.name.contains('(Free)') || item.product.sellingPrice == 0.0)
                                                  ? 'Free'
                                                  : formatCurrency(item.product.sellingPrice),
                                            ),
                                            _TableCell(
                                              label: (item.product.name.contains('(Free)') || item.product.sellingPrice == 0.0)
                                                  ? 'Free'
                                                  : formatCurrency(item.lineTotal),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 320),
                                child: Column(
                                  children: [
                                    _SummaryLine(label: 'Subtotal', value: formatCurrency(subtotal)),
                                    const SizedBox(height: 8),
                                    _SummaryLine(label: 'Discount', value: '- ${formatCurrency(discount)}'),
                                    const SizedBox(height: 8),
                                    _SummaryLine(label: 'GST (5%)', value: formatCurrency(gst)),
                                    const Divider(height: 28),
                                    _SummaryLine(
                                      label: 'Grand Total',
                                      value: formatCurrency(grandTotal),
                                      emphasize: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AppCard(
                                    backgroundColor: AppColors.background,
                                    borderColor: AppColors.border,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Payment Status',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        StatusBadge(status: invoice.status),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 130,
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.qr_code_2_rounded, size: 44, color: AppColors.orange),
                                        const SizedBox(height: 6),
                                        Text(
                                          'QR placeholder',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 760;
                                final buttons = [
                                  SecondaryButton(
                                    label: 'Print',
                                    icon: Icons.print_rounded,
                                    onPressed: onActionPressed,
                                  ),
                                  SecondaryButton(
                                    label: 'Download PDF',
                                    icon: Icons.picture_as_pdf_rounded,
                                    onPressed: onActionPressed,
                                  ),
                                  PrimaryButton(
                                    label: 'Share',
                                    icon: Icons.share_rounded,
                                    onPressed: onActionPressed,
                                  ),
                                ];

                                if (compact) {
                                  return Column(
                                    children: [
                                      buttons[0],
                                      const SizedBox(height: 12),
                                      buttons[1],
                                      const SizedBox(height: 12),
                                      buttons[2],
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: buttons[0]),
                                    const SizedBox(width: 12),
                                    Expanded(child: buttons[1]),
                                    const SizedBox(width: 12),
                                    Expanded(child: buttons[2]),
                                  ],
                                );
                              },
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

class _MetaPanel extends StatelessWidget {
  const _MetaPanel({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.background,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                line,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: emphasize ? 15 : 13,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: emphasize ? 19 : 13,
            fontWeight: FontWeight.w800,
            color: emphasize ? AppColors.orange : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
