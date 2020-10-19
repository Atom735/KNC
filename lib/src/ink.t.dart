/// Доп инфомация проведения инклинометрии
class OneFileInkDataDocExtInfo {
  /// Номер
  int n;

  /// Интервал начало
  double /*?*/ strt;

  /// Интервал конец
  double /*?*/ stop;

  /// Количетсво точек
  int /*?*/ count;

  /// Дата иследования (День)
  int /*?*/ dd;

  /// Дата иследования (Месяц)
  int /*?*/ mm;

  /// Дата иследования (Год)
  int /*?*/ yy;

  /// Тип прибора
  String /*?*/ devType;

  /// Номер прибора
  int /*?*/ devNum;

  /// Дата проверки
  String /*?*/ devDate;

  /// Ствол
  String /*?*/ shaft;

  /// ЛБТ
  String /*?*/ sLBT;

  /// ТБПВ
  String /*?*/ sTBPV;

  /// УБТ
  String /*?*/ sUBT;

  /// Фамилия начальника партии
  String /*?*/ supervisor;

  /// Фамилия представителя заказчика
  String /*?*/ client;
}

/// Данные инклинометрии, одна строка
class OneFileInkDataRow {
  /// Глубина (м)
  double depth;

  /// Угол (градусы)
  double angle;

  /// Угол (градусы`минуты)
  double angle1;

  /// Азимут (градусы)
  double azimuth;
}

/// Данные инклинометрии DBF файла на каждую скважину, одна строка
class OneFileInkDataRowDbf extends OneFileInkDataRow {
  /// Дополнительные поля данных скважины, названия берутся из [OneFileInkDataDbf]
  List<String> /*?*/ extInfo;
}

/// Данные инклинометрии DOCX файла, одна строка
class OneFileInkDataRowDoc extends OneFileInkDataRow {
  /// Звёздочка у значения Азимута
  bool azimuthStar;

  /// Удлинение (м)
  double /*?*/ addLenght;

  /// Абс. отметка (м)
  double /*?*/ absPoint;

  /// Вертикальная глубина (м)
  double /*?*/ vertDepth;

  /// Смещение (м)
  double /*?*/ offset;

  /// Дир. угол смещения (градусы)
  double /*?*/ offsetAngle;

  /// Дир. угол смещения (градусы`минуты)
  double /*?*/ offsetAngle1;

  /// +север, -юг, (м)
  double /*?*/ north;

  /// +восток, -запад, (м)
  double /*?*/ west;

  /// Интенсивность (градусы/10м)
  double /*?*/ intensity;
}

/// Данные инклинометрии каждой скважины
class OneFileInkData<T extends OneFileInkDataRow> {
  /// Номер скважины
  String well;

  /// Интервал печати начало (м)
  double strt;

  /// Интервал печати конец (м)
  double stop;

  /// Данные инклинометрии
  List<T> data;
}

/// Данные инклинометрии DBF файла на каждую скважину
class OneFileInkDataDbfWell extends OneFileInkData<OneFileInkDataRowDbf> {}

/// Данные инклинометрии DOCX файла
class OneFileInkDataDoc extends OneFileInkData<OneFileInkDataRowDoc> {
  /// Угол склонения (градусы)
  double angle;

  /// Альтитуда (м)
  double altitude;

  /// Доп инфомация
  List<OneFileInkDataDocExtInfo> extInfo;

  /// Фамилия утверждающего
  String /*?*/ approver;

  /// Заказчик
  String /*?*/ client;

  /// Площадь
  String /*?*/ square;

  /// Куст
  String /*?*/ cluster;

  /// Диаметр скважины (м)
  double /*?*/ diametr;

  /// Глубина башмака (м)
  double /*?*/ depth;

  /// Забой (м)
  double /*?*/ zaboy;

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

/// Данные инклинометрии DBF файла
class OneFileInkDataDbf {
  /// Данные инклинометрии каждой скважины
  List<OneFileInkDataDbfWell> wells;

  /// Наименования дополнительных полей данных скважины
  List<String> extInfo;
}
