import 'rowdata.dart';

/// Данные инклинометрии DOCX файла, одна строка
class InkRowDataDoc extends InkRowData {
  /// Звёздочка у значения Азимута
  final bool azimuthStar;

  /// Удлинение (м)
  final double addLenght;

  /// Абс. отметка (м)
  final double absPoint;

  /// Вертикальная глубина (м)
  final double vertDepth;

  /// Смещение (м)
  final double offset;

  /// Дир. угол смещения (градусы)
  final double offsetAngle;

  /// +север, -юг, (м)
  final double north;

  /// +восток, -запад, (м)
  final double west;

  /// Интенсивность (градусы/10м)
  final double intensity;

  InkRowDataDoc(
      double depth,
      double angle,
      double azimuth,
      this.azimuthStar,
      this.addLenght,
      this.absPoint,
      this.vertDepth,
      this.offset,
      this.offsetAngle,
      this.north,
      this.west,
      this.intensity)
      : super(depth, angle, azimuth);
}
