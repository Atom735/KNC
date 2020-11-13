import 'dart:typed_data';

import '../structs.dart';
import '../texts.dart';

/// Структура описания DBF полей
class DbfField {
  /// Указатель на базу данных
  final Dbf dbf;

  /// Отображение памяти
  final ByteData byteData;

  DbfField(this.byteData, this.dbf);

  /// `0-10` Имя поля.  If less than 10, it is padded with null characters (0x00)
  String get name => String.fromCharCodes(
      Uint8List.sublistView(byteData, 0, 10).toList(growable: true)
        ..removeWhere((e) => e == 0x0));
  set name(String i) => Uint8List.sublistView(byteData, 0, 10)
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
  String get type => String.fromCharCode(byteData.getUint8(11));
  set type(String i) => byteData.setUint8(11, i.codeUnits.first);
  String get typeName => kDbfFieldTypeName[type] ?? 'UNKNOWN';

  /// `12-15` Смещение поля в записи
  int get address => byteData.getUint32(12, Endian.little);
  set address(int i) => byteData.setUint32(12, i, Endian.little);

  /// `16` Полная длина поля
  int get length => byteData.getUint8(16);
  set length(int i) => byteData.setUint8(16, i);

  /// `17` Число десятичных разрядов; для типа C - второй байт длины поля
  int get decimalCount => byteData.getUint8(17);
  set decimalCount(int i) => byteData.setUint8(17, i);

  /// `18` Field flags:
  /// - `0x01`  System Column (not visible to user)
  /// - `0x02`  Column can store null values
  /// - `0x04`  Binary column (for CHAR and MEMO only)
  /// - `0x06`  (`0x02+0x04`) When a field is NULL and binary (Integer, Currency, and Character/Memo fields)
  /// - `0x0C`  Column is autoincrementing
  int get flags => byteData.getUint8(18);
  set flags(int i) => byteData.setUint8(18, i);
}
