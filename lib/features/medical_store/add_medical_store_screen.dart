import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/api_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_fields.dart';
import '../../widgets/standard_page_scaffold.dart';

class AddMedicalStoreScreen extends ConsumerStatefulWidget {
  const AddMedicalStoreScreen({super.key});

  @override
  ConsumerState<AddMedicalStoreScreen> createState() => _AddMedicalStoreScreenState();
}

class _AddMedicalStoreScreenState extends ConsumerState<AddMedicalStoreScreen> {
  final _storeController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  bool _isLoading = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    // Check if the service is currently in offline mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final api = ref.read(apiServiceProvider);
      if (!api.hasValidClient) {
        setState(() => _isOffline = true);
      }
    });
  }

  @override
  void dispose() {
    _storeController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  void _onSaveStore() async {
    final localContext = context;
    final storeName = _storeController.text.trim();
    final contactPerson = _ownerController.text.trim();
    final phone = _phoneController.text.trim();
    final district = _districtController.text.trim();
    final address = _addressController.text.trim();

    if (storeName.isEmpty) {
      _showError('Store Firm Name is required');
      return;
    }
    if (phone.isEmpty) {
      _showError('Phone Number is required');
      return;
    }

    if (_isOffline) {
      if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(
            content: Text('Store added in local demo mode.'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(localContext);
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(apiServiceProvider).createStore(
            firmName: storeName,
            contactPerson: contactPerson,
            phone: phone,
            district: district,
            address: address,
          );

      if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(
            content: Text('Medical store added successfully to database!'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(localContext);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Fall back to offline flow if connection error occurred
        _isOffline = true;
      });
      
      if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          SnackBar(
            content: Text('Failed to save store: ${e.toString().replaceAll('Exception: ', '')}. Switched to local offline mode.'),
            backgroundColor: Theme.of(localContext).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StandardPageScaffold(
      title: 'Add Store',
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            child: AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Medical Store',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isOffline
                        ? 'Offline Mode: Directory changes are local only.'
                        : 'Fill in the medical store details to add a new directory record.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: _isOffline ? AppColors.orange : AppColors.textMuted,
                      fontWeight: _isOffline ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 700;
                      final fieldWidth =
                          wide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

                      Widget field(Widget child) =>
                          SizedBox(width: fieldWidth, child: child);

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          field(
                            AppTextField(
                              controller: _storeController,
                              label: 'Firm Name (Medical Store Name) *',
                              prefixIcon: Icons.local_pharmacy_rounded,
                              readOnly: _isLoading,
                            ),
                          ),
                          field(
                            AppTextField(
                              controller: _ownerController,
                              label: 'Contact Person Name',
                              prefixIcon: Icons.person_outline_rounded,
                              readOnly: _isLoading,
                            ),
                          ),
                          field(
                            AppTextField(
                              controller: _phoneController,
                              label: 'Phone Number *',
                              prefixIcon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                              readOnly: _isLoading,
                            ),
                          ),
                          field(
                            AppTextField(
                              controller: _districtController,
                              label: 'District',
                              prefixIcon: Icons.location_city_rounded,
                              readOnly: _isLoading,
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth,
                            child: AppTextField(
                              controller: _addressController,
                              label: 'Address',
                              prefixIcon: Icons.location_on_outlined,
                              maxLines: 3,
                              readOnly: _isLoading,
                            ),
                          ),
                        ],
                      );
                    },
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
                          label: _isLoading ? 'Saving...' : 'Save Store',
                          icon: _isLoading ? null : Icons.check_circle_rounded,
                          onPressed: _isLoading ? () {} : _onSaveStore,
                        ),
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
