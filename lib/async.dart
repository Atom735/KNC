import 'dart:async';

import 'dart:math';

class AsyncTask<R> {
  /// Комплитер заверешния задачи
  Completer completer = Completer<R>();

  /// Функция исполнения задачи
  final Future<R> Function() func;

  /// Флаг выполнения
  bool run = false;

  AsyncTask(this.func);
}

class AsyncTaskQueue {
  /// Максимальное количество одновременно исполняемых задач
  int _max;

  /// Пауза выполнения задач
  bool _pause;

  /// Список ожидаемых задач
  final _tasks = <AsyncTask>[];

  AsyncTaskQueue([this._max = 8, this._pause = false]);

  /// Пауза выполнения задач
  bool get pause => _pause;

  /// Пауза выполнения задач (Выполняющиеся задачи не будут остановлены)
  set pause(bool pause) {
    _pause = pause;
    tryProc();
  }

  /// Максимальное количество одновременно исполняемых задач
  int get max => _max;

  /// Максимальное количество одновременно исполняемых задач
  set max(int max) {
    _max = max;
    tryProc();
  }

  /// Попытка запустить задчи из очереди
  void tryProc() {
    if (!_pause) {
      final _min = min<int>(_max, _tasks.length);
      for (var i = 0; i < _min; i++) {
        final task = _tasks[i];
        if (task.run == false) {
          task.run = true;
          if (task.func != null) {
            task.func().then((value) {
              task.completer.complete(value);
              _tasks.remove(task);
              tryProc();
            });
          }
        }
      }
    }
  }

  /// Добавить задачу в очередь
  Future<R> addTask<R>(Future<R> Function() func) {
    final task = AsyncTask<R>(func);
    _tasks.add(task);
    tryProc();
    return task.completer.future;
  }
}
