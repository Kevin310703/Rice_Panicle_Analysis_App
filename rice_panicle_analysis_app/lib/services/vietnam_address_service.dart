import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class VietnamProvince {
  final String code;
  final String name;

  VietnamProvince({required this.code, required this.name});

  factory VietnamProvince.fromJson(Map<String, dynamic> json) => VietnamProvince(
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

class VietnamWard {
  final String code;
  final String name;
  final String provinceCode;

  VietnamWard({
    required this.code,
    required this.name,
    required this.provinceCode,
  });

  factory VietnamWard.fromJson(Map<String, dynamic> json) => VietnamWard(
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        provinceCode: json['provinceCode'] as String? ?? '',
      );
}

class VietnamAddressService {
  static List<VietnamProvince>? _cachedProvinces;
  static Map<String, List<VietnamWard>>? _cachedWardsByProvince;

  static Future<List<VietnamProvince>> fetchProvinces() async {
    if (_cachedProvinces != null) return _cachedProvinces!;
    final raw = await rootBundle.loadString('/jsons/vn_provinces.json');
    final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
    final List<dynamic> provinces = data['provinces'] as List<dynamic>? ?? [];
    _cachedProvinces = provinces
        .map((e) => VietnamProvince.fromJson(e as Map<String, dynamic>))
        .where((province) => province.code.isNotEmpty)
        .toList();
    return _cachedProvinces!;
  }

  static Future<List<VietnamWard>> fetchWards(String provinceCode) async {
    _cachedWardsByProvince ??= await _loadAllWards();
    return _cachedWardsByProvince![provinceCode]?.toList() ?? [];
  }

  static Future<Map<String, List<VietnamWard>>> _loadAllWards() async {
    final raw = await rootBundle.loadString('/jsons/vn_wards.json');
    final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
    final List<dynamic> wards = data['wards'] as List<dynamic>? ?? [];

    final map = <String, List<VietnamWard>>{};
    for (final w in wards) {
      final ward = VietnamWard.fromJson(w as Map<String, dynamic>);
      if (ward.code.isEmpty || ward.provinceCode.isEmpty) continue;
      map.putIfAbsent(ward.provinceCode, () => []).add(ward);
    }
    return map;
  }
}
