export 'charmaps/ruslang_freq_2letters.dart';

import 'dart:convert';

import 'charmaps/8859-5.dart';
import 'charmaps/CP1251.dart';
import 'charmaps/CP855.dart';
import 'charmaps/CP866.dart';
import 'charmaps/KOI8-R.dart';
import 'charmaps/MacCyrillic.dart';
import 'charmaps/class.dart';
import 'charmaps/ruslang_freq_2letters.dart';

const cp_855 = ByteSymbolCodec(cp855);
const cp_866 = ByteSymbolCodec(cp866);
const cp_1251 = ByteSymbolCodec(cp1251);
const cp_10007 = ByteSymbolCodec(cp10007);
const cp_20866 = ByteSymbolCodec(cp20866);
const cp_28595 = ByteSymbolCodec(cp28595);

const cp_all = [
  cp_855,
  cp_866,
  cp_1251,
  cp_10007,
  cp_20866,
  cp_28595,
];

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
