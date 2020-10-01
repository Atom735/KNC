import 'dart:convert';

enum NTaskState {
  initialization,
  searchFiles,
  workFiles,
  generateTable,
  waitForCorrectErrors,
  reworkErrors,
  completed,
}

/// Обёртка над JSON данными состояния задачи
class JTaskState {
  final Map<String, dynamic> map;

  /// Данные подготовляемые для отправки как обновление состояния задачи
  final mapUpdates = <String, dynamic>{};

  /// Handle таймера
  Future<void> /*?*/ _updatesFuture;

  /// Частота обновления
  Duration duration;

  /// Функция обновления данных
  void Function() /*?*/ onUpdate;

  void _onUpdateEnd(void _) {
    mapUpdates.clear();
    mapUpdates['id'] = map['id'];
    _updatesFuture = null;
  }

  /// Состояние задачи
  NTaskState get state =>
      NTaskState.values[(map[jsonKey_state] as int /*?*/) ?? 0];
  static const jsonKey_state = 'state';
  set state(final NTaskState /*?*/ i) {
    if (i == null || state == i) {
      return;
    }
    map[jsonKey_state] = i.index;
    mapUpdates[jsonKey_state] = i.index;
    _updatesFuture ??= Future.delayed(duration, onUpdate).then(_onUpdateEnd);
  }

  /// Количество обработанных файлов с ошибками
  int get errors => (map[jsonKey_errors] as int /*?*/) ?? 0;
  static const jsonKey_errors = 'errors';
  set errors(final int /*?*/ i) {
    if (i == null || errors == i) {
      return;
    }
    map[jsonKey_errors] = i;
    mapUpdates[jsonKey_errors] = i;
    _updatesFuture ??= Future.delayed(duration, onUpdate).then(_onUpdateEnd);
  }

  /// Количество найденных файлов для обработки
  int get files => (map[jsonKey_files] as int /*?*/) ?? 0;
  static const jsonKey_files = 'files';
  set files(final int /*?*/ i) {
    if (i == null || files == i) {
      return;
    }
    map[jsonKey_files] = i;
    mapUpdates[jsonKey_files] = i;
    _updatesFuture ??= Future.delayed(duration, onUpdate).then(_onUpdateEnd);
  }

  /// Количество обработанных файлов с предупреждениями и/или ошибками
  int get warnings => (map[jsonKey_warnings] as int /*?*/) ?? 0;
  static const jsonKey_warnings = 'files';
  set warnings(final int /*?*/ i) {
    if (i == null || warnings == i) {
      return;
    }
    map[jsonKey_warnings] = i;
    mapUpdates[jsonKey_warnings] = i;
    _updatesFuture ??= Future.delayed(duration, onUpdate).then(_onUpdateEnd);
  }

  /// Количество обработанных файлов
  int get worked => (map[jsonKey_worked] as int /*?*/) ?? 0;
  static const jsonKey_worked = 'worked';
  set worked(final int /*?*/ i) {
    if (i == null || worked == i) {
      return;
    }
    map[jsonKey_worked] = i;
    mapUpdates[jsonKey_worked] = i;
    _updatesFuture ??= Future.delayed(duration, onUpdate).then(_onUpdateEnd);
  }

  /// Ссылка на отчётную таблицу
  bool get raport => (map[jsonKey_raport] as bool /*?*/) ?? false;
  static const jsonKey_raport = 'raport';
  set raport(final bool /*?*/ i) {
    if (i == null || raport == i) {
      return;
    }
    map[jsonKey_raport] = i;
    mapUpdates[jsonKey_raport] = i;
    _updatesFuture ??= Future.delayed(duration, onUpdate).then(_onUpdateEnd);
  }

  JTaskState(this.map, this.duration, [this.onUpdate]) {
    mapUpdates.addAll(map);
    _updatesFuture ??= Future.delayed(duration, onUpdate).then(_onUpdateEnd);
  }

  factory JTaskState.fromJson(Map<String, dynamic> m) =>
      JTaskState(m, Duration.zero);
  Map<String, dynamic> toJson() => map;
  @override
  String toString() => jsonEncode(this);
}
