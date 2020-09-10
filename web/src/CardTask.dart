import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:knc/knc.dart';
import 'package:mdc_web/mdc_web.dart';

import 'App.dart';
import 'TaskFiles.dart';
import 'misc.dart';

class CardTask {
  final String id;
  final Element eRoot;
  final Element eCard;
  final Element eName;
  final Element eState;
  final Element eBgIcon;
  final ButtonElement eBtnErrors;
  final ButtonElement eBtnWarnings;
  final ButtonElement eBtnFiles;
  final ButtonElement eBtnRaport;
  final ButtonElement eBtnRestart;
  final Element eErrors;
  final Element eWarnings;
  final Element eFiles;
  final MDCLinearProgress eLinearProgress;

  /// Загрузка шаблона и инициализация модуля
  static Future<void> init() async {
    document.body.querySelector('main div.mdc-layout-grid__inner').appendHtml(
        await HttpRequest.getString('/src/CardTask.html'),
        validator: nodeValidator);
  }

  /// Обновление состояния задачи в визуальном представлении
  void _updateState() {
    final s = NTaskState.values[_iState];
    switch (s) {
      case NTaskState.initialization:
        eState
          ..innerText = 'Запуск задачи'
          ..classes.clear()
          ..classes.addAll(['task-state', 'init']);
        eBgIcon.innerText = 'build_circle';
        eLinearProgress.close();
        break;
      case NTaskState.searchFiles:
        eState
          ..innerText = 'Поиск и подсчёт файлов для обработки'
          ..classes.clear()
          ..classes.addAll(['task-state', 'search']);
        eBgIcon.innerText = 'track_changes';
        eLinearProgress.open();
        eLinearProgress.determinate = false;
        break;
      case NTaskState.workFiles:
        eState
          ..innerText = 'Обработка файлов'
          ..classes.clear()
          ..classes.addAll(['task-state', 'work']);
        eBgIcon.innerText = 'arrow_circle_down';
        eLinearProgress.open();
        eLinearProgress.determinate = true;
        break;
      case NTaskState.generateTable:
        eState
          ..innerText = 'Генерация таблицы'
          ..classes.clear()
          ..classes.addAll(['task-state', 'gen-tbl']);
        eBgIcon.innerText = 'motion_photos_on';
        break;
      case NTaskState.completed:
        eState
          ..innerText = 'Завершена'
          ..classes.clear()
          ..classes.addAll(['task-state', 'completed']);
        eBgIcon.innerText = 'stars';
        eLinearProgress.close();
        break;
      case NTaskState.reworkErrors:
        eState
          ..innerText = 'Работа над ошибками'
          ..classes.clear()
          ..classes.addAll(['task-state', 'rework']);
        eBgIcon.innerText = 'swap_vertical_circle';
        break;
      case NTaskState.waitForCorrectErrors:
        eState
          ..innerText = 'Ожидание исправления ошибок'
          ..classes.clear()
          ..classes.addAll(['task-state', 'wait-errors']);
        eBgIcon.innerText = 'error';
        break;
    }
    if (_bClosed) {
      eBgIcon.innerText = 'pause_circle_outline';
    }
  }

  /// Название задачи
  String _sName;
  String get sName => _sName;
  set sName(final String i) {
    if (i == null || _sName == i) {
      return;
    }
    _sName = i;
    eName.innerText = '[$id] $_sName' + (_bClosed ? ' (Не запущена)' : '');
  }

  /// Является ли задача "Мёртвой", т.е. не запущенной
  bool _bClosed = false;
  set bClosed(final bool i) {
    if (i == null || _bClosed == i) {
      return;
    }
    _bClosed = i;
    eName.innerText = '[$id] $_sName' + (_bClosed ? ' (Не запущена)' : '');
    eBtnRestart.hidden = !_bClosed;
    _updateState();
  }

  /// Состояние задачи
  int _iState = -1;
  set iState(final int i) {
    if (i == null || _iState == i) {
      return;
    }
    _iState = i;
    _updateState();
  }

  /// Количество обработанных файлов с ошибками
  int _iErrors = -1;
  set iErrors(final int i) {
    if (i == null || _iErrors == i) {
      return;
    }
    _iErrors = i;
    if (_iErrors <= 0) {
      // eErrors.hidden = true;
      eBtnErrors.hidden = true;
    } else {
      // eErrors.hidden = false;
      eBtnErrors.hidden = false;
      if (_iErrors >= 1000) {
        eErrors.innerText =
            '${_iErrors % 1000 == 0 ? '' : '>'}${_iErrors ~/ 1000}k';
      } else {
        eErrors.innerText = _iErrors.toString();
      }
    }
  }

  /// Количество обработанных файлов с предупреждениями
  int _iWarnings = -1;
  set iWarnings(final int i) {
    if (i == null || _iWarnings == i) {
      return;
    }
    _iWarnings = i;
    if (_iWarnings <= 0) {
      // eWarnings.hidden = true;
      eBtnWarnings.hidden = true;
    } else {
      // eWarnings.hidden = false;
      eBtnWarnings.hidden = false;
      if (_iWarnings >= 1000) {
        eWarnings.innerText =
            '${_iWarnings % 1000 == 0 ? '' : '>'}${_iWarnings ~/ 1000}k';
      } else {
        eWarnings.innerText = _iWarnings.toString();
      }
    }
  }

  /// Количество найденных файлов
  int _iFiles = -1;
  int get iFiles => _iFiles;
  set iFiles(final int i) {
    if (i == null || _iFiles == i) {
      return;
    }
    _iFiles = i;
    if (_iFiles <= 0) {
      // eFiles.hidden = true;
      eBtnFiles.hidden = true;
    } else {
      // eFiles.hidden = false;
      eBtnFiles.hidden = false;
      if (_iFiles >= 1000) {
        eFiles.innerText =
            '${_iFiles % 1000 == 0 ? '' : '>'}${_iFiles ~/ 1000}k';
      } else {
        eFiles.innerText = _iFiles.toString();
      }
    }
  }

  /// Количество обработанных файлов
  int _iWorked = -1;
  set iWorked(final int i) {
    if (i == null || _iWorked == i) {
      return;
    }
    _iWorked = i;
    eLinearProgress.progress = _iWorked.toDouble() / _iFiles.toDouble();
  }

  /// Ссылка на отчёт задачи
  String _sRaport;
  StreamSubscription _ssRaport;
  set sRaport(final String i) {
    if (i == null || _sRaport == i) {
      return;
    }
    _sRaport = i;

    if (_ssRaport != null) {
      _ssRaport.cancel();
      _ssRaport = null;
    }
    if (_sRaport == null || _sRaport.isEmpty) {
      eBtnRaport.hidden = true;
    } else {
      eBtnRaport.hidden = false;
      _ssRaport =
          eBtnRaport.onClick.listen((_) => window.open(_sRaport, _sRaport));
    }
  }

  /// Название папки задачи
  String _dir;
  set dir(final String i) {
    if (i == null || _dir == i) {
      return;
    }
    _dir = i;
  }

  void byJson(final dynamic item) {
    sName = item['name'];
    iState = item['state'];
    iErrors = item['errors'];
    iWarnings = item['warnings'];
    iFiles = item['files'];
    iWorked = item['worked'];
    bClosed = item['closed'];
    sRaport = item['raport'];
    dir = item['dir'];
  }

  CardTask._new(final Element root, this.id)
      : eRoot = root,
        eName = root.querySelector('.mdc-card__media-content>div>h2'),
        eState = root.querySelector('.mdc-card__media-content>div>h3'),
        eBgIcon = root.querySelector('.mdc-card__media-content>i'),
        eBtnErrors = root.querySelector('.mdc-card__actions button.my-errors'),
        eBtnWarnings =
            root.querySelector('.mdc-card__actions button.my-warnings'),
        eBtnFiles = root.querySelector('.mdc-card__actions button.my-files'),
        eBtnRaport = root.querySelector('.mdc-card__actions button.my-raport'),
        eBtnRestart =
            root.querySelector('.mdc-card__actions button.my-restart'),
        eErrors = root.querySelector('.mdc-card__actions button.my-errors>i'),
        eWarnings =
            root.querySelector('.mdc-card__actions button.my-warnings>i'),
        eFiles = root.querySelector('.mdc-card__actions button.my-files>i'),
        eCard = root.querySelector('.mdc-card'),
        eLinearProgress =
            MDCLinearProgress(root.querySelector('.mdc-linear-progress')) {
    eCard.querySelector('.mdc-card__media-content > i')?.style?.transform =
        'scale(${eCard.offsetWidth / 48})';
    window.onResize.listen((_) => eCard
        .querySelector('.mdc-card__media-content > i')
        ?.style
        ?.transform = 'scale(${eCard.offsetWidth / 48})');

    eBtnErrors.onClick.listen((_) {
      window.history.pushState('data', 'title', '/app/task/$id/files/e');
      TaskFiles().open(id, 'e').then((_b) {
        if (!_b) {
          window.history.back();
        }
      });
    });
    eBtnWarnings.onClick.listen((_) {
      window.history.pushState('data', 'title', '/app/task/$id/files/w');
      TaskFiles().open(id, 'w').then((_b) {
        if (!_b) {
          window.history.back();
        }
      });
    });
    eBtnFiles.onClick.listen((_) {
      window.history.pushState('data', 'title', '/app/task/$id/files');
      TaskFiles().open(id).then((_b) {
        if (!_b) {
          window.history.back();
        }
      });
    });
    eBtnRestart.onClick.listen((_) {
      requestOnce(wwwTaskRestart + id).then((msg) {
        // TODO: ответ на перезапуск задачи
      });
    });
  }

  factory CardTask(final String id) {
    final Element imp = document.importNode(
        CardTaskTemplate().eTemp.content.children.first, true);
    CardTaskTemplate().eTemp.parent.append(imp);

    return CardTask._new(imp, id);
  }
}

class CardTaskTemplate {
  /// Шаблон карточки задачи
  final TemplateElement eTemp;

  final list = <String, CardTask>{};

  /// Запрос на обновление состояния списка всех доступных задач
  void updateTasks() {
    requestOnce(
            wwwTaskViewUpdate + jsonEncode(list.keys.toList(growable: false)))
        .then((msg) {
      final items = jsonDecode(msg);
      for (final item in items) {
        if (list[item['id']] == null) {
          list[item['id']] = CardTask(item['id'])..byJson(item);
        }
      }
    });
  }

  /// Удаляет все видимые карточки задач
  void removeAllTasks() {
    list.values.forEach((e) {
      e.eRoot.remove();
    });
    list.clear();
  }

  CardTaskTemplate._init(final TemplateElement temp) : eTemp = temp {
    print('$runtimeType created: $hashCode');
    _instance = this;

    /// Запрос на обновление состояния списка всех доступных задач
    updateTasks();

    /// Реагируем на сообщения о новых задачах
    waitMsgAll(wwwTaskNew).listen((msg) {
      final item = jsonDecode(msg.s);
      list[item['id']] = CardTask(item['id'])..byJson(item);
    });

    /// Реагируем на сообщения об обновлении состояния задачи
    waitMsgAll(wwwTaskUpdates).listen((msg) {
      final item = json.decode(msg.s);
      list[item['id']]?.byJson(item);
    });
  }

  static CardTaskTemplate _instance;
  factory CardTaskTemplate() =>
      (_instance) ??
      (_instance = CardTaskTemplate._init(eGetById('my-template-task-card')));
}
