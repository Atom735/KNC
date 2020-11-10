import 'dart:math';

/// https://www.clicketyclick.dk/databases/xbase/format/dbf.html
/// http://www.dbase.com/Knowledgebase/INT/db7_file_fmt.htm
/// https://www.dbf2002.com/dbf-file-format.html
/// http://www.autopark.ru/ASBProgrammerGuide/DBFSTRUC.HTM
import 'dart:typed_data';

const kDbfSignaturesNames = {
  0x02: r'[FoxBASE]	Таблица без memo-полей',
  0x03:
      r'[dBASE III, dBASE IV, dBASE 5, dBASE 7, FoxPro, FoxBASE+]	Таблица без memo-полей',
  0x04: r'[dBASE 7]	Таблица без memo-полей',
  0x30:
      r'[Visual FoxPro]	Таблица (признак наличия memo-поля .FPT не предусмотрен )',
  0x31: r'[Visual FoxPro]	Таблица с автоинкрементными полями',
  0x43: r'[dBASE IV, dBASE 5]	SQL-таблица dBASE IV без memo-полей',
  0x63: r'[dBASE IV, dBASE 5]	Системная SQL-таблица dBASE IV без memo-полей',
  0x83: r'[dBASE III, FoxBASE+, FoxPro]	Таблица с memo-полями .DBT',
  0x8B: r'[dBASE IV, dBASE 5]	Таблица с memo-полями .DBT формата dBASE IV',
  0x8C: r'[dBASE 7]	Таблица с memo-полями .DBT формата dBASE IV',
  0xCB: r'[dBASE IV, dBASE 5]	SQL-таблица dBASE IV с memo-полями .DBT',
  0xE5: r'[SMT]	Таблица с memo-полями .SMT',
  0xEB:
      r'[dBASE IV, dBASE 5]	Системная SQL-таблица dBASE IV с memo-полями .DBT',
  0xF5: r'[FoxPro]	Таблица с memo-полями .FPT',
  0xFB: r'[FoxBASE]	Таблица с memo-полями .???',
};

const kDbfLanguageDriverIdNames = {
  0x01: r'437: US MS-DOS',
  0x02: r'850: International MS-DOS',
  0x03: r'1252: Windows ANSI Latin I',
  0x04: r'10000: Standard Macintosh',
  0x08: r'865: Danish OEM',
  0x09: r'437: Dutch OEM',
  0x0A: r'850: Dutch OEM*',
  0x0B: r'437: Finnish OEM',
  0x0D: r'437: French OEM',
  0x0E: r'850: French OEM*',
  0x0F: r'437: German OEM',
  0x10: r'850: German OEM*',
  0x11: r'437: Italian OEM',
  0x12: r'850: Italian OEM*',
  0x13: r'932: Japanese Shift-JIS',
  0x14: r'850: Spanish OEM*',
  0x15: r'437: Swedish OEM',
  0x16: r'850: Swedish OEM*',
  0x17: r'865: Norwegian OEM',
  0x18: r'437: Spanish OEM',
  0x19: r'437: English OEM (Great Britain)',
  0x1A: r'850: English OEM (Great Britain)*',
  0x1B: r'437: English OEM (US)',
  0x1C: r'863: French OEM (Canada)',
  0x1D: r'850: French OEM*',
  0x1F: r'852: Czech OEM',
  0x22: r'852: Hungarian OEM',
  0x23: r'852: Polish OEM',
  0x24: r'860: Portuguese OEM',
  0x25: r'850: Portuguese OEM*',
  0x26: r'866: Russian OEM',
  0x37: r'850: English OEM (US)*',
  0x40: r'852: Romanian OEM',
  0x4D: r'936: Chinese GBK (PRC)',
  0x4E: r'949: Korean (ANSI/OEM)',
  0x4F: r'950: Chinese Big5 (Taiwan)',
  0x50: r'874: Thai (ANSI/OEM)',
  0x57: r'Current ANSI CP: ANSI',
  0x58: r'1252: Western European ANSI',
  0x59: r'1252: Spanish ANSI',
  0x64: r'852: Eastern European MS-DOS',
  0x65: r'866: Russian MS-DOS',
  0x66: r'865: Nordic MS-DOS',
  0x67: r'861: Icelandic MS-DOS',
  0x68: r'895: Kamenicky (Czech) MS-DOS',
  0x69: r'620: Mazovia (Polish) MS-DOS',
  0x6A: r'737: Greek MS-DOS (437G)',
  0x6B: r'857: Turkish MS-DOS',
  0x6C: r'863: French-Canadian MS-DOS',
  0x78: r'950: Taiwan Big 5',
  0x79: r'949: Hangul (Wansung)',
  0x7A: r'936: PRC GBK',
  0x7B: r'932: Japanese Shift-JIS',
  0x7C: r'874: Thai Windows/MS–DOS',
  0x86: r'737: Greek OEM',
  0x87: r'852: Slovenian OEM',
  0x88: r'857: Turkish OEM',
  0x96: r'10007: Russian Macintosh',
  0x97: r'10029: Eastern European Macintosh',
  0x98: r'10006: Greek Macintosh',
  0xC8: r'1250: Eastern European Windows',
  0xC9: r'1251: Russian Windows',
  0xCA: r'1254: Turkish Windows',
  0xCB: r'1253: Greek Windows',
  0xCC: r'1257: Baltic Windows',
};

const kDbfFieldTypeName = {
  r'B': r'Binary',
  r'C': r'Character',
  r'D': r'Date',
  r'F': r'Float',
  r'G': r'General',
  r'I': r'Integer',
  r'L': r'Logical',
  r'M': r'Memo',
  r'N': r'Numeric',
  r'O': r'Double',
  r'P': r'Picture',
  r'Q': r'Varbinary',
  r'T': r'DateTime',
  r'V': r'Varchar',
  r'W': r'Blob',
  r'Y': r'Currency',
  r'@': r'Timestamp',
  r'+': r'Autoincrement',
};

/// Структура заголовка DBF файла
class Dbf {
  /// Отображение памяти
  final ByteData _bytes;

  /// Получает отладочную информацию
  String get debugString {
    final str = StringBuffer();
    str.writeln('Сигнатура:'.padRight(32) + '($signature) $signatureName');
    str.writeln('Последняя модификация:'.padRight(32) +
        '$lastUpdateDD.$lastUpdateMM.$lastUpdateYY');
    str.writeln('Количество записей:'.padRight(32) + '$numberOfRecords');
    str.writeln('Длина заголовка:'.padRight(32) + '$lengthOfHeader');
    str.writeln('Длина одной записи:'.padRight(32) + '$lengthOfEachRecord');
    str.writeln('Зарезервировано (всегда 0)'.padRight(32) + '$r12');
    str.writeln(
        'Незавершенная транзакция:'.padRight(32) + '$incompleteTransac');
    str.writeln('Флаг шифрования таблицы:'.padRight(32) + '$ecryptionFlag');
    str.writeln('Зарезервированная область:'.padRight(32) + '$r16');
    str.writeln('Зарезервированная область:'.padRight(32) + '$r20');
    str.writeln('Зарезервированная область:'.padRight(32) + '$r24');
    str.writeln('Флаг MDX-файла:'.padRight(32) + '$mdxFlag');
    str.writeln('Кодовая страница:'.padRight(32) +
        '($laguageDriverId) $laguageDriverIdName');
    str.writeln('Зарезервировано (всегда 0):'.padRight(32) + '$r30');
    return str.toString();
  }

  String get debugStringFields {
    final str = StringBuffer();
    str.writeln(''.padRight(64, '-'));
    for (var field in fields) {
      str.write(field.debugString);
      str.writeln(''.padRight(64, '-'));
    }
    return str.toString();
  }

  String get debugStringRecords {
    if (records.isEmpty) {
      return '';
    }
    final str = StringBuffer();
    str.writeln(''.padRight(64, '='));
    str.writeln(records.first.debugString(fields, true));
    for (var record in records) {
      str.writeln(record.debugString(fields));
    }
    str.writeln(''.padRight(64, '='));
    return str.toString();
  }

  String get debugStringFull =>
      debugString + debugStringFields + debugStringRecords;

  /// Поля записи
  final List<DbfField> fields = [];

  final List<DbfRecord> records = [];

  Dbf._(this._bytes);
  Dbf(this._bytes) {
    var offset = 32;
    while (_bytes.getUint8(offset) != 0x0D) {
      fields.add(DbfField(ByteData.sublistView(_bytes, offset, offset + 32)));
      offset += 32;
    }
    final _l = numberOfRecords;
    final _lR = lengthOfEachRecord;
    offset = lengthOfHeader;
    for (var i = 0; i < _l; i++) {
      records
          .add(DbfRecord(ByteData.sublistView(_bytes, offset, offset + _lR)));
      offset += _lR;
    }
  }

  static bool validate(ByteData data) {
    if (data.lengthInBytes <= 32) {
      return false;
    }

    final _head = Dbf._(data);
    if (_head.signatureName == 'UNKNOWN') {
      return false;
    }

    /// Если размеры не соответсуют укзаанным
    if (data.lengthInBytes <
        _head.lengthOfHeader +
            _head.lengthOfEachRecord * _head.numberOfRecords) {
      return false;
    }

    return true;
  }

  /// `0` Сигнатура файла
  /// - `2`	`0x02`	`00000010`	[FoxBASE]	Таблица без memo-полей
  /// - `3`	`0x03`	`00000011`	[dBASE III, dBASE IV, dBASE 5, dBASE 7, FoxPro, FoxBASE+]	Таблица без memo-полей
  /// - `4`	`0x04`	`00000100`	[dBASE 7]	Таблица без memo-полей
  /// - `48`	`0x30`	`00110000`	[Visual FoxPro]	Таблица (признак наличия memo-поля .FPT не предусмотрен )
  /// - `49`	`0x31`	`00110001`	[Visual FoxPro]	Таблица с автоинкрементными полями
  /// - `67`	`0x43`	`01000011`	[dBASE IV, dBASE 5]	SQL-таблица dBASE IV без memo-полей
  /// - `99`	`0x63`	`01100011`	[dBASE IV, dBASE 5]	Системная SQL-таблица dBASE IV без memo-полей
  /// - `131`	`0x83`	`10000011`	[dBASE III, FoxBASE+, FoxPro]	Таблица с memo-полями .DBT
  /// - `139`	`0x8B`	`10001011`	[dBASE IV, dBASE 5]	Таблица с memo-полями .DBT формата dBASE IV
  /// - `140`	`0x8C`	`10001100`	[dBASE 7]	Таблица с memo-полями .DBT формата dBASE IV
  /// - `203`	`0xCB`	`11001011`	[dBASE IV, dBASE 5]	SQL-таблица dBASE IV с memo-полями .DBT
  /// - `229`	`0xE5`	`11100101`	[SMT]	Таблица с memo-полями .SMT
  /// - `235`	`0xEB`	`11101011`	[dBASE IV, dBASE 5]	Системная SQL-таблица dBASE IV с memo-полями .DBT
  /// - `245`	`0xF5`	`11110101`	[FoxPro]	Таблица с memo-полями .FPT
  /// - `251`	`0xFB`	`11111011`	[FoxBASE]	Таблица с memo-полями .???
  int get signature => _bytes.getUint8(0);
  set signature(int i) => _bytes.setUint8(0, i);
  String get signatureName => kDbfSignaturesNames[signature] ?? 'UNKNOWN';

  /// `1` Дата последней модификации Год
  int get lastUpdateYY => _bytes.getUint8(1);
  set lastUpdateYY(int i) => _bytes.setUint8(1, i);

  /// `2` Дата последней модификации Месяц
  int get lastUpdateMM => _bytes.getUint8(2);
  set lastUpdateMM(int i) => _bytes.setUint8(2, i);

  /// `3` Дата последней модификации День
  int get lastUpdateDD => _bytes.getUint8(3);
  set lastUpdateDD(int i) => _bytes.setUint8(3, i);

  /// `4-7` Число записей в базе
  int get numberOfRecords => _bytes.getUint32(4, Endian.little);
  set numberOfRecords(int i) => _bytes.setUint32(4, i, Endian.little);

  /// `8-9` Полная длина заголовка (с дескрипторами полей) или
  /// позиция начала записей
  int get lengthOfHeader => _bytes.getUint16(8, Endian.little);
  set lengthOfHeader(int i) => _bytes.setUint16(8, i, Endian.little);

  /// `10-11` Длина одной записи
  int get lengthOfEachRecord => _bytes.getUint16(10, Endian.little);
  set lengthOfEachRecord(int i) => _bytes.setUint16(10, i, Endian.little);

  /// `12-13` Зарезервировано (всегда 0)
  int get r12 => _bytes.getUint16(12, Endian.little);
  set r12(int i) => _bytes.setUint16(12, i, Endian.little);

  /// `14` Флаг, указывающий на наличие незавершенной транзакции [dBASE IV]
  int get incompleteTransac => _bytes.getUint8(14);
  set incompleteTransac(int i) => _bytes.setUint8(14, i);

  /// `15` Флаг шифрования таблицы [dBASE IV]
  int get ecryptionFlag => _bytes.getUint8(15);
  set ecryptionFlag(int i) => _bytes.setUint8(15, i);

  /// `16-27` Зарезервированная область для многопользовательского использования
  int get r16 => _bytes.getUint32(16, Endian.little);
  set r16(int i) => _bytes.setUint32(16, i, Endian.little);

  /// `16-27` Зарезервированная область для многопользовательского использования
  int get r20 => _bytes.getUint32(20, Endian.little);
  set r20(int i) => _bytes.setUint32(20, i, Endian.little);

  /// `16-27` Зарезервированная область для многопользовательского использования
  int get r24 => _bytes.getUint32(24, Endian.little);
  set r24(int i) => _bytes.setUint32(24, i, Endian.little);

  /// `28` Флаг наличия индексного MDX-файла
  /// - `0x01` file has a structural [.cdx]
  /// - `0x02` file has a [Memo field]
  /// - `0x04` file is a database ([.dbc])
  /// - This byte can contain the sum of any of the above values. For example, the value 0x03 indicates the table has a structural .cdx and a Memo field.
  int get mdxFlag => _bytes.getUint8(28);
  set mdxFlag(int i) => _bytes.setUint8(28, i);

  /// `29` Идентификатор кодовой страницы файла ([dBASE IV, Visual FoxPro, XBase])
  /// - `1`	`0x01`	`437`	US MS-DOS
  /// - `2`	`0x02`	`850`	International MS-DOS
  /// - `3`	`0x03`	`1252`	Windows ANSI Latin I
  /// - `4`	`0x04`	`10000`	Standard Macintosh
  /// - `8`	`0x08`	`865`	Danish OEM
  /// - `9`	`0x09`	`437`	Dutch OEM
  /// - `10`	`0x0A`	`850`	Dutch OEM*
  /// - `11`	`0x0B`	`437`	Finnish OEM
  /// - `13`	`0x0D`	`437`	French OEM
  /// - `14`	`0x0E`	`850`	French OEM*
  /// - `15`	`0x0F`	`437`	German OEM
  /// - `16`	`0x10`	`850`	German OEM*
  /// - `17`	`0x11`	`437`	Italian OEM
  /// - `18`	`0x12`	`850`	Italian OEM*
  /// - `19`	`0x13`	`932`	Japanese Shift-JIS
  /// - `20`	`0x14`	`850`	Spanish OEM*
  /// - `21`	`0x15`	`437`	Swedish OEM
  /// - `22`	`0x16`	`850`	Swedish OEM*
  /// - `23`	`0x17`	`865`	Norwegian OEM
  /// - `24`	`0x18`	`437`	Spanish OEM
  /// - `25`	`0x19`	`437`	English OEM (Great Britain)
  /// - `26`	`0x1A`	`850`	English OEM (Great Britain)*
  /// - `27`	`0x1B`	`437`	English OEM (US)
  /// - `28`	`0x1C`	`863`	French OEM (Canada)
  /// - `29`	`0x1D`	`850`	French OEM*
  /// - `31`	`0x1F`	`852`	Czech OEM
  /// - `34`	`0x22`	`852`	Hungarian OEM
  /// - `35`	`0x23`	`852`	Polish OEM
  /// - `36`	`0x24`	`860`	Portuguese OEM
  /// - `37`	`0x25`	`850`	Portuguese OEM*
  /// - `38`	`0x26`	`866`	Russian OEM
  /// - `55`	`0x37`	`850`	English OEM (US)*
  /// - `64`	`0x40`	`852`	Romanian OEM
  /// - `77`	`0x4D`	`936`	Chinese GBK (PRC)
  /// - `78`	`0x4E`	`949`	Korean (ANSI/OEM)
  /// - `79`	`0x4F`	`950`	Chinese Big5 (Taiwan)
  /// - `80`	`0x50`	`874`	Thai (ANSI/OEM)
  /// - `87`	`0x57`	`Current ANSI CP`	ANSI
  /// - `88`	`0x58`	`1252`	Western European ANSI
  /// - `89`	`0x59`	`1252`	Spanish ANSI
  /// - `100`	`0x64`	`852`	Eastern European MS-DOS
  /// - `101`	`0x65`	`866`	Russian MS-DOS
  /// - `102`	`0x66`	`865`	Nordic MS-DOS
  /// - `103`	`0x67`	`861`	Icelandic MS-DOS
  /// - `104`	`0x68`	`895`	Kamenicky (Czech) MS-DOS
  /// - `105`	`0x69`	`620`	Mazovia (Polish) MS-DOS
  /// - `106`	`0x6A`	`737`	Greek MS-DOS (437G)
  /// - `107`	`0x6B`	`857`	Turkish MS-DOS
  /// - `108`	`0x6C`	`863`	French-Canadian MS-DOS
  /// - `120`	`0x78`	`950`	Taiwan Big 5
  /// - `121`	`0x79`	`949`	Hangul (Wansung)
  /// - `122`	`0x7A`	`936`	PRC GBK
  /// - `123`	`0x7B`	`932`	Japanese Shift-JIS
  /// - `124`	`0x7C`	`874`	Thai Windows/MS–DOS
  /// - `134`	`0x86`	`737`	Greek OEM
  /// - `135`	`0x87`	`852`	Slovenian OEM
  /// - `136`	`0x88`	`857`	Turkish OEM
  /// - `150`	`0x96`	`10007`	Russian Macintosh
  /// - `151`	`0x97`	`10029`	Eastern European Macintosh
  /// - `152`	`0x98`	`10006`	Greek Macintosh
  /// - `200`	`0xC8`	`1250`	Eastern European Windows
  /// - `201`	`0xC9`	`1251`	Russian Windows
  /// - `202`	`0xCA`	`1254`	Turkish Windows
  /// - `203`	`0xCB`	`1253`	Greek Windows
  /// - `204`	`0xCC`	`1257`	Baltic Windows
  int get laguageDriverId => _bytes.getUint8(29);
  set laguageDriverId(int i) => _bytes.setUint8(29, i);
  String get laguageDriverIdName =>
      kDbfLanguageDriverIdNames[laguageDriverId] ?? 'UNKNOWN';

  /// `30-31` Зарезервировано (всегда 0)
  int get r30 => _bytes.getUint16(30, Endian.little);
  set r30(int i) => _bytes.setUint16(30, i, Endian.little);
}

/// Структура описания DBF полей
class DbfField {
  /// Отображение памяти
  final ByteData _bytes;

  DbfField(this._bytes);

  /// Получает отладочную информацию
  String get debugString {
    final str = StringBuffer();
    str.writeln('Имя поля:'.padRight(32) + '$name');
    str.writeln('Тип поля:'.padRight(32) + '$type - $typeName');
    str.writeln('Смещение поля в записи:'.padRight(32) + '$address');
    str.writeln('Полная длина поля:'.padRight(32) + '$length');
    str.writeln('Число десятичных разрядов:'.padRight(32) + '$decimalCount');
    str.writeln(
        'Field flags:'.padRight(32) + flags.toRadixString(16).padLeft(2, '0'));
    // str.writeln(
    //     'Autoincrement Next value:'.padRight(32) + '$autoincrementNextVal');
    // str.writeln(
    //     'Autoincrement Step value:'.padRight(32) + '$autoincrementStepVal');
    // str.writeln('Зарезервировано:'.padRight(32) + '$r24');
    // str.writeln('Зарезервировано:'.padRight(32) + '$r28');
    return str.toString();
  }

  /// `0-10` Имя поля.  If less than 10, it is padded with null characters (0x00)
  String get name => String.fromCharCodes(
      _bytes.buffer.asUint8List(0, 10).toList(growable: true)
        ..removeWhere((e) => e == 0x0));
  set name(String i) => _bytes.buffer
      .asUint8List(0, 10)
      .setAll(0, i.padRight(10, '\u0000').codeUnits.sublist(0, 10));

  /// `11` Тип поля
  /// - `B`	`Binary`	[dBASE 5]	Номер блока в MEMO-файле, хранимый в виде строки
  ///  до 10 цифр, выровненной вправо пробелами. Длина поля всегда 10. Пустое
  /// значение - 10 пробелов, означает отсутствие блока в MEMO-файле
  /// - `B`	`Double`	[MS Visual FoxPro]	Плавающее число, хранимое в 8-байтовом
  ///  бинарном формате IEEE 754. Пустое значение совпадает с нулем
  /// - `C`	`Character`	[dBASE III]	Строка, выровненная влево пробелами
  /// - `D`	`Date`	[dBASE III]	Дата, хранимая в виде строки из 8 цифр в формате
  ///  ГГГГММДД. Пустое значение - 10 пробелов
  /// - `F`	`Float`	[dBASE IV]	Число, хранимое в виде строки заданной длины с
  /// заданным количеством цифр после точки, выровненной вправо пробелами.
  /// Пустое значение задается строкой пробелов. Чем отличается от Numeric,
  /// непонятно
  /// - `G`	`General (OLE)`	[dBASE 5]	Номер блока в MEMO-файле, хранимый в виде
  /// строки до 10 цифр, выровненной вправо пробелами. Длина поля всегда 10.
  /// Пустое значение - 10 пробелов, означает отсутствие блока в MEMO-файле
  /// - `I`	`Integer (Long)`	[dBASE 7]	Знаковое целое число, хранимое в
  /// бинарном виде. Длина поля - 4 байта, порядок байтов - big-endian,
  /// старший бит инвертирован относительно дополнительного кода.
  /// Преимущество такого формата хранения в том, что числа можно сравнивать
  /// побайтово, что очень полезно для индексирования.
  /// Пустое значение совпадает с нулем
  /// - `L`	`Logical`	[dBASE III]	Булево значение, длина всегда 1.
  /// `T`, `t`, `Y`, `y` - истина, `F`, `f`, `N`, `n` - ложь,
  /// `пробел` или `?` - пустое значение
  /// - `M`	`Memo`	[dBASE III]	Номер блока в MEMO-файле, хранимый в виде строки
  /// до 10 цифр, выровненной вправо пробелами. Длина поля всегда 10.
  /// Пустое значение - 10 пробелов, означает отсутствие блока в MEMO-файле
  /// - `N`	`Numeric`	[dBASE III]	Число, хранимое в виде строки заданной длины
  /// с заданным количеством цифр после точки, выровненной вправо пробелами.
  /// Пустое значение задается строкой пробелов
  /// - `O`	`Double`	[dBASE 7]	Плавающее число, хранимое в 8-байтовом бинарном
  /// формате, получаемом из IEEE 754 простым преобразованием. Порядок байтов изменяется на обратный, для отрицательных чисел инвертируются все биты, для неотрицательных - только знаковый бит. Преимущество такого формата хранения в том, что числа можно сравнивать побайтово, что очень полезно для индексирования. Пустое значение совпадает с нулем
  /// - `P`	`Picture`	[FoxPro]	Номер блока в MEMO-файле, хранимый в виде строки
  /// до 10 цифр, выровненной вправо пробелами. Длина поля всегда 10.
  /// Пустое значение - 10 пробелов, означает отсутствие блока в MEMO-файле
  /// - `Q`	`Varbinary`	[MS Visual FoxPro]	Бинарные данные переменной длины.
  /// Начальная часть хранится в DBF-файле,
  /// хвост переменного размера - в memo-файле
  /// - `T`	`DateTime`	[FoxPro]	Дата и время. Существует в двух вариантах:
  /// текстовом и бинарном. Текстовый вариант - строка из 14 цифр в формате
  /// `ГГГГММДДЧЧММСС`; пустое значение - 14 пробелов.
  /// Бинарный вариант - два двойных слова little-endian, т.е. всего 8 байт;
  /// первое двойное слово содержит число дней от начала Юлианского календаря
  /// (01.01.4713 до нашей эры), второе двойное слово - число миллисекунд от
  /// начала суток; пустое значение - 8 нулевых байтов
  /// - `V`	`Varchar`	[MS Visual FoxPro]	Строка переменной длины.
  /// Начальная часть строки хранится в DBF-файле,
  /// хвост переменного размера - в memo-файле.
  /// Индексация - только по начальной части
  /// - `W`	`Blob`	[MS Visual FoxPro]	Нет информации о формате
  /// - `Y`	`Currency`	[MS Visual FoxPro]	Денежный тип.
  /// Хранится в виде знакового 8-байтового целого числа little-endian.
  /// Точность хранения составляет 1E-4 денежной единицы.
  /// Пустое значение совпадает с нулем
  /// - `@`	`Timestamp (DateTime)`	[dBASE 7]	Дата и время.
  /// Совпадает с типом 'T' в бинарном варианте
  /// - `+`	`Autoincrement`	[dBASE 7]	Знаковое целое число, хранимое в бинарном
  /// виде. Длина поля - 4 байта, порядок байтов - big-endian,
  /// старший бит инвертирован относительно дополнительного кода.
  /// Преимущество такого формата хранения в том, что числа можно сравнивать
  /// побайтово, что очень полезно для индексирования.
  /// Пустое значение совпадает с нулем
  String get type => String.fromCharCode(_bytes.getUint8(11));
  set type(String i) => _bytes.setUint8(11, i.codeUnits.first);
  String get typeName => kDbfFieldTypeName[type] ?? 'UNKNOWN';

  /// `12-15` Смещение поля в записи
  int get address => _bytes.getUint32(12, Endian.little);
  set address(int i) => _bytes.setUint32(12, i, Endian.little);

  /// `16` Полная длина поля
  int get length => _bytes.getUint8(16);
  set length(int i) => _bytes.setUint8(16, i);

  /// `17` Число десятичных разрядов; для типа C - второй байт длины поля
  int get decimalCount => _bytes.getUint8(17);
  set decimalCount(int i) => _bytes.setUint8(17, i);

  /// `18` Field flags:
  /// - `0x01`  System Column (not visible to user)
  /// - `0x02`  Column can store null values
  /// - `0x04`  Binary column (for CHAR and MEMO only)
  /// - `0x06`  (`0x02+0x04`) When a field is NULL and binary (Integer, Currency, and Character/Memo fields)
  /// - `0x0C`  Column is autoincrementing
  int get flags => _bytes.getUint8(18);
  set flags(int i) => _bytes.setUint8(18, i);
}

/// Структура записи DBF
class DbfRecord {
  /// Отображение памяти
  final ByteData _bytes;

  /// Заголовочный байт. Может принимать одно из следующих значений:
  /// - `0x20` `32` - обычная запись;
  /// - `0x2A` `42` - удаленная запись
  bool get deleted => _bytes.getUint8(0) == 0x2A;
  set deleted(bool i) => _bytes.setUint8(0, i ? 0x2A : 0x20);

  String debugString(final List<DbfField> fields, [bool head = false]) {
    final str = StringBuffer();
    final _filedsLength = fields.length;
    if (head) {
      str.write('#');
      for (var i = 0; i < _filedsLength; i++) {
        str.write('|' +
            fields[i]
                .name
                .padRight(max(fields[i].name.length, fields[i].length)));
      }
    } else {
      str.write(String.fromCharCode(_bytes.getUint8(0)));
      for (var i = 0; i < _filedsLength; i++) {
        final _type = fields[i].type;
        switch (_type) {
          case 'N':
            str.write('|' +
                (value(fields[i]) as double)
                    .toStringAsFixed(fields[i].decimalCount)
                    .padRight(max(fields[i].name.length, fields[i].length)));
            break;
          default:
            str.write('|' +
                value(fields[i])
                    .toString()
                    .padRight(max(fields[i].name.length, fields[i].length)));
        }
      }
    }

    return str.toString();
  }

  /// Получить значение по полю
  dynamic value(DbfField field) {
    final _type = field.type;
    switch (_type) {
      case 'C':
        return String.fromCharCodes(_bytes.buffer.asUint8List(
                _bytes.offsetInBytes + field.address,
                field.length + field.decimalCount << 8))
            .trim();
      case 'N':
        return double.tryParse(String.fromCharCodes(_bytes.buffer.asUint8List(
                _bytes.offsetInBytes + field.address, field.length))) ??
            double.nan;
      default:
        return String.fromCharCodes(_bytes.buffer.asUint8List(
                _bytes.offsetInBytes + field.address, field.length))
            .trim();
    }
  }

  DbfRecord(this._bytes);
}
