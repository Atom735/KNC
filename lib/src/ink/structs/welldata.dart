import '../structs.dart';

/// Данные инклинометрии каждой скважины
class InkWellData<T extends InkRowData> {
  /// Номер скважины
  final String well;

  /// Интервал печати начало (м)
  final double strt;

  /// Интервал печати конец (м)
  final double stop;

  /// Данные инклинометрии
  final List<T> data;

  InkWellData(this.well, this.strt, this.stop, this.data);
}
