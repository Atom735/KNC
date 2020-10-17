/// https://www.clicketyclick.dk/databases/xbase/format/dbf.html
/// http://www.dbase.com/Knowledgebase/INT/db7_file_fmt.htm
/// https://www.dbf2002.com/dbf-file-format.html
/// http://www.autopark.ru/ASBProgrammerGuide/DBFSTRUC.HTM
/// Структура заголовка DBF файла
class DbfHead {
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
  int signature;

  /// `1` Дата последней модификации Год
  int lastUpdateYY;

  /// `2` Дата последней модификации Месяц
  int lastUpdateMM;

  /// `3` Дата последней модификации День
  int lastUpdateDD;

  /// `4-7` Число записей в базе
  int numberOfRecords;

  /// `8-9` Полная длина заголовка (с дескрипторами полей) или
  /// позиция начала записей
  int lengthOfHeader;

  /// `10-11` Длина одной записи
  int lengthOfEachRecord;

  /// `12-13` Зарезервировано (всегда 0)
  int r12;

  /// `14` Флаг, указывающий на наличие незавершенной транзакции [dBASE IV]
  int incompleteTransac;

  /// `15` Флаг шифрования таблицы [dBASE IV]
  int ecryptionFlag;

  /// `16-27` Зарезервированная область для многопользовательского использования
  int r16;

  /// `16-27` Зарезервированная область для многопользовательского использования
  int r20;

  /// `16-27` Зарезервированная область для многопользовательского использования
  int r24;

  /// `28` Флаг наличия индексного MDX-файла
  /// - `0x01` file has a structural [.cdx]
  /// - `0x02` file has a [Memo field]
  /// - `0x04` file is a database ([.dbc])
  /// - This byte can contain the sum of any of the above values. For example, the value 0x03 indicates the table has a structural .cdx and a Memo field.
  int mdxFlag;

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
  int laguageDriverID;

  /// `30-31` Зарезервировано (всегда 0)
  int r30;

  /// `32-63` Только в [dBASE 7]. Идентификатор языкового драйвера.
  String laguageDriverName;

  /// `64-67` Только в [dBASE 7]. Зарезервировано
  int r64;
}

/// Структура описания DBF полей
class DbfFieldStruct {
  /// `0-10` Имя поля.  If less than 10, it is padded with null characters (0x00)
  String name;

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
  String type;

  /// `12-15` Смещение поля в записи
  int address;

  /// `16` Полная длина поля
  int length;

  /// `17` Число десятичных разрядов; для типа C - второй байт длины поля
  int decimalCount;

  /// `18` Field flags:
  /// - `0x01`  System Column (not visible to user)
  /// - `0x02`  Column can store null values
  /// - `0x04`  Binary column (for CHAR and MEMO only)
  /// - `0x06`  (`0x02+0x04`) When a field is NULL and binary (Integer, Currency, and Character/Memo fields)
  /// - `0x0C`  Column is autoincrementing
  int flags;

  /// `19-22` Value of autoincrement Next value
  int autoincrementNextVal;

  /// `23` Value of autoincrement Step value
  int autoincrementStepVal;

  /// `24-31` Зарезервировано
  int r24;

  /// `24-31` Зарезервировано
  int r28;
}

/// Структура записи DBF
class DbfRecord {
  /// Заголовочный байт. Может принимать одно из следующих значений:
  /// - `0x20` `32` - обычная запись;
  /// - `0x2A` `42` - удаленная запись
  int headByte;

  /// Данные записи (количество данных n). Данные полей в порядке описания полей
  /// без разделителей.
  List<dynamic> values;
}

/// Структура данных DBF
class OneFileDbf {
  /// Заголовок БД
  DbfHead head;

  /// Поля
  List<DbfFieldStruct> fields;

  /// Записи
  List<DbfRecord> records;
}