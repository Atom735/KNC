import 'package:knc/freq_2letters.dart';

/// Возвращает актуальную кодировку
String convGetMappingMax(final Map<String, int> r) {
  var o = '';
  r.forEach((final k, final v) {
    if (r[o] == null) {
      o = k;
    } else if (r[o] < v) {
      o = k;
    }
  });
  return o;
}

/// Возвращает актуальность той или иной кодировки
Map<String, int> convGetMappingRaitings(
    final Map<String, List<String>> map, final List<int> bytes) {
  final r = <String, int>{};
  map.forEach((k, v) {
    r[k] = 0;
  });
  var byteLast = 0;
  for (final byte in bytes) {
    if (byte >= 0x80 && byteLast >= 0x80) {
      // map.forEach(k,v) {
      //   // r[i] += freq_2letters(map[i][byteLast - 0x80] + map[i][byte - 0x80]);
      // }
      map.forEach((final k, final v) {
        r[k] += freq_2letters(v[byteLast - 0x80] + v[byte - 0x80]);
      });
    }
    byteLast = byte;
  }
  return r;
}

/// Преобразует данные с помощью заданной кодировки
String convDecode(final List<int> bytes, final List<String> charMap) =>
    String.fromCharCodes(
        bytes.map((i) => i >= 0x80 ? charMap[i - 0x80].codeUnitAt(0) : i));
