import 'package:shared_preferences/shared_preferences.dart';
import '../services/commerce_api.dart';
import '../services/local_store.dart';

String normalizePhone(String value) {
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  for (var i = 0; i < 10; i++) {
    value = value.replaceAll(eastern[i], '$i').replaceAll(persian[i], '$i');
  }
  return value.replaceAll(RegExp(r'[\s()\-]'), '');
}

String? validatePhone(String? value) =>
    RegExp(
      r'^(?:07\d{9}|(?:\+964|00964|964)7\d{9})$',
    ).hasMatch(normalizePhone(value ?? ''))
    ? null
    : 'ژمارەی مۆبایلی دروست بنووسە (07xxxxxxxxx)';

class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.phone,
    this.serverId,
  });
  final String id, label, address, phone;
  final int? serverId;
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'address': address,
    'phone': phone,
    'serverId': serverId,
  };
  factory CustomerAddress.fromJson(Map json) => CustomerAddress(
    id: json['id']?.toString() ?? '',
    label: json['label'] as String? ?? '',
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    serverId: (json['serverId'] as num?)?.toInt(),
  );

  factory CustomerAddress.fromSaved(SavedAddress saved) => CustomerAddress(
    id: 'srv-${saved.id}',
    label: saved.label,
    address: saved.address,
    phone: saved.phone,
    serverId: saved.id,
  );
}

/// Soft ink / gold / forest tones for initials avatars (Roni palette).
const kAvatarColors = <int>[
  0xFF17130D, // ink
  0xFF8A6416, // gold deep
  0xFF06724D, // forest
  0xFF3A2D15, // header brown
  0xFFC22136, // sale rose
  0xFF5F6B63, // muted green-grey
];

class CustomerProvider extends LocalStoreNotifier {
  CustomerProvider({CommerceApi? api, SharedPreferences? preferences})
    : _api = api,
      super(preferences, 'boutique.customer.v1') {
    final data = readData();
    if (data is Map) {
      name = data['name'] as String? ?? '';
      phone = data['phone'] as String? ?? '';
      avatarColorIndex = (data['avatarColor'] as num?)?.toInt() ?? 0;
      avatarPersonalized = data['avatarOn'] as bool? ?? false;
      defaultAddressId = data['default'] as String?;
      for (final row in data['addresses'] as List? ?? []) {
        try {
          _addresses.add(CustomerAddress.fromJson(row as Map));
        } catch (_) {
          /* Ignore damaged address. */
        }
      }
    }
  }

  final CommerceApi? _api;
  bool loading = false;
  String? error;
  bool _disposed = false;

  String name = '';
  String phone = '';
  int avatarColorIndex = 0;
  bool avatarPersonalized = false;
  String? defaultAddressId;
  final List<CustomerAddress> _addresses = [];
  List<CustomerAddress> get addresses => List.unmodifiable(_addresses);
  CustomerAddress? get defaultAddress =>
      _addresses.where((a) => a.id == defaultAddressId).firstOrNull ??
      _addresses.firstOrNull;

  int get avatarColor =>
      kAvatarColors[avatarColorIndex.clamp(0, kAvatarColors.length - 1)];

  /// Display phone: account phone, else default address phone.
  String get displayPhone {
    if (phone.trim().isNotEmpty) return phone.trim();
    return defaultAddress?.phone.trim() ?? '';
  }

  /// 0–100 based on name, phone, address, personalized avatar.
  int get profileCompletionPercent {
    var score = 0;
    if (name.trim().isNotEmpty) score += 30;
    if (displayPhone.isNotEmpty) score += 30;
    if (defaultAddress != null) score += 25;
    if (avatarPersonalized) score += 15;
    return score.clamp(0, 100);
  }

  String? get profileCompletionHint {
    final pct = profileCompletionPercent;
    if (pct >= 100) return null;
    if (name.trim().isEmpty) return 'ناوەکەت زیاد بکە تا پڕۆفایلت تەواو بێت';
    if (displayPhone.isEmpty) {
      return 'ژمارەی مۆبایل زیاد بکە — بۆ گەیاندن پێویستە';
    }
    if (defaultAddress == null) return 'ناونیشانی سەرەکی زیاد بکە';
    if (!avatarPersonalized) return 'ڕەنگی وێنەی پڕۆفایل هەڵبژێرە';
    return 'پڕۆفایلت $pct٪ تەواوە';
  }

  void updateName(String value) {
    name = value.trim();
    _save();
  }

  void updatePhone(String value) {
    phone = normalizePhone(value);
    _save();
  }

  void updateAvatar({int? colorIndex, bool? personalized}) {
    if (colorIndex != null) {
      avatarColorIndex = colorIndex.clamp(0, kAvatarColors.length - 1);
    }
    if (personalized != null) avatarPersonalized = personalized;
    _save();
  }

  /// Commits name + avatar together from the edit-profile draft.
  void saveProfile({
    required String newName,
    required int colorIndex,
    required bool personalized,
  }) {
    name = newName.trim();
    avatarColorIndex = colorIndex.clamp(0, kAvatarColors.length - 1);
    avatarPersonalized = personalized;
    _save();
  }

  Future<void> refreshFromApi() async {
    final api = _api;
    if (api == null || api.token == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final remote = await api.addresses();
      if (_disposed) return;
      _addresses
        ..clear()
        ..addAll(remote.map(CustomerAddress.fromSaved));
      final def = remote.where((a) => a.isDefault).firstOrNull;
      defaultAddressId = def != null
          ? 'srv-${def.id}'
          : _addresses.firstOrNull?.id;
      error = null;
      _save();
    } on CommerceException catch (e) {
      error = e.message;
      notifyListeners();
    } catch (_) {
      error = 'نەتوانرا ناونیشانەکان بکرێنەوە';
      notifyListeners();
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> saveAddress(CustomerAddress address) async {
    final api = _api;
    if (api != null && api.token != null) {
      try {
        final saved = address.serverId == null
            ? await api.saveAddress(
                label: address.label,
                address: address.address,
                phone: address.phone,
                isDefault:
                    defaultAddressId == null ||
                    defaultAddressId == address.id,
              )
            : await api.updateAddress(
                id: address.serverId!,
                label: address.label,
                address: address.address,
                phone: address.phone,
                isDefault: defaultAddressId == address.id,
              );
        await refreshFromApi();
        defaultAddressId ??= 'srv-${saved.id}';
        _save();
        return;
      } on CommerceException catch (e) {
        error = e.message;
        notifyListeners();
      }
    }
    final index = _addresses.indexWhere((a) => a.id == address.id);
    if (index < 0) {
      _addresses.add(address);
    } else {
      _addresses[index] = address;
    }
    defaultAddressId ??= address.id;
    _save();
  }

  Future<void> makeDefault(String id) async {
    final match = _addresses.where((a) => a.id == id).firstOrNull;
    if (match == null) return;
    defaultAddressId = id;
    final api = _api;
    if (api != null && api.token != null && match.serverId != null) {
      try {
        await api.updateAddress(
          id: match.serverId!,
          label: match.label,
          address: match.address,
          phone: match.phone,
          isDefault: true,
        );
        await refreshFromApi();
        return;
      } on CommerceException catch (e) {
        error = e.message;
      }
    }
    _save();
  }

  Future<void> removeAddress(String id) async {
    final match = _addresses.where((a) => a.id == id).firstOrNull;
    final api = _api;
    if (api != null &&
        api.token != null &&
        match?.serverId != null) {
      try {
        await api.deleteAddress(match!.serverId!);
      } on CommerceException catch (e) {
        error = e.message;
        notifyListeners();
        return;
      }
    }
    _addresses.removeWhere((a) => a.id == id);
    if (defaultAddressId == id) defaultAddressId = _addresses.firstOrNull?.id;
    _save();
  }

  void clearForGuest() {
    // Keep local cache; server data will replace on next sign-in.
    error = null;
    notifyListeners();
  }

  void _save() {
    saveData({
      'name': name,
      'phone': phone,
      'avatarColor': avatarColorIndex,
      'avatarOn': avatarPersonalized,
      'default': defaultAddressId,
      'addresses': _addresses.map((a) => a.toJson()).toList(),
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
