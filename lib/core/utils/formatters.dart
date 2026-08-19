import 'package:intl/intl.dart';

final NumberFormat currencyFormatter = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String formatCurrency(num value) => currencyFormatter.format(value);

String formatDate(DateTime value) => DateFormat('dd MMM yyyy').format(value);

String formatShortDate(DateTime value) => DateFormat('dd MMM').format(value);
