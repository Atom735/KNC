/// Доп инфомация проведения инклинометрии
class InkExtInfo {
  /// Номер
  final int n;

  /// Интервал начало
  final double strt;

  /// Интервал конец
  final double stop;

  /// Количетсво точек
  final int count;

  /// Дата иследования (День)
  final int dd;

  /// Дата иследования (Месяц)
  final int mm;

  /// Дата иследования (Год)
  final int yy;

  /// Тип прибора
  final String devType;

  /// Номер прибора
  final int devNum;

  /// Дата проверки
  final String devDate;

  /// Ствол
  final String shaft;

  /// ЛБТ
  final String sLBT;

  /// ТБПВ
  final String sTBPV;

  /// УБТ
  final String sUBT;

  /// Фамилия начальника партии
  final String supervisor;

  /// Фамилия представителя заказчика
  final String client;

  InkExtInfo(
      this.n,
      this.strt,
      this.stop,
      this.count,
      this.dd,
      this.mm,
      this.yy,
      this.devType,
      this.devNum,
      this.devDate,
      this.shaft,
      this.sLBT,
      this.sTBPV,
      this.sUBT,
      this.supervisor,
      this.client);
}
