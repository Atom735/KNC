import 'dart:typed_data';

import '../texts.dart';
import 'field.dart';
import 'record.dart';

/// Структура заголовка DBF файла
class Dbf {
  /// Отображение памяти
  final ByteData byteData;

  /// Поля записи
  final List<DbfField> fields = [];

  final List<DbfRecord> records = [];

  Dbf._(this.byteData);
  Dbf(this.byteData) {
    var offset = 32;
    while (byteData.getUint8(offset) != 0x0D) {
      fields.add(
          DbfField(ByteData.sublistView(byteData, offset, offset + 32), this));
      offset += 32;
    }
    final _l = numberOfRecords;
    final _lR = lengthOfEachRecord;
    offset = lengthOfHeader;
    for (var i = 0; i < _l; i++) {
      records.add(DbfRecord(
          ByteData.sublistView(byteData, offset, offset + _lR), this));
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
  int get signature => byteData.getUint8(0);
  set signature(int i) => byteData.setUint8(0, i);
  String get signatureName => kDbfSignaturesNames[signature] ?? 'UNKNOWN';

  /// `1` Дата последней модификации Год
  int get lastUpdateYY => byteData.getUint8(1);
  set lastUpdateYY(int i) => byteData.setUint8(1, i);

  /// `2` Дата последней модификации Месяц
  int get lastUpdateMM => byteData.getUint8(2);
  set lastUpdateMM(int i) => byteData.setUint8(2, i);

  /// `3` Дата последней модификации День
  int get lastUpdateDD => byteData.getUint8(3);
  set lastUpdateDD(int i) => byteData.setUint8(3, i);

  /// `4-7` Число записей в базе
  int get numberOfRecords => byteData.getUint32(4, Endian.little);
  set numberOfRecords(int i) => byteData.setUint32(4, i, Endian.little);

  /// `8-9` Полная длина заголовка (с дескрипторами полей) или
  /// позиция начала записей
  int get lengthOfHeader => byteData.getUint16(8, Endian.little);
  set lengthOfHeader(int i) => byteData.setUint16(8, i, Endian.little);

  /// `10-11` Длина одной записи
  int get lengthOfEachRecord => byteData.getUint16(10, Endian.little);
  set lengthOfEachRecord(int i) => byteData.setUint16(10, i, Endian.little);

  /// `12-13` Зарезервировано (всегда 0)
  int get r12 => byteData.getUint16(12, Endian.little);
  set r12(int i) => byteData.setUint16(12, i, Endian.little);

  /// `14` Флаг, указывающий на наличие незавершенной транзакции [dBASE IV]
  int get incompleteTransac => byteData.getUint8(14);
  set incompleteTransac(int i) => byteData.setUint8(14, i);

  /// `15` Флаг шифрования таблицы [dBASE IV]
  int get ecryptionFlag => byteData.getUint8(15);
  set ecryptionFlag(int i) => byteData.setUint8(15, i);

  /// `16-27` Зарезервированная область для многопользовательского использования
  int get r16 => byteData.getUint32(16, Endian.little);
  set r16(int i) => byteData.setUint32(16, i, Endian.little);

  /// `16-27` Зарезервированная область для многопользовательского использования
  int get r20 => byteData.getUint32(20, Endian.little);
  set r20(int i) => byteData.setUint32(20, i, Endian.little);

  /// `16-27` Зарезервированная область для многопользовательского использования
  int get r24 => byteData.getUint32(24, Endian.little);
  set r24(int i) => byteData.setUint32(24, i, Endian.little);

  /// `28` Флаг наличия индексного MDX-файла
  /// - `0x01` file has a structural [.cdx]
  /// - `0x02` file has a [Memo field]
  /// - `0x04` file is a database ([.dbc])
  /// - This byte can contain the sum of any of the above values. For example, the value 0x03 indicates the table has a structural .cdx and a Memo field.
  int get mdxFlag => byteData.getUint8(28);
  set mdxFlag(int i) => byteData.setUint8(28, i);

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
  int get laguageDriverId => byteData.getUint8(29);
  set laguageDriverId(int i) => byteData.setUint8(29, i);
  String get laguageDriverIdName =>
      kDbfLanguageDriverIdNames[laguageDriverId] ?? 'UNKNOWN';

  /// `30-31` Зарезервировано (всегда 0)
  int get r30 => byteData.getUint16(30, Endian.little);
  set r30(int i) => byteData.setUint16(30, i, Endian.little);
}
