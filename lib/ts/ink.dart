/// Доп инфомация проведения инклинометрии
class OneFileInkExtInfo {
  /// Номер
  int n;

  /// Интервал начало
  double strt;

  /// Интервал конец
  double stop;

  /// Количетсво точек
  int count;

  /// Дата иследования (День)
  int dd;

  /// Дата иследования (Месяц)
  int mm;

  /// Дата иследования (Год)
  int yy;

  /// Тип прибора
  String devType;

  /// Номер прибора
  int devNum;

  /// Дата проверки
  String devDate;

  /// Ствол
  String shaft;

  /// ЛБТ
  String sLBT;

  /// ТБПВ
  String sTBPV;

  /// УБТ
  String sUBT;

  /// Фамилия начальника партии
  String supervisor;

  /// Фамилия представителя заказчика
  String client;
}

/// Данные инклинометрии
class OneFileInkDataExt {
  /// Глубина (м)
  double depth;

  /// Угол (градусы)
  double angle;

  /// Азимут (градусы)
  double azimuth;

  /// Звёздочка у значения Азимута
  bool azimuthStar;

  /// Удлинение (м)
  double addLenght;

  /// Абс. отметка (м)
  double absPoint;

  /// Вертикальная глубина (м)
  double vertDepth;

  /// Смещение (м)
  double offset;

  /// Дир. угол смещения (градусы)
  double offsetAngle;

  /// +север, -юг, (м)
  double north;

  /// +восток, -запад, (м)
  double west;

  /// Интенсивность (градусы/10м)
  double intensity;
}

/// Данные инклинометрии DOCX файла
class OneFileInk {
  /// Фамилия утверждающего
  String approver;

  /// Заказчик
  String client;

  /// Номер скважины
  String well;

  /// Площадь
  String /*?*/ square;

  /// Куст
  String /*?*/ cluster;

  /// Диаметр скважины (м)
  double /*?*/ diametr;

  /// Глубина башмака (м)
  double /*?*/ depth;

  /// Угол склонения (градусы)
  double angle;

  /// Альтитуда (м)
  double altitude;

  /// Забой (м)
  double /*?*/ zaboy;

  /// Доп инфомация
  List<OneFileInkExtInfo> extInfo;

  /// Данные инклинометрии
  List<OneFileInkDataExt> data;

  /// Интервал печати начало (м)
  double strt;

  /// Интервал печати конец (м)
  double stop;

  /// Глубина максимального зенитного угла (м)
  double /*?*/ maxZenithAngleDepth;

  /// Максимальный зенитный угл (градусы)
  double /*?*/ maxZenithAngle;

  /// Глубина максимальной интенисивности кривизны (м)
  double /*?*/ maxIntensityDepth;

  /// Максимальная интенсивность кривизны (градусы/10м)
  double /*?*/ maxIntensity;

  /// Кто обработал
  String /*?*/ processed;
}
