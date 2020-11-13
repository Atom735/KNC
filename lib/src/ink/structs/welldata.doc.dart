import '../structs.dart';

/// Данные инклинометрии DOCX файла
class InkWellDataDoc extends InkWellData<InkRowDataDoc> {
  /// Угол склонения (градусы)
  final double angle;

  /// Альтитуда (м)
  final double altitude;

  /// Доп инфомация
  final List<InkExtInfo> extInfo;

  /// Фамилия утверждающего
  final String approver;

  /// Заказчик
  final String client;

  /// Площадь
  final String square;

  /// Куст
  final String cluster;

  /// Диаметр скважины (м)
  final double diametr;

  /// Глубина башмака (м)
  final double depth;

  /// Забой (м)
  final double zaboy;

  /// Глубина максимального зенитного угла (м)
  final double maxZenithAngleDepth;

  /// Максимальный зенитный угол (градусы)
  final double maxZenithAngle;

  /// Глубина максимальной интенисивности кривизны (м)
  final double maxIntensityDepth;

  /// Максимальная интенсивность кривизны (градусы/10м)
  final double maxIntensity;

  /// Кто обработал
  final String processed;

  InkWellDataDoc(
      String well,
      double strt,
      double stop,
      List<InkRowDataDoc> data,
      this.angle,
      this.altitude,
      this.extInfo,
      this.approver,
      this.client,
      this.square,
      this.cluster,
      this.diametr,
      this.depth,
      this.zaboy,
      this.maxZenithAngleDepth,
      this.maxZenithAngle,
      this.maxIntensityDepth,
      this.maxIntensity,
      this.processed)
      : super(well, strt, stop, data);
}
