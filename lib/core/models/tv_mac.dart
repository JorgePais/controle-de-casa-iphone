/// Shared validation for Wi-Fi/Ethernet wake addresses.
String? normalizeTvMac(String? value) {
  if (value == null) return null;
  final raw = value.replaceAll(RegExp('[:-]'), '').trim().toUpperCase();
  if (!RegExp(r'^[0-9A-F]{12}$').hasMatch(raw) ||
      raw == '000000000000' ||
      raw == 'FFFFFFFFFFFF') {
    return null;
  }
  if ((int.parse(raw.substring(0, 2), radix: 16) & 1) != 0) return null;
  return List.generate(6, (i) => raw.substring(i * 2, i * 2 + 2)).join(':');
}
