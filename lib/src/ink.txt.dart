import 'ink.g.dart';

// ignore: slash_for_doc_comments
/**
```regexp
^\s*утверждаю\s+
?(?:[\s\S]*?([\w :]+)[\s\S]*?
?(?:_+)([\w \.\s]+?$))?
```
- 1 - Звание
- 2 - ФИО
*/
final reInkTxtApprover = RegExp(
    r'^\s*Утверждаю\s+'
    r'(?:[\s\S]*?([\w :]+)[\s\S]*?'
    r'(?:_+)([\w \.\s]+?$))?',
    multiLine: true,
    unicode: true,
    caseSensitive: false);

final reInkTxtTitle = RegExp(r'^\s*Замер кривизны\s*$',
    multiLine: true, unicode: true, caseSensitive: false);

/// - 1 - Заказчик
final reInkTxtClient = RegExp(r'^\s*Заказчик.?(.*)$',
    multiLine: true, unicode: true, caseSensitive: false);

// ignore: slash_for_doc_comments
/**
```regexp
^Скважина(?:\s*N)?(.*?)
?(?:\s*Площадь(?:\s*:)?(.*?))?
?(?:\s*Куст(?:\s*:)?(.*?))?$
```
- 1 - Скважина
- 2? - Площадь
- 3? - Куст
*/
final reInkTxtWell = RegExp(
    r'^Скважина(?:\s*N)?(.*?)'
    r'(?:\s*Площадь(?:\s*:)?(.*?))?'
    r'(?:\s*Куст(?:\s*:)?(.*?))?$',
    multiLine: true,
    unicode: true,
    caseSensitive: false);

// ignore: slash_for_doc_comments
/**
```regexp
^Диаметр(?:\s*скважины:)?(?:\s*:)?(.*?)
?(?:\s*Глубина(?:\s*башмака)?(?:\s*:)?(.*?))?$
```
- 1 - Диаметр скважины
- 2? - Глубина башмака
*/
final reInkTxtDiametr = RegExp(
    r'^Диаметр(?:\s*скважины:)?(?:\s*:)?(.*?)'
    r'(?:\s*Глубина(?:\s*башмака)?(?:\s*:)?(.*?))?$',
    multiLine: true,
    unicode: true,
    caseSensitive: false);

// ignore: slash_for_doc_comments
/**
```regexp
^Угол(?:\s*склонения:)?(?:\s*:)?(.*?)
?(?:\s*Альтитуда(?:\s*:)?(.*?))?
?(?:\s*Забой(?:\s*:)?(.*?))?$
```
- 1 - Угол склонения
- 2? - Альтитуда
- 3? - Забой
*/
final reInkTxtAngle = RegExp(
    r'^Угол(?:\s*склонения:)?(?:\s*:)?(.*?)'
    r'(?:\s*Альтитуда(?:\s*:)?(.*?))?'
    r'(?:\s*Забой(?:\s*:)?(.*?))?$',
    multiLine: true,
    unicode: true,
    caseSensitive: false);

/// - 1 - Интервал печати
final reInkTxtPrint = RegExp(r'^В\s+интервале\s+печати\s*:?(.+)$',
    multiLine: true, unicode: true, caseSensitive: false);

/// - 1 - Глубина максимального зенитного угла
/// - 2 - Максимальный зенитный угол
final reInkTxtMaxZenith = RegExp(
    r'^(?:На\s+глубине)?(?:\s*-)?\s*(.+)макс(?:имaльный)?\s+зенит(?:ный\s+угол)?(?:\s*-)?\s*(.+)$',
    multiLine: true,
    unicode: true,
    caseSensitive: false);

/// - 1 - Глубина максимальной интенисивности кривизны
/// - 2 - Максимальная интенсивность кривизны
final reInkTxtMaxIntensity = RegExp(
    r'^(?:На\s+глубине)?(?:\s*-)?\s*(.+)макс(?:имaльная)?\s+инт(?:енсивность\s+кривизны)?(?:\s*-)?(.+)$',
    multiLine: true,
    unicode: true,
    caseSensitive: false);

/// - 1 - Кто обработал
final reInkTxtProcessed = RegExp(r'^\s*Обработал\s*:?\s*(.+)$',
    multiLine: true, unicode: true, caseSensitive: false);

extension IOneFileInkDataTxt on OneFileInkDataDoc {
  static OneFileInkDataDoc /*?*/ createByString(final String data) {}
}
