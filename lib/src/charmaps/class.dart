import 'dart:convert';

import 'dart:typed_data';

class ConstUniSymbolMap {
  /// ID символа по спецификации `Microsoft Code Pages`
  final int id;

  /// Наименование кодировки как в платформе `.NET`
  final String nameDotNet;

  /// Альтернативные названия
  final String addInfo;

  /// Данные отображения символов в Юникод таблицу
  final List<int> data;

  /// Юникод названия символов
  final List<String> symbolNames;

  /// Отображение символов из юникода в байты
  final Map<int, int> map;

  const ConstUniSymbolMap(this.id, this.nameDotNet, this.addInfo, this.data,
      this.map, this.symbolNames);
}

class ByteSymbolCodec extends Encoding {
  final ConstUniSymbolMap mapper;
  const ByteSymbolCodec(this.mapper);

  @override
  String get name => mapper.nameDotNet;

  @override
  Uint8List encode(String source) => encoder.convert(source);

  @override
  String decode(List<int> bytes) => decoder.convert(bytes);

  @override
  ByteSymbolEncoder get encoder => ByteSymbolEncoder(mapper);

  @override
  ByteSymbolDecoder get decoder => ByteSymbolDecoder(mapper);
}

/// Преобразует байты в текстовую строку
class ByteSymbolDecoder extends Converter<List<int>, String> {
  final ConstUniSymbolMap mapper;

  const ByteSymbolDecoder(this.mapper);
  @override
  String convert(List<int> input) => String.fromCharCodes(List<int>.generate(
      input.length,
      (i) => input[i] < 0x80 ? input[i] : mapper.data[input[i] - 0x80],
      growable: false));
}

/// текстовую строку в байты
class ByteSymbolEncoder extends Converter<String, List<int>> {
  final ConstUniSymbolMap mapper;

  const ByteSymbolEncoder(this.mapper);
  @override
  Uint8List convert(String input) => Uint8List.fromList(List<int>.generate(
      input.length,
      (i) => input.codeUnitAt(i) < 0x80
          ? input.codeUnitAt(i)
          : mapper.map[input.codeUnitAt(i)] ?? 0x7f,
      growable: false));
}
