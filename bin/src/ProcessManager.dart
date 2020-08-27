import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:math';

/// Состояние задачи
class _AsyncTask {
  /// Комплитер заверешния задачи
  Completer completer = Completer<ProcessResult>();

  /// Функция исполнения задачи
  final Future<ProcessResult> Function() func;

  /// Флаг выполнения
  bool run = false;

  _AsyncTask(this.func);
}

/// Менеджер процессов, следит за количеством запущенных процессов
class ProcessManager {
  /// Максимальное количество одновременно исполняемых задач
  int _max;

  /// Максимальное количество одновременно исполняемых задач
  int get max => _max;

  /// Максимальное количество одновременно исполняемых задач
  set max(int i) {
    if (_max == i) {
      return;
    }
    _max = i;
    tryProc();
  }

  /// Список ожидаемых задач
  final _tasks = <_AsyncTask>[];

  /// Устанавливает количество максимальное количество
  /// одновременно запущенных процессов
  ProcessManager([this._max = 8]);

  /// Добавляет процесс в очередь на запуск
  Future<ProcessResult> run(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding}) {
    final task = _AsyncTask(() => Process.run(executable, arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding));
    _tasks.add(task);
    tryProc();
    return task.completer.future;
  }

  /// Попытка запустить задачи из очереди
  void tryProc() {
    final _min = _max <= 0 ? _tasks.length : min<int>(_max, _tasks.length);
    for (var i = 0; i < _min; i++) {
      final task = _tasks[i];
      if (task.run == false) {
        task.run = true;
        if (task.func != null) {
          task.func().then((value) {
            task.completer.complete(value);
            _tasks.remove(task);
            tryProc();
            return;
          });
        }
      }
    }
  }
}
