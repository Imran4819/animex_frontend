import 'package:flutter/material.dart';

import '../constants/app_routes.dart';
import '../models/app_models.dart';

const dummyCustomers = [
  Customer(
    name: 'Shree Vet Clinic',
    phone: '+91 98765 43210',
    address: 'C.G. Road, Ahmedabad',
  ),
  Customer(
    name: 'MediPaws Hospital',
    phone: '+91 98123 44556',
    address: 'Ring Road, Surat',
  ),
  Customer(
    name: 'Royal Pet Care',
    phone: '+91 98221 77889',
    address: 'Maninagar, Ahmedabad',
  ),
];

const dummyStores = [
  MedicalStore(
    name: 'Medi Care Pharmacy',
    owner: 'Amit Patel',
    phone: '+91 98765 11223',
    address: 'Prahlad Nagar, Ahmedabad',
    district: 'Ahmedabad',
    gstNumber: '24AAHCM1122K1Z3',
  ),
  MedicalStore(
    name: 'Royal Veterinary Store',
    owner: 'Neha Shah',
    phone: '+91 98980 33445',
    address: 'Adajan, Surat',
    district: 'Surat',
    gstNumber: '24AABCR8899N1Z6',
  ),
  MedicalStore(
    name: 'Animal Health Hub',
    owner: 'Rahul Mehta',
    phone: '+91 99000 77881',
    address: 'Ring Road, Rajkot',
    district: 'Rajkot',
    gstNumber: '24AAXPA5533P1Z2',
  ),
  MedicalStore(
    name: 'Pet Wellness Point',
    owner: 'Priya Joshi',
    phone: '+91 99667 55443',
    address: 'Vastrapur, Ahmedabad',
    district: 'Ahmedabad',
    gstNumber: '24ABCPJ4466D1Z9',
  ),
];

const dummyProducts = [
  ProductItem(
    name: 'Albendazole Suspension',
    category: 'Deworming',
    unit: '100 ml bottle',
    mrp: 1200,
    sellingPrice: 980,
    gst: 5,
    description: 'Broad spectrum veterinary deworming suspension.',
  ),
  ProductItem(
    name: 'Calcium Syrup',
    category: 'Supplements',
    unit: '200 ml bottle',
    mrp: 640,
    sellingPrice: 540,
    gst: 12,
    description: 'Daily mineral support for cattle and pets.',
  ),
  ProductItem(
    name: 'Liv-Guard Injection',
    category: 'Injections',
    unit: '10 ml vial',
    mrp: 310,
    sellingPrice: 265,
    gst: 5,
    description: 'Hepatic care injectable solution.',
  ),
  ProductItem(
    name: 'Oral Electrolyte',
    category: 'Hydration',
    unit: '1 kg pouch',
    mrp: 450,
    sellingPrice: 395,
    gst: 5,
    description: 'Supports recovery during dehydration and stress.',
  ),
  ProductItem(
    name: 'Antiseptic Spray',
    category: 'Skin Care',
    unit: '200 ml spray',
    mrp: 380,
    sellingPrice: 325,
    gst: 12,
    description: 'Topical antiseptic spray for wound care.',
  ),
  ProductItem(
    name: 'Tick & Flea Shampoo',
    category: 'Hygiene',
    unit: '300 ml bottle',
    mrp: 590,
    sellingPrice: 510,
    gst: 18,
    description: 'Premium cleansing and pest-control formula.',
  ),
];

final dummyBills = [
  BillRecord(
    invoiceNumber: 'ANX-2408-1184',
    storeName: 'Medi Care Pharmacy',
    date: DateTime(2026, 8, 14),
    amount: 28450,
    status: BillStatus.paid,
    paymentType: 'UPI',
  ),
  BillRecord(
    invoiceNumber: 'ANX-2408-1183',
    storeName: 'Royal Veterinary Store',
    date: DateTime(2026, 8, 13),
    amount: 16890,
    status: BillStatus.pending,
    paymentType: 'Credit',
  ),
  BillRecord(
    invoiceNumber: 'ANX-2408-1182',
    storeName: 'Animal Health Hub',
    date: DateTime(2026, 8, 11),
    amount: 33210,
    status: BillStatus.partiallyPaid,
    paymentType: 'Cheque',
  ),
  BillRecord(
    invoiceNumber: 'ANX-2408-1181',
    storeName: 'Pet Wellness Point',
    date: DateTime(2026, 8, 10),
    amount: 19760,
    status: BillStatus.paid,
    paymentType: 'Cash',
  ),
];

const revenueChart = [
  ChartPoint(label: 'Jan', value: 18),
  ChartPoint(label: 'Feb', value: 26),
  ChartPoint(label: 'Mar', value: 20),
  ChartPoint(label: 'Apr', value: 32),
  ChartPoint(label: 'May', value: 28),
  ChartPoint(label: 'Jun', value: 44),
  ChartPoint(label: 'Jul', value: 39),
  ChartPoint(label: 'Aug', value: 52),
];

const pendingChart = [
  ChartPoint(label: 'Ahmedabad', value: 36),
  ChartPoint(label: 'Surat', value: 24),
  ChartPoint(label: 'Rajkot', value: 18),
  ChartPoint(label: 'Vadodara', value: 12),
];

const quickActions = [
  QuickActionModel(
    title: 'Create Bill',
    icon: Icons.receipt_long_rounded,
    route: AppRoutes.createBill,
  ),
  QuickActionModel(
    title: 'Products',
    icon: Icons.inventory_2_rounded,
    route: AppRoutes.products,
  ),
  QuickActionModel(
    title: 'Medical Stores',
    icon: Icons.local_pharmacy_rounded,
    route: AppRoutes.stores,
  ),
  QuickActionModel(
    title: 'Bill History',
    icon: Icons.history_rounded,
    route: AppRoutes.bills,
  ),
];
