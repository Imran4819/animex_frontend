import 'package:flutter/material.dart';

enum BillStatus { paid, pending, partiallyPaid, cancelled }

extension BillStatusX on BillStatus {
  String get label {
    switch (this) {
      case BillStatus.paid:
        return 'PAID';
      case BillStatus.pending:
        return 'PENDING';
      case BillStatus.partiallyPaid:
        return 'PARTIALLY PAID';
      case BillStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color get color {
    switch (this) {
      case BillStatus.paid:
        return const Color(0xFF16A34A);
      case BillStatus.pending:
        return const Color(0xFFF59E0B);
      case BillStatus.partiallyPaid:
        return const Color(0xFF0284C7);
      case BillStatus.cancelled:
        return const Color(0xFF64748B);
    }
  }

  Color get softColor {
    switch (this) {
      case BillStatus.paid:
        return const Color(0xFFDFF7E8);
      case BillStatus.pending:
        return const Color(0xFFFFF1CF);
      case BillStatus.partiallyPaid:
        return const Color(0xFFE0F2FE);
      case BillStatus.cancelled:
        return const Color(0xFFF1F5F9);
    }
  }
}

class ChartPoint {
  const ChartPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class Customer {
  const Customer({
    required this.name,
    required this.phone,
    required this.address,
  });

  final String name;
  final String phone;
  final String address;
}

class MedicalStore {
  const MedicalStore({
    this.id,
    required this.name,
    required this.owner,
    required this.phone,
    required this.address,
    required this.district,
    required this.gstNumber,
  });

  final String? id;
  final String name;
  final String owner;
  final String phone;
  final String address;
  final String district;
  final String gstNumber;
}

class ProductItem {
  const ProductItem({
    this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.mrp,
    required this.sellingPrice,
    required this.gst,
    required this.description,
    this.quantity = 0,
  });

  final String? id;
  final String name;
  final String category;
  final String unit;
  final double mrp;
  final double sellingPrice;
  final double gst;
  final String description;
  final int quantity;
}

class BillRecord {
  const BillRecord({
    this.id,
    required this.invoiceNumber,
    this.companyInvoiceNumber,
    this.globalBillId,
    required this.storeName,
    this.medicalStoreId,
    required this.date,
    required this.amount,
    required this.status,
    required this.paymentType,
    this.discount = 0.0,
    this.receivedAmount = 0.0,
    this.balanceDue = 0.0,
    this.notes = '',
    this.items = const [],
  });

  final String? id;
  final String invoiceNumber;
  final int? companyInvoiceNumber;
  final int? globalBillId;
  final String storeName;
  final String? medicalStoreId;
  final DateTime date;
  final double amount;
  final BillStatus status;
  final String paymentType;
  final double discount;
  final double receivedAmount;
  final double balanceDue;
  final String notes;
  final List<dynamic> items;
}

class InvoiceLineItem {
  const InvoiceLineItem({
    required this.product,
    required this.quantity,
  });

  final ProductItem product;
  final int quantity;

  double get lineTotal => product.sellingPrice * quantity;
}

class QuickActionModel {
  const QuickActionModel({
    required this.title,
    required this.icon,
    required this.route,
  });

  final String title;
  final IconData icon;
  final String route;
}
