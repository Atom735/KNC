import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:knc/knc.dart';
import 'package:mdc_web/mdc_web.dart';

import 'App.dart';
import 'TaskFiles.dart';
import 'misc.dart';

class CardTask {
  final int uid;
  final Element eRoot;
  final Element eCard;
  final Element eName;
  final Element eState;
  final Element eBgIcon;
  final ButtonElement eBtnErrors;
  final ButtonElement eBtnWarnings;
  final ButtonElement eBtnFiles;
  final ButtonElement eBtnRaport;
  final Element eErrors;
  final Element eWarnings;
  final Element eFiles;
  final MDCLinearProgress eLinearProgress;

  static Future<void> init() async {
    document.body.querySelector('main div.mdc-layout-grid__inner').appendHtml(
        await HttpRequest.getString('/src/CardTask.html'),
        validator: nodeValidator);
  }

  void _updateState() {
    final s = NTaskState.values[_iState];
    switch (s) {
      case NTaskState.initialization:
        eState
          ..innerText = 'Запуск задачи' + (_bPause ? '(преостановлено)' : '')
          ..classes.clear()
          ..classes.addAll(['task-state', 'init']);
        eBgIcon.innerText = 'build_circle';
        eLinearProgress.close();
        break;
      case NTaskState.searchFiles:
        eState
          ..innerText = 'Поиск и подсчёт файлов для обработки' +
              (_bPause ? '(преостановлено)' : '')
          ..classes.clear()
          ..classes.addAll(['task-state', 'search']);
        eBgIcon.innerText = 'track_changes';
        eLinearProgress.open();
        eLinearProgress.determinate = false;
        break;
      case NTaskState.workFiles:
        eState
          ..innerText = 'Обработка файлов' + (_bPause ? '(преостановлено)' : '')
          ..classes.clear()
          ..classes.addAll(['task-state', 'work']);
        eBgIcon.innerText = 'arrow_circle_down';
        eLinearProgress.open();
        eLinearProgress.determinate = true;
        break;
      case NTaskState.generateTable:
        eState
          ..innerText =
              'Генерация таблицы' + (_bPause ? '(преостановлено)' : '')
          ..classes.clear()
          ..classes.addAll(['task-state', 'gen-tbl']);
        eBgIcon.innerText = 'motion_photos_on';
        break;
      case NTaskState.completed:
        eState
          ..innerText = 'Завершена' + (_bPause ? '(преостановлено)' : '')
          ..classes.clear()
          ..classes.addAll(['task-state', 'completed']);
        eBgIcon.innerText = 'stars';
        eLinearProgress.close();
        break;
      case NTaskState.reworkErrors:
        eState
          ..innerText =
              'Работа над ошибками' + (_bPause ? '(преостановлено)' : '')
          ..classes.clear()
          ..classes.addAll(['task-state', 'rework']);
        eBgIcon.innerText = 'swap_vertical_circle';
        break;
      case NTaskState.waitForCorrectErrors:
        eState
          ..innerText = 'Ожидание исправления ошибок' +
              (_bPause ? '(преостановлено)' : '')
          ..classes.clear()
          ..classes.addAll(['task-state', 'wait-errors']);
        eBgIcon.innerText = 'error';
        break;
    }
    if (_bPause) {
      eBgIcon.innerText = 'pause_circle_outline';
    }
  }

  String _sName;
  String get sName => _sName;
  set sName(final String i) {
    if (i == null || _sName == i) {
      return;
    }
    _sName = i;
    eName.innerText = '[$uid] $_sName';
  }

  bool _bPause = true;
  set bPause(final bool i) {
    if (i == null || _bPause == i) {
      return;
    }
    _bPause = i;
    _updateState();
  }

  int _iState = -1;
  set iState(final int i) {
    if (i == null || _iState == i) {
      return;
    }
    _iState = i;
    _updateState();
  }

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

  int _iWorked = -1;
  set iWorked(final int i) {
    if (i == null || _iWorked == i) {
      return;
    }
    _iWorked = i;
    eLinearProgress.progress = _iWorked.toDouble() / _iFiles.toDouble();
  }

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

  String dir;

  void byJson(final dynamic item) {
    sName = item['name'];
    iState = item['state'];
    iErrors = item['errors'];
    iWarnings = item['warnings'];
    iFiles = item['files'];
    iWorked = item['worked'];
    bPause = item['pause'];
    sRaport = item['raport'];
    print(dir);
    dir = item['dir'];
  }

  CardTask._new(final Element root, this.uid)
      : eRoot = root,
        eName = root.querySelector('.mdc-card__media-content>div>h2'),
        eState = root.querySelector('.mdc-card__media-content>div>h3'),
        eBgIcon = root.querySelector('.mdc-card__media-content>i'),
        eBtnErrors = root.querySelector('.mdc-card__actions button.my-errors'),
        eBtnWarnings =
            root.querySelector('.mdc-card__actions button.my-warnings'),
        eBtnFiles = root.querySelector('.mdc-card__actions button.my-files'),
        eBtnRaport = root.querySelector('.mdc-card__actions button.my-raport'),
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

    eBtnFiles.onClick.listen((_) {
      MyTaskFilesDialog(this).open();
    });
  }

  factory CardTask(final int uid) {
    final Element imp = document.importNode(
        CardTaskTemplate().eTemp.content.children.first, true);
    CardTaskTemplate().eTemp.parent.append(imp);

    return CardTask._new(imp, uid);
  }
}

class CardTaskTemplate {
  final TemplateElement eTemp;

  final list = <int, CardTask>{};

  void updateTasks() {
    App()
        .requestOnce(
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

  CardTaskTemplate._init(final TemplateElement temp) : eTemp = temp {
    print('$runtimeType created: $hashCode');
    _instance = this;
    updateTasks();

    App().waitMsgAll(wwwTaskNew).listen((msg) {
      final item = jsonDecode(msg.s);
      list[item['id']] = CardTask(item['id'])..byJson(item);
    });
    App().waitMsgAll(wwwTaskUpdates).listen((msg) {
      final items = json.decode(msg.s);
      for (final item in items) {
        list[item['id']]?.byJson(item);
      }
    });
  }

  static CardTaskTemplate _instance;
  factory CardTaskTemplate() =>
      (_instance) ??
      (_instance = CardTaskTemplate._init(eGetById('my-template-task-card')));
}
