/// Данные инклинометрии, одна строка
class InkRowData {
  /// Глубина (м)
  final double depth;

  /// Угол (градусы)
  final double angle;

  /// Азимут (градусы)
  final double azimuth;

  InkRowData(this.depth, this.angle, this.azimuth);
}
