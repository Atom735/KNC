import '../structs.dart';

extension DbfFieldExt on DbfField {
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
}
