export 'charmaps/ruslang_freq_2letters.dart';

import 'dart:convert';

import 'charmaps/8859-5.dart';
import 'charmaps/CP1251.dart';
import 'charmaps/CP855.dart';
import 'charmaps/CP866.dart';
import 'charmaps/KOI8-R.dart';
import 'charmaps/MacCyrillic.dart';
import 'charmaps/class.dart';

const cp_855 = ByteSymbolCodec(cp855);
const cp_866 = ByteSymbolCodec(cp866);
const cp_1251 = ByteSymbolCodec(cp1251);
const cp_10007 = ByteSymbolCodec(cp10007);
const cp_20866 = ByteSymbolCodec(cp20866);
const cp_28595 = ByteSymbolCodec(cp28595);

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
