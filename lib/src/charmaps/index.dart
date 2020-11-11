export 'ruslang_freq_2letters.dart';

import 'dart:convert';

import '8859-5.dart';
import 'CP1251.dart';
import 'CP855.dart';
import 'CP866.dart';
import 'KOI8-R.dart';
import 'MacCyrillic.dart';
import 'class.dart';
import 'ruslang_freq_2letters.dart';

/// `CP855` — кириллическая кодовая страница для MS-DOS и подобных ей операционных систем.
const cp_855 = ByteSymbolCodec(cp855);

/// «Альтернати́вная кодиро́вка» («Альтернативная кодировка ГОСТ»)
const cp_866 = ByteSymbolCodec(cp866);

/// `Windows-1251` — набор символов и кодировка, являющаяся стандартной 8-битной
/// кодировкой для русских версий `Microsoft Windows` до 10-й версии.
const cp_1251 = ByteSymbolCodec(cp1251);

/// Кодировка `MacCyrillic` используется только на компьютерах «Макинтош».
const cp_10007 = ByteSymbolCodec(cp10007);

/// `КОИ-8` (код обмена информацией, 8 бит)
const cp_20866 = ByteSymbolCodec(cp20866);

/// `ISO 8859-5` — 8-битная кодовая страница из семейства кодовых страниц
/// стандарта `ISO-8859` для представления кириллицы.
const cp_28595 = ByteSymbolCodec(cp28595);

/// массив кодировок
const cp_all = [
  cp_855,
  cp_866,
  cp_1251,
  cp_10007,
  cp_20866,
  cp_28595,
];

/// Карта кодировок
final charMapsCodecs = {
  cp_855.name: cp_855,
  cp_866.name: cp_866,
  cp_1251.name: cp_1251,
  cp_10007.name: cp_10007,
  cp_20866.name: cp_20866,
  cp_28595.name: cp_28595,
  utf8.name: utf8,
  ascii.name: ascii,
};

/// Возвращает [Map] с рейтингом подобранных кодировок
Map<String, int> getEncodingsRaiting(List<int> data) {
  if (!data.any((e) => e >= 0x80)) {
    return {
      utf8.name: 800000,
      ascii.name: 1000000,
    };
  }
  final _l = data.length;
  if (_l >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF) {
    return {
      utf8.name: 1000000,
    };
  }
  try {
    utf8.decode(data, allowMalformed: false);
  } catch (e) {
    return Map.fromIterables(cp_all.map((e) => e.name),
        cp_all.map((e) => getRusLangFreq2LettersRaiting(e.decode(data))));
  } finally {
    return {
      utf8.name: 1000000,
    };
  }
}

/// Возвращает имя кодировки с наибольшим рейтингом
String getEncodingNameMustRaited(Map<String, int> map) {
  var _mV = 0;
  var _mK = '';
  map.forEach((key, value) {
    if (value > _mV) {
      _mV = value;
      _mK = key;
    }
  });
  return _mK;
}

/// Возвращает имя кодировки
String getEncodingName(List<int> data) =>
    getEncodingNameMustRaited(getEncodingsRaiting(data));

/// Возвращает кодировку
Encoding getEncodingCodec(List<int> data) =>
    charMapsCodecs[getEncodingName(data)];
