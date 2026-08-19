import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../utils/pdf_helper.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final authState = ref.watch(authProvider);
  final token = authState.token;
  final clientId = authState.clientId;

  final dio = Dio(BaseOptions(
    baseUrl: 'https://animex-pharma-backend.onrender.com',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  ));

  return ApiService(dio, clientId ?? '');
});

class ApiService {
  final Dio _dio;
  final String clientId;

  ApiService(this._dio, this.clientId);

  // Helper to check if client ID is valid
  bool get hasValidClient => clientId.isNotEmpty;

  /// Extracts a List from API responses regardless of wrapping.
  /// Handles: bare List, {"data":[...]}, {"categories":[...]}, etc.
  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is List) return responseData;
    if (responseData is Map) {
      // Try common wrapper keys in priority order
      for (final key in [
        'data',
        'categories',
        'products',
        'stores',
        'items',
        'results',
        'records',
      ]) {
        if (responseData[key] is List) return responseData[key] as List;
      }
      // Last resort: find any List value in the map
      for (final val in responseData.values) {
        if (val is List) return val;
      }
    }
    return [];
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val) ?? 0.0;
    }
    return 0.0;
  }

  // --- PRODUCT CATEGORIES ---

  Future<List<Map<String, dynamic>>> getCategories() async {
    if (!hasValidClient) return [];
    try {
      final response = await _dio.get('/product-category/client/$clientId/product-categories');
      final list = _extractList(response.data);
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Failed to fetch categories.'));
    }
  }

  Future<Map<String, dynamic>> createCategory({
    required String name,
    required String code,
    required String description,
  }) async {
    if (!hasValidClient) throw Exception('No client session active.');
    try {
      final response = await _dio.post(
        '/product-category/client/$clientId/product-categories',
        data: {
          'category_name': name,
          'category_code': code,
          'description': description,
          'status': true,
        },
      );
      final raw = response.data;
      // Unwrap { data: {...} } or { category: {...} } wrapper if present
      if (raw is Map) {
        for (final key in ['data', 'category', 'result']) {
          if (raw[key] is Map) return Map<String, dynamic>.from(raw[key] as Map);
        }
        return Map<String, dynamic>.from(raw);
      }
      return {};
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Failed to create category.'));
    }
  }

  Future<Map<String, dynamic>> updateCategory(String categoryId, String name, bool status) async {
    if (!hasValidClient) throw Exception('No client session active.');
    try {
      final response = await _dio.put(
        '/product-category/client/$clientId/product-categories/$categoryId',
        data: {
          'category_name': name,
          'status': status,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Failed to update category.'));
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    if (!hasValidClient) throw Exception('No client session active.');
    try {
      await _dio.delete('/product-category/client/$clientId/product-categories/$categoryId');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Failed to delete category.'));
    }
  }

  // --- MEDICAL PRODUCTS ---

  Future<List<ProductItem>> getProducts(List<Map<String, dynamic>> categories) async {
    if (!hasValidClient) return [];
    try {
      final response = await _dio.get('/medical-product/client/$clientId/medical-products');
      final rawList = _extractList(response.data);
      final List<ProductItem> list = [];
      for (final item in rawList) {
        final m = item as Map;
        final catId = m['category_id'] as String? ?? '';

        // Map category ID to category name
        String catName = 'Veterinary';
        final matched = categories.firstWhere(
          (c) => c['id'] == catId,
          orElse: () => <String, dynamic>{},
        );
        if (matched.containsKey('category_name')) {
          catName = matched['category_name'] as String;
        }

        list.add(ProductItem(
          id: m['id'] as String?,
          name: m['product_title'] as String? ?? 'Unnamed Product',
          category: catName,
          unit: m['unit'] as String? ?? 'Ltr',
          mrp: _toDouble(m['mrp']),
          sellingPrice: _toDouble(m['selling_price']),
          gst: 0.0,
          description: m['description'] as String? ?? '',
          quantity: m['quantity'] as int? ?? 0,
        ));
      }
      return list;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Failed to fetch products.'));
    }
  }

  Future<ProductItem> createProduct({
    required String categoryId,
    required String title,
    required String unit,
    required double mrp,
    required double sellingPrice,
    required int quantity,
  }) async {
    if (!hasValidClient) throw Exception('No client session active.');
    try {
      final response = await _dio.post(
        '/medical-product/client/$clientId/medical-products',
        data: {
          'category_id': categoryId,
          'product_title': title,
          'unit': unit,
          'mrp': mrp,
          'selling_price': sellingPrice,
          'quantity': quantity,
          'status': true,
        },
      );
      final item = response.data;
      return ProductItem(
        id: item['id'] as String?,
        name: item['product_title'] as String? ?? title,
        category: '',
        unit: item['unit'] as String? ?? unit,
        mrp: _toDouble(item['mrp']),
        sellingPrice: _toDouble(item['selling_price']),
        gst: 0.0,
        description: '',
        quantity: item['quantity'] as int? ?? quantity,
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Failed to create product.'));
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (!hasValidClient) throw Exception('No client session active.');
    try {
      await _dio.delete('/medical-product/client/$clientId/medical-products/$productId');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Failed to delete product.'));
    }
  }

  // --- MEDICAL STORES ---

  Future<List<MedicalStore>> getStores() async {
    if (!hasValidClient) return [];
    try {
      final response = await _dio.get('/medical-store/client/$clientId/medical-stores');
      final rawList = _extractList(response.data);
      return rawList.map<MedicalStore>((item) {
        final m = item as Map;
        return MedicalStore(
          id: m['id'] as String?,
          name: m['firm_name'] as String? ?? 'Unnamed Store',
          owner: m['contact_person_name'] as String? ?? '',
          phone: m['phone_number'] as String? ?? '',
          address: m['address'] as String? ?? '',
          district: m['district'] as String? ?? '',
          gstNumber: '',
        );
      }).toList();
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Failed to fetch medical stores.'));
    }
  }

  Future<MedicalStore> createStore({
    required String firmName,
    required String contactPerson,
    required String phone,
    required String district,
    required String address,
  }) async {
    if (!hasValidClient) throw Exception('No client session active.');
    try {
      final response = await _dio.post(
        '/medical-store/client/$clientId/medical-stores',
        data: {
          'firm_name': firmName,
          'contact_person_name': contactPerson,
          'phone_number': phone,
          'district': district,
          'address': address,
          'status': true,
        },
      );
      final item = response.data;
      return MedicalStore(
        id: item['id'] as String?,
        name: item['firm_name'] as String? ?? firmName,
        owner: item['contact_person_name'] as String? ?? contactPerson,
        phone: item['phone_number'] as String? ?? phone,
        address: item['address'] as String? ?? address,
        district: item['district'] as String? ?? district,
        gstNumber: '',
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Failed to create medical store.'));
    }
  }

  Future<void> deleteStore(String storeId) async {
    if (!hasValidClient) throw Exception('No client session active.');
    try {
      await _dio.delete('/medical-store/client/$clientId/medical-stores/$storeId');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Failed to delete medical store.'));
    }
  }

  // --- INVOICES ---

  BillStatus _parseBillStatus(String? status) {
    if (status == null) return BillStatus.pending;
    switch (status.toLowerCase()) {
      case 'paid':
        return BillStatus.paid;
      case 'partially paid':
      case 'partiallypaid':
        return BillStatus.partiallyPaid;
      case 'cancelled':
        return BillStatus.cancelled;
      default:
        return BillStatus.pending;
    }
  }

  Future<List<BillRecord>> getInvoices(List<MedicalStore> stores) async {
    if (!hasValidClient) return [];
    try {
      final response = await _dio.get('/client/$clientId/invoices');
      final rawList = _extractList(response.data);
      final List<BillRecord> list = [];
      for (final item in rawList) {
        final m = item as Map;
        final storeId = m['medical_store_id'] as String? ?? '';
        
        // Find store name
        String storeName = 'Unknown Store';
        if (m['medical_store'] is Map && m['medical_store']['firm_name'] != null) {
          storeName = m['medical_store']['firm_name'] as String;
        } else {
          final matched = stores.firstWhere(
            (s) => s.id == storeId,
            orElse: () => const MedicalStore(name: '', owner: '', phone: '', address: '', district: '', gstNumber: ''),
          );
          if (matched.name.isNotEmpty) {
            storeName = matched.name;
          }
        }

        list.add(BillRecord(
          id: m['id'] as String?,
          invoiceNumber: m['invoice_number'] as String? ?? '',
          storeName: storeName,
          medicalStoreId: storeId,
          date: m['date'] != null ? DateTime.tryParse(m['date'] as String) ?? DateTime.now() : DateTime.now(),
          amount: _toDouble(m['grand_total']),
          status: _parseBillStatus(m['status'] as String?),
          paymentType: m['payment_type'] as String? ?? 'UPI',
          discount: _toDouble(m['discount']),
          receivedAmount: _toDouble(m['received_amount']),
          balanceDue: _toDouble(m['balance_due']),
          notes: m['notes'] as String? ?? '',
          items: m['items'] is List ? m['items'] as List : [],
        ));
      }
      return list;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Failed to fetch invoices.'));
    }
  }

  Future<BillRecord> createInvoice({
    required String medicalStoreId,
    required DateTime date,
    required double discount,
    required double receivedAmount,
    required String paymentType,
    required String notes,
    required List<Map<String, dynamic>> items,
  }) async {
    if (!hasValidClient) throw Exception('No client session active.');
    try {
      final response = await _dio.post(
        '/client/$clientId/invoices',
        data: {
          'medical_store_id': medicalStoreId,
          'date': date.toIso8601String(),
          'discount': discount,
          'received_amount': receivedAmount,
          'payment_type': paymentType,
          'notes': notes,
          'items': items,
        },
      );
      final m = response.data is Map ? response.data : {};
      final data = m['data'] is Map ? m['data'] as Map : m;
      
      return BillRecord(
        id: data['id'] as String?,
        invoiceNumber: data['invoice_number'] as String? ?? '',
        storeName: '', // Will be matched by callers
        medicalStoreId: medicalStoreId,
        date: data['date'] != null ? DateTime.tryParse(data['date'] as String) ?? date : date,
        amount: _toDouble(data['grand_total']),
        status: _parseBillStatus(data['status'] as String?),
        paymentType: data['payment_type'] as String? ?? paymentType,
        discount: _toDouble(data['discount']),
        receivedAmount: _toDouble(data['received_amount']),
        balanceDue: _toDouble(data['balance_due']),
        notes: data['notes'] as String? ?? notes,
        items: data['items'] is List ? data['items'] as List : [],
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Failed to create invoice.'));
    }
  }

  Future<void> updateInvoice(
    String invoiceId, {
    required double discount,
    required double receivedAmount,
    required String paymentType,
  }) async {
    if (!hasValidClient) throw Exception('No client session active.');
    try {
      await _dio.put(
        '/client/$clientId/invoices/$invoiceId',
        data: {
          'discount': discount,
          'received_amount': receivedAmount,
          'payment_type': paymentType,
        },
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Failed to update invoice.'));
    }
  }

  Future<void> deleteInvoice(String invoiceId) async {
    if (!hasValidClient) throw Exception('No client session active.');
    try {
      await _dio.delete('/client/$clientId/invoices/$invoiceId');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Failed to delete invoice.'));
    }
  }

  String getInvoicePdfUrl(String invoiceId) {
    return '${_dio.options.baseUrl}/client/$clientId/invoices/$invoiceId/pdf';
  }

  String getInvoicePreviewUrl(String invoiceId) {
    return '${_dio.options.baseUrl}/client/$clientId/invoices/$invoiceId/preview';
  }

  Future<String> downloadInvoicePdf(String invoiceId) async {
    if (!hasValidClient) throw Exception('No client session active.');
    try {
      if (kIsWeb) {
        final response = await _dio.get<List<int>>(
          '/client/$clientId/invoices/$invoiceId/pdf',
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null) {
          savePdfWeb(response.data!, invoiceId);
          return 'web_download';
        }
        throw Exception('No data received from backend.');
      } else {
        final tempDir = await getTemporaryDirectory();
        final savePath = '${tempDir.path}/invoice_$invoiceId.pdf';
        await _dio.download(
          '/client/$clientId/invoices/$invoiceId/pdf',
          savePath,
        );
        return savePath;
      }
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Failed to download invoice PDF.'));
    }
  }

  String _getErrorMessage(DioException e, String defaultMessage) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'].toString();
      }
    }
    return defaultMessage;
  }
}
