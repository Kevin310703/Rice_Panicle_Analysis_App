import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rice_panicle_analysis_app/controllers/auth_controller.dart';
import 'package:rice_panicle_analysis_app/features/widgets/custom_textfield.dart';
import 'package:rice_panicle_analysis_app/services/vietnam_address_service.dart';
import 'package:rice_panicle_analysis_app/utils/app_text_style.dart';

class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _houseNumberController = TextEditingController();

  late final AuthController _authController;

  final List<String> _genderOptions = ['Female', 'Male', 'Other'];
  List<VietnamProvince> _provinces = [];
  List<VietnamWard> _wards = [];
  VietnamProvince? _selectedProvince;
  VietnamWard? _selectedWard;
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _nameController.text = _authController.userName ?? '';
    _emailController.text = _authController.userEmail ?? '';
    _phoneController.text = _authController.userPhone ?? '';
    _dobController.text =
        _authController.userProfile?.dateOfBirth
            ?.toIso8601String()
            .split('T')
            .first ??
        '';
    _genderController.text = _authController.userProfile?.gender ?? '';
    _houseNumberController.text = '';
    _loadProvinces();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _houseNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final currentText = _dobController.text;
    DateTime? initialDate;
    if (currentText.isNotEmpty) {
      initialDate = DateTime.tryParse(currentText);
    }
    initialDate ??= DateTime.now().subtract(const Duration(days: 365 * 20));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _dobController.text = picked.toIso8601String().split('T').first;
    }
  }

  Future<void> _saveProfile() async {
    final success = await _authController.updatedUserProfile(
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      dateOfBirth: _dobController.text.trim().isEmpty
          ? null
          : _dobController.text.trim(),
      gender: _selectedGender,
      address: _buildAddressString(),
    );

    if (!mounted) return;

    if (success) {
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.back();
    } else {
      Get.snackbar(
        'Error',
        'Failed to update profile. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String? get _selectedGender {
    final value = _genderController.text.trim();
    if (value.isEmpty) return null;
    return value;
  }

  String? _buildAddressString() {
    final segments = [
      _houseNumberController.text.trim().isEmpty
          ? null
          : _houseNumberController.text.trim(),
      _selectedWard?.name,
      _selectedProvince?.name,
    ].whereType<String>().where((element) => element.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    return segments.join(', ');
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces = await VietnamAddressService.fetchProvinces();
      setState(() {
        _provinces = provinces;
      });
      final address = _authController.userProfile?.address ?? '';
      if (address.isNotEmpty) {
        await _restoreAddress(address, provinces);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  Future<void> _restoreAddress(
    String address,
    List<VietnamProvince> provinces,
  ) async {
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.isEmpty) return;

    final provinceName = parts.isNotEmpty ? parts.last : null;
    final wardName = parts.length > 1 ? parts[parts.length - 2] : null;
    final house = parts.length > 2
        ? parts.sublist(0, parts.length - 2).join(', ')
        : null;

    if (house != null) {
      _houseNumberController.text = house;
    }

    final province = provinces.firstWhereOrNull(
      (p) => p.name.toLowerCase() == provinceName?.toLowerCase(),
    );

    if (province != null) {
      setState(() => _selectedProvince = province);
      final wards = await VietnamAddressService.fetchWards(province.code);
      if (!mounted) return;
      setState(() => _wards = wards);

      final ward = wards.firstWhereOrNull(
        (w) => w.name.toLowerCase() == wardName?.toLowerCase(),
      );
      if (ward != null) {
        setState(() => _selectedWard = ward);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildField({required Widget child}) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          buildField(
            child: CustomTextfield(
              label: 'Full Name',
              prefixIcon: Icons.person_outline,
              controller: _nameController,
            ),
          ),
          const SizedBox(height: 16),
          buildField(
            child: CustomTextfield(
              label: 'Email',
              prefixIcon: Icons.email_outlined,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              readOnly: true,
            ),
          ),
          const SizedBox(height: 16),
          buildField(
            child: CustomTextfield(
              label: 'Phone Number',
              prefixIcon: Icons.phone_outlined,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(height: 16),
          buildField(
            child: CustomTextfield(
              label: 'Date of Birth',
              prefixIcon: Icons.calendar_today_outlined,
              controller: _dobController,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),
          ),
          const SizedBox(height: 16),
          buildField(
            child: DropdownButtonFormField<String>(
              value: _genderOptions.contains(_genderController.text)
                  ? _genderController.text
                  : null,
              items: _genderOptions
                  .map(
                    (gender) => DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _genderController.text = value ?? '';
              }),
              decoration: _dropdownDecoration(
                context: context,
                label: 'Gender',
                icon: Icons.wc_outlined,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingAddress)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            )
          else ...[
            buildField(
              child: DropdownButtonFormField<VietnamProvince>(
                value: _selectedProvince,
                items: _provinces
                    .map(
                      (p) => DropdownMenuItem<VietnamProvince>(
                        value: p,
                        child: Text(p.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() {
                    _selectedProvince = value;
                    _selectedWard = null;
                    _wards = [];
                  });
                  final wards = await VietnamAddressService.fetchWards(
                    value.code,
                  );
                  if (!mounted) return;
                  setState(() => _wards = wards);
                },
                decoration: _dropdownDecoration(
                  context: context,
                  label: 'Province/City',
                  icon: Icons.location_city_outlined,
                ),
              ),
            ),
            const SizedBox(height: 16),
            buildField(
              child: DropdownButtonFormField<VietnamWard>(
                value: _selectedWard,
                items: _wards
                    .map(
                      (w) => DropdownMenuItem<VietnamWard>(
                        value: w,
                        child: Text(w.name),
                      ),
                    )
                    .toList(),
                onChanged: _wards.isEmpty
                    ? null
                    : (value) => setState(() {
                        _selectedWard = value;
                      }),
                decoration: _dropdownDecoration(
                  context: context,
                  label: 'Ward/Commune',
                  icon: Icons.location_on_outlined,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          buildField(
            child: CustomTextfield(
              label: 'House / Street Number',
              prefixIcon: Icons.home_outlined,
              controller: _houseNumberController,
              maxLines: 2,
              minLines: 1,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save Changes',
                style: AppTextStyle.withColor(
                  AppTextStyle.buttonMedium,
                  Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration({
    required BuildContext context,
    required String label,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyle.withColor(
        AppTextStyle.bodyMedium,
        isDark ? Colors.grey[400]! : Colors.grey[600]!,
      ),
      prefixIcon: Icon(
        icon,
        color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
    );
  }
}
