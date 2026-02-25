/// Helpers for business hours: 24h storage (HH:mm) ↔ 12h AM/PM display.
library;

/// Format 24h time string (e.g. "09:00", "17:30") to 12h AM/PM (e.g. "9:00 AM", "5:30 PM").
/// Returns null if input is null or invalid.
String? format24hToAmPm(String? time24) {
  if (time24 == null || time24.trim().isEmpty) return null;
  final parts = time24.trim().split(RegExp(r'[:\s]'));
  if (parts.isEmpty) return null;
  final hour = int.tryParse(parts[0]);
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  if (hour == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  if (hour == 0) return '12:${minute.toString().padLeft(2, '0')} AM';
  if (hour == 12) return '12:${minute.toString().padLeft(2, '0')} PM';
  if (hour < 12) return '$hour:${minute.toString().padLeft(2, '0')} AM';
  return '${hour - 12}:${minute.toString().padLeft(2, '0')} PM';
}

/// Parse 12h AM/PM string (e.g. "9:00 AM", "5:30 PM") to 24h "HH:mm".
/// Returns null if input is null or invalid.
String? parseAmPmTo24h(String? amPm) {
  if (amPm == null || amPm.trim().isEmpty) return null;
  final s = amPm.trim().toUpperCase();
  final isPm = s.endsWith('PM');
  if (!isPm && !s.endsWith('AM')) return null;
  final timePart = s.replaceFirst(RegExp(r'\s*AM$|\s*PM$'), '').trim();
  final parts = timePart.split(':');
  if (parts.isEmpty) return null;
  var hour = int.tryParse(parts[0]);
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  if (hour == null || hour < 1 || hour > 12 || minute < 0 || minute > 59) return null;
  if (hour == 12) {
    hour = isPm ? 12 : 0;
  } else if (isPm) {
    hour += 12;
  }
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Whether this open/close pair represents "open 24 hours" (00:00–23:59 or 00:00–24:00).
bool is24Hours(String? openTime, String? closeTime) {
  if (openTime == null || closeTime == null) return false;
  final o = openTime.trim();
  final c = closeTime.trim();
  final openMidnight = o == '00:00' || o == '0:00' || o.startsWith('00:00');
  final closeLate = c == '23:59' || c == '24:00' || c == '23:59:59' || c.startsWith('23:59');
  return openMidnight && closeLate;
}
