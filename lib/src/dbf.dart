import 'dart:math';
import 'dart:typed_data';
import 'dbf.g.dart';

extension IDbfHead on DbfHead {
  static DbfHead /*?*/ createByByteData(final ByteData bytes) {
    if (bytes.lengthInBytes < 32) {
      return null;
    }
    return DbfHead(
        bytes.getUint8(0),
        bytes.getUint8(1),
        bytes.getUint8(2),
        bytes.getUint8(3),
        bytes.getUint32(4, Endian.little),
        bytes.getUint16(8, Endian.little),
        bytes.getUint16(10, Endian.little),
        bytes.getUint16(12, Endian.little),
        bytes.getUint8(14),
        bytes.getUint8(15),
        bytes.getUint32(16, Endian.little),
        bytes.getUint32(20, Endian.little),
        bytes.getUint32(24, Endian.little),
        bytes.getUint8(28),
        bytes.getUint8(29),
        bytes.getUint16(30),
        '',
        0);
  }

  String getDebugString() {
    final str = StringBuffer();
    str.write('СИГНАТУРА: 0x' + signature.toRadixString(16).padLeft(2, '0'));
    switch (signature) {
      case 2:
        str.writeln('`0x02`	`00000010`	[FoxBASE]	Таблица без memo-полей');
        break;
      case 3:
        str.writeln(
            '`0x03`	`00000011`	[dBASE III, dBASE IV, dBASE 5, dBASE 7, FoxPro, FoxBASE+]	Таблица без memo-полей');
        break;
      case 4:
        str.writeln('`0x04`	`00000100`	[dBASE 7]	Таблица без memo-полей');
        break;
      case 48:
        str.writeln(
            '`0x30`	`00110000`	[Visual FoxPro]	Таблица (признак наличия memo-поля .FPT не предусмотрен )');
        break;
      case 49:
        str.writeln(
            '`0x31`	`00110001`	[Visual FoxPro]	Таблица с автоинкрементными полями');
        break;
      case 67:
        str.writeln(
            '`0x43`	`01000011`	[dBASE IV, dBASE 5]	SQL-таблица dBASE IV без memo-полей');
        break;
      case 99:
        str.writeln(
            '`0x63`	`01100011`	[dBASE IV, dBASE 5]	Системная SQL-таблица dBASE IV без memo-полей');
        break;
      case 131:
        str.writeln(
            '`0x83`	`10000011`	[dBASE III, FoxBASE+, FoxPro]	Таблица с memo-полями .DBT');
        break;
      case 139:
        str.writeln(
            '`0x8B`	`10001011`	[dBASE IV, dBASE 5]	Таблица с memo-полями .DBT формата dBASE IV');
        break;
      case 140:
        str.writeln(
            '`0x8C`	`10001100`	[dBASE 7]	Таблица с memo-полями .DBT формата dBASE IV');
        break;
      case 203:
        str.writeln(
            '`0xCB`	`11001011`	[dBASE IV, dBASE 5]	SQL-таблица dBASE IV с memo-полями .DBT');
        break;
      case 229:
        str.writeln('`0xE5`	`11100101`	[SMT]	Таблица с memo-полями .SMT');
        break;
      case 235:
        str.writeln(
            '`0xEB`	`11101011`	[dBASE IV, dBASE 5]	Системная SQL-таблица dBASE IV с memo-полями .DBT');
        break;
      case 245:
        str.writeln('`0xF5`	`11110101`	[FoxPro]	Таблица с memo-полями .FPT');
        break;
      case 251:
        str.writeln('`0xFB`	`11111011`	[FoxBASE]	Таблица с memo-полями .???');
        break;
      default:
        str.writeln('UNKNOWN');
        break;
    }
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
    str.writeln('Кодовая страница:'.padRight(32) + '$laguageDriverID');
    switch (laguageDriverID) {
      case 1:
        str.writeln('`0x01`	`437`	US MS-DOS');
        break;
      case 2:
        str.writeln('`0x02`	`850`	International MS-DOS');
        break;
      case 3:
        str.writeln('`0x03`	`1252`	Windows ANSI Latin I');
        break;
      case 4:
        str.writeln('`0x04`	`10000`	Standard Macintosh');
        break;
      case 8:
        str.writeln('`0x08`	`865`	Danish OEM');
        break;
      case 9:
        str.writeln('`0x09`	`437`	Dutch OEM');
        break;
      case 10:
        str.writeln('`0x0A`	`850`	Dutch OEM*');
        break;
      case 11:
        str.writeln('`0x0B`	`437`	Finnish OEM');
        break;
      case 13:
        str.writeln('`0x0D`	`437`	French OEM');
        break;
      case 14:
        str.writeln('`0x0E`	`850`	French OEM*');
        break;
      case 15:
        str.writeln('`0x0F`	`437`	German OEM');
        break;
      case 16:
        str.writeln('`0x10`	`850`	German OEM*');
        break;
      case 17:
        str.writeln('`0x11`	`437`	Italian OEM');
        break;
      case 18:
        str.writeln('`0x12`	`850`	Italian OEM*');
        break;
      case 19:
        str.writeln('`0x13`	`932`	Japanese Shift-JIS');
        break;
      case 20:
        str.writeln('`0x14`	`850`	Spanish OEM*');
        break;
      case 21:
        str.writeln('`0x15`	`437`	Swedish OEM');
        break;
      case 22:
        str.writeln('`0x16`	`850`	Swedish OEM*');
        break;
      case 23:
        str.writeln('`0x17`	`865`	Norwegian OEM');
        break;
      case 24:
        str.writeln('`0x18`	`437`	Spanish OEM');
        break;
      case 25:
        str.writeln('`0x19`	`437`	English OEM (Great Britain)');
        break;
      case 26:
        str.writeln('`0x1A`	`850`	English OEM (Great Britain)*');
        break;
      case 27:
        str.writeln('`0x1B`	`437`	English OEM (US)');
        break;
      case 28:
        str.writeln('`0x1C`	`863`	French OEM (Canada)');
        break;
      case 29:
        str.writeln('`0x1D`	`850`	French OEM*');
        break;
      case 31:
        str.writeln('`0x1F`	`852`	Czech OEM');
        break;
      case 34:
        str.writeln('`0x22`	`852`	Hungarian OEM');
        break;
      case 35:
        str.writeln('`0x23`	`852`	Polish OEM');
        break;
      case 36:
        str.writeln('`0x24`	`860`	Portuguese OEM');
        break;
      case 37:
        str.writeln('`0x25`	`850`	Portuguese OEM*');
        break;
      case 38:
        str.writeln('`0x26`	`866`	Russian OEM');
        break;
      case 55:
        str.writeln('`0x37`	`850`	English OEM (US)*');
        break;
      case 64:
        str.writeln('`0x40`	`852`	Romanian OEM');
        break;
      case 77:
        str.writeln('`0x4D`	`936`	Chinese GBK (PRC)');
        break;
      case 78:
        str.writeln('`0x4E`	`949`	Korean (ANSI/OEM)');
        break;
      case 79:
        str.writeln('`0x4F`	`950`	Chinese Big5 (Taiwan)');
        break;
      case 80:
        str.writeln('`0x50`	`874`	Thai (ANSI/OEM)');
        break;
      case 87:
        str.writeln('`0x57`	`Current ANSI CP`	ANSI');
        break;
      case 88:
        str.writeln('`0x58`	`1252`	Western European ANSI');
        break;
      case 89:
        str.writeln('`0x59`	`1252`	Spanish ANSI');
        break;
      case 100:
        str.writeln('`0x64`	`852`	Eastern European MS-DOS');
        break;
      case 101:
        str.writeln('`0x65`	`866`	Russian MS-DOS');
        break;
      case 102:
        str.writeln('`0x66`	`865`	Nordic MS-DOS');
        break;
      case 103:
        str.writeln('`0x67`	`861`	Icelandic MS-DOS');
        break;
      case 104:
        str.writeln('`0x68`	`895`	Kamenicky (Czech) MS-DOS');
        break;
      case 105:
        str.writeln('`0x69`	`620`	Mazovia (Polish) MS-DOS');
        break;
      case 106:
        str.writeln('`0x6A`	`737`	Greek MS-DOS (437G)');
        break;
      case 107:
        str.writeln('`0x6B`	`857`	Turkish MS-DOS');
        break;
      case 108:
        str.writeln('`0x6C`	`863`	French-Canadian MS-DOS');
        break;
      case 120:
        str.writeln('`0x78`	`950`	Taiwan Big 5');
        break;
      case 121:
        str.writeln('`0x79`	`949`	Hangul (Wansung)');
        break;
      case 122:
        str.writeln('`0x7A`	`936`	PRC GBK');
        break;
      case 123:
        str.writeln('`0x7B`	`932`	Japanese Shift-JIS');
        break;
      case 124:
        str.writeln('`0x7C`	`874`	Thai Windows/MS–DOS');
        break;
      case 134:
        str.writeln('`0x86`	`737`	Greek OEM');
        break;
      case 135:
        str.writeln('`0x87`	`852`	Slovenian OEM');
        break;
      case 136:
        str.writeln('`0x88`	`857`	Turkish OEM');
        break;
      case 150:
        str.writeln('`0x96`	`10007`	Russian Macintosh');
        break;
      case 151:
        str.writeln('`0x97`	`10029`	Eastern European Macintosh');
        break;
      case 152:
        str.writeln('`0x98`	`10006`	Greek Macintosh');
        break;
      case 200:
        str.writeln('`0xC8`	`1250`	Eastern European Windows');
        break;
      case 201:
        str.writeln('`0xC9`	`1251`	Russian Windows');
        break;
      case 202:
        str.writeln('`0xCA`	`1254`	Turkish Windows');
        break;
      case 203:
        str.writeln('`0xCB`	`1253`	Greek Windows');
        break;
      case 204:
        str.writeln('`0xCC`	`1257`	Baltic Windows');
        break;
      default:
        str.writeln('UNKNOWN');
        break;
    }
    str.writeln('Зарезервировано (всегда 0):'.padRight(32) + '$r30');
    str.writeln('Языковой драйвер:'.padRight(32) + '$laguageDriverName');
    str.writeln('Зарезервировано:'.padRight(32) + '$r64');
    return str.toString();
  }
}

extension IDbfFieldStruct on DbfFieldStruct {
  static DbfFieldStruct /*?*/ createByByteData(final ByteData bytes) {
    if (bytes.lengthInBytes < 32) {
      return null;
    }
    var ij = -1;
    for (var i = 0; i <= 10 && ij == -1; i++) {
      if (bytes.getUint8(i) == 0) {
        ij = i;
      }
    }
    if (ij == -1) {
      ij = 11;
    }
    final _name =
        String.fromCharCodes(bytes.buffer.asInt8List(bytes.offsetInBytes, ij));
    final _type = String.fromCharCode(bytes.getUint8(11));
    return DbfFieldStruct(
        _name,
        _type,
        bytes.getUint32(12, Endian.little),
        bytes.getUint8(16),
        bytes.getUint8(17),
        bytes.getUint8(18),
        bytes.getUint32(19, Endian.little),
        bytes.getUint8(23),
        bytes.getUint32(24, Endian.little),
        bytes.getUint32(28, Endian.little));
  }

  String getDebugString() {
    final str = StringBuffer();
    str.writeln('Имя поля:'.padRight(32) + name);
    str.writeln('Тип поля:'.padRight(32) + type);
    switch (type) {
      case 'B':
        str.writeln(
            '- `B`	`Binary`	[dBASE 5]	Номер блока в MEMO-файле, хранимый в виде строки');
        str.writeln(
            ' до 10 цифр, выровненной вправо пробелами. Длина поля всегда 10. Пустое');
        str.writeln(
            'значение - 10 пробелов, означает отсутствие блока в MEMO-файле');
        str.writeln(
            '- `B`	`Double`	[MS Visual FoxPro]	Плавающее число, хранимое в 8-байтовом');
        str.writeln(
            ' бинарном формате IEEE 754. Пустое значение совпадает с нулем');
        break;
      case 'C':
        str.writeln(
            '- `C`	`Character`	[dBASE III]	Строка, выровненная влево пробелами');
        break;
      case 'D':
        str.writeln(
            '- `D`	`Date`	[dBASE III]	Дата, хранимая в виде строки из 8 цифр в формате');
        str.writeln(' ГГГГММДД. Пустое значение - 10 пробелов');
        break;
      case 'F':
        str.writeln(
            '- `F`	`Float`	[dBASE IV]	Число, хранимое в виде строки заданной длины с');
        str.writeln(
            'заданным количеством цифр после точки, выровненной вправо пробелами.');
        str.writeln(
            'Пустое значение задается строкой пробелов. Чем отличается от Numeric,');
        str.writeln('непонятно');
        break;
      case 'G':
        str.writeln(
            '- `G`	`General (OLE)`	[dBASE 5]	Номер блока в MEMO-файле, хранимый в виде');
        str.writeln(
            'строки до 10 цифр, выровненной вправо пробелами. Длина поля всегда 10.');
        str.writeln(
            'Пустое значение - 10 пробелов, означает отсутствие блока в MEMO-файле');
        break;
      case 'I':
        str.writeln(
            '- `I`	`Integer (Long)`	[dBASE 7]	Знаковое целое число, хранимое в');
        str.writeln(
            'бинарном виде. Длина поля - 4 байта, порядок байтов - big-endian,');
        str.writeln(
            'старший бит инвертирован относительно дополнительного кода.');
        str.writeln(
            'Преимущество такого формата хранения в том, что числа можно сравнивать');
        str.writeln('побайтово, что очень полезно для индексирования.');
        str.writeln('Пустое значение совпадает с нулем');
        break;
      case 'L':
        str.writeln(
            '- `L`	`Logical`	[dBASE III]	Булево значение, длина всегда 1.');
        str.writeln('`T`, `t`, `Y`, `y` - истина, `F`, `f`, `N`, `n` - ложь,');
        str.writeln('`пробел` или `?` - пустое значение');
        break;
      case 'M':
        str.writeln(
            '- `M`	`Memo`	[dBASE III]	Номер блока в MEMO-файле, хранимый в виде строки');
        str.writeln(
            'до 10 цифр, выровненной вправо пробелами. Длина поля всегда 10.');
        str.writeln(
            'Пустое значение - 10 пробелов, означает отсутствие блока в MEMO-файле');
        break;
      case 'N':
        str.writeln(
            '- `N`	`Numeric`	[dBASE III]	Число, хранимое в виде строки заданной длины');
        str.writeln(
            'с заданным количеством цифр после точки, выровненной вправо пробелами.');
        str.writeln('Пустое значение задается строкой пробелов');
        break;
      case 'O':
        str.writeln(
            '- `O`	`Double`	[dBASE 7]	Плавающее число, хранимое в 8-байтовом бинарном');
        str.writeln(
            'формате, получаемом из IEEE 754 простым преобразованием. Порядок байтов изменяется на обратный, для отрицательных чисел инвертируются все биты, для неотрицательных - только знаковый бит. Преимущество такого формата хранения в том, что числа можно сравнивать побайтово, что очень полезно для индексирования. Пустое значение совпадает с нулем');
        break;
      case 'P':
        str.writeln(
            '- `P`	`Picture`	[FoxPro]	Номер блока в MEMO-файле, хранимый в виде строки');
        str.writeln(
            'до 10 цифр, выровненной вправо пробелами. Длина поля всегда 10.');
        str.writeln(
            'Пустое значение - 10 пробелов, означает отсутствие блока в MEMO-файле');
        break;
      case 'Q':
        str.writeln(
            '- `Q`	`Varbinary`	[MS Visual FoxPro]	Бинарные данные переменной длины.');
        str.writeln('Начальная часть хранится в DBF-файле,');
        str.writeln('хвост переменного размера - в memo-файле');
        break;
      case 'T':
        str.writeln(
            '- `T`	`DateTime`	[FoxPro]	Дата и время. Существует в двух вариантах:');
        str.writeln(
            'текстовом и бинарном. Текстовый вариант - строка из 14 цифр в формате');
        str.writeln('`ГГГГММДДЧЧММСС`; пустое значение - 14 пробелов.');
        str.writeln(
            'Бинарный вариант - два двойных слова little-endian, т.е. всего 8 байт;');
        str.writeln(
            'первое двойное слово содержит число дней от начала Юлианского календаря');
        str.writeln(
            '(01.01.4713 до нашей эры), второе двойное слово - число миллисекунд от');
        str.writeln('начала суток; пустое значение - 8 нулевых байтов');
        break;
      case 'V':
        str.writeln(
            '- `V`	`Varchar`	[MS Visual FoxPro]	Строка переменной длины.');
        str.writeln('Начальная часть строки хранится в DBF-файле,');
        str.writeln('хвост переменного размера - в memo-файле.');
        str.writeln('Индексация - только по начальной части');
        break;
      case 'W':
        str.writeln('- `W`	`Blob`	[MS Visual FoxPro]	Нет информации о формате');
        break;
      case 'Y':
        str.writeln('- `Y`	`Currency`	[MS Visual FoxPro]	Денежный тип.');
        str.writeln(
            'Хранится в виде знакового 8-байтового целого числа little-endian.');
        str.writeln('Точность хранения составляет 1E-4 денежной единицы.');
        str.writeln('Пустое значение совпадает с нулем');
        break;
      case '@':
        str.writeln('- `@`	`Timestamp (DateTime)`	[dBASE 7]	Дата и время.');
        str.writeln('Совпадает с типом \'T\' в бинарном варианте');
        break;
      case '+':
        str.writeln(
            '- `+`	`Autoincrement`	[dBASE 7]	Знаковое целое число, хранимое в бинарном');
        str.writeln('виде. Длина поля - 4 байта, порядок байтов - big-endian,');
        str.writeln(
            'старший бит инвертирован относительно дополнительного кода.');
        str.writeln(
            'Преимущество такого формата хранения в том, что числа можно сравнивать');
        str.writeln('побайтово, что очень полезно для индексирования.');
        str.writeln('Пустое значение совпадает с нулем');
        break;
      default:
        str.writeln('UNKNOWN');
        break;
    }
    str.writeln('Смещение поля в записи:'.padRight(32) + '$address');
    str.writeln('Полная длина поля:'.padRight(32) + '$length');
    str.writeln('Число десятичных разрядов:'.padRight(32) + '$decimalCount');
    str.writeln(
        'Field flags:'.padRight(32) + flags.toRadixString(16).padLeft(2, '0'));
    str.writeln(
        'Autoincrement Next value:'.padRight(32) + '$autoincrementNextVal');
    str.writeln(
        'Autoincrement Step value:'.padRight(32) + '$autoincrementStepVal');
    str.writeln('Зарезервировано:'.padRight(32) + '$r24');
    str.writeln('Зарезервировано:'.padRight(32) + '$r28');
    return str.toString();
  }
}

extension IDbfRecord on DbfRecord {
  static DbfRecord /*?*/ createByByteData(
      final ByteData bytes, final List<DbfFieldStruct> fields) {
    var offset = 1;
    final _filedsLength = fields.length;
    final _list = List.filled(_filedsLength, '');
    for (var j = 0; j < _filedsLength; j++) {
      _list[j] = String.fromCharCodes(bytes.buffer
          .asUint8List(bytes.offsetInBytes + offset, fields[j].length));
      offset += fields[j].length;
    }
    return DbfRecord(bytes.getUint8(0), _list);
  }

  String getDebugString(final List<DbfFieldStruct> fields,
      [bool head = false]) {
    final str = StringBuffer();
    final _filedsLength = fields.length;
    if (head) {
      str.write(' ');
      for (var i = 0; i < _filedsLength; i++) {
        str.write('|' +
            fields[i]
                .name
                .padRight(max(fields[i].name.length, fields[i].length)));
      }
      str.writeln();
    } else {
      str.write(String.fromCharCode(headByte));
      for (var i = 0; i < _filedsLength; i++) {
        str.write('|' +
            values[i]
                .toString()
                .padRight(max(fields[i].name.length, fields[i].length)));
      }
      str.writeln();
    }

    return str.toString();
  }
}

extension IOneFileDbf on OneFileDbf {
  /// Загружает данные из буфера байтов
  static OneFileDbf /*?*/ createByByteData(final ByteData bytes) {
    /// Если в базе данных отсутсвует заголовок и хотяб одно поле
    if (bytes.lengthInBytes < 65) {
      return null;
    }
    final _head = IDbfHead.createByByteData(bytes);

    /// Если размеры не соответсуют укзаанным
    if (bytes.lengthInBytes <
        _head.lengthOfHeader +
            _head.lengthOfEachRecord * _head.numberOfRecords) {
      return null;
    }
    final _fields = <DbfFieldStruct>[];

    var offset = 32;
    while (bytes.getUint8(offset) != 0x0D) {
      _fields.add(IDbfFieldStruct.createByByteData(
          ByteData.sublistView(bytes, offset, offset + 32)));
      offset += 32;
    }
    final _records = List<DbfRecord>.generate(_head.numberOfRecords, (i) {
      offset = _head.lengthOfHeader + _head.lengthOfEachRecord * i;
      return IDbfRecord.createByByteData(
          ByteData.sublistView(
              bytes, offset, offset + _head.lengthOfEachRecord),
          _fields);
    });
    return OneFileDbf(_head, _fields, _records);
  }

  String getDebugString() {
    final str = StringBuffer();
    str.writeln(head.getDebugString());
    for (var field in fields) {
      str.writeln(field.getDebugString());
    }
    if (records.isNotEmpty) {
      str.writeln(records.first.getDebugString(fields, true));
      for (var record in records) {
        str.writeln(record.getDebugString(fields));
      }
    }
    return str.toString();
  }
}
