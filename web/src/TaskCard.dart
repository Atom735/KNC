import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:knc/www.dart';
import 'package:m4d_components/m4d_components.dart';
import 'package:mdc_web/mdc_web.dart';

import 'App.dart';
import 'HtmlGenerator.dart';
import 'TaskErrors.dart';
import 'TaskFiles.dart';
import 'TaskViewSection.dart';
import 'misc.dart';

class MyTaskCard {
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

  void _updateState() {
    final s = NTaskState.values[_iState];
    switch (s) {
      case NTaskState.initialization:
        eState
          ..innerText = 'Запуск задачи' + (_bPause ? '(преостановлено)' : '')
          ..classes.clear()
          ..classes.addAll(['task-state', 'init']);
        eBgIcon.innerText = 'build_circle';
        break;
      case NTaskState.searchFiles:
        eState
          ..innerText = 'Поиск и подсчёт файлов для обработки' +
              (_bPause ? '(преостановлено)' : '')
          ..classes.clear()
          ..classes.addAll(['task-state', 'search']);
        eBgIcon.innerText = 'track_changes';
        break;
      case NTaskState.workFiles:
        eState
          ..innerText = 'Обработка файлов' + (_bPause ? '(преостановлено)' : '')
          ..classes.clear()
          ..classes.addAll(['task-state', 'work']);
        eBgIcon.innerText = 'arrow_circle_down';
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

  void byJson(final dynamic item) {
    sName = item['name'];
    iState = item['state'];
    iErrors = item['errors'];
    iWarnings = item['warnings'];
    iFiles = item['files'];
    bPause = item['pause'];
    sRaport = item['raport'];
  }

  MyTaskCard._new(final Element root, this.uid)
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
  }

  factory MyTaskCard(final int uid) {
    final Element imp = document.importNode(
        MyTaskCardTemplate().eTemp.content.children.first, true);
    MyTaskCardTemplate().eTemp.parent.append(imp);

    return MyTaskCard._new(imp, uid);
  }
}

class MyTaskCardTemplate {
  final TemplateElement eTemp;

  final list = <int, MyTaskCard>{};

  void updateTasks() {
    App()
        .requestOnce(
            wwwTaskViewUpdate + jsonEncode(list.keys.toList(growable: false)))
        .then((msg) {
      final items = jsonDecode(msg);
      for (final item in items) {
        list[item['id']] = MyTaskCard(item['id'])..byJson(item);
      }
    });
  }

  MyTaskCardTemplate._init(final TemplateElement temp) : eTemp = temp {
    print('$runtimeType created: $hashCode');
    _instance = this;

    updateTasks();

    App().waitMsgAll(wwwTaskNew).listen((msg) {
      final item = jsonDecode(msg.s);
      list[item['id']] = MyTaskCard(item['id'])..byJson(item);
    });
    App().waitMsgAll(wwwTaskUpdates).listen((msg) {
      final items = json.decode(msg.s);
      for (final item in items) {
        list[item['id']]?.byJson(item);
      }
    });
  }

  static MyTaskCardTemplate _instance;
  factory MyTaskCardTemplate() =>
      (_instance) ??
      (_instance = MyTaskCardTemplate._init(eGetById('my-template-task-card')));
}

class ErrorFileDetails {}

class TaskCard {
  final int id;
  final DivElement eCard;
  final Element eName;
  final Element eState;
  final ButtonElement eReport;
  final ButtonElement eErrors;
  final ButtonElement eFiles;
  final ButtonElement eLaunch;
  final ButtonElement eClose;

  bool errorsDialogOpend = false;
  bool filesDialogOpend = false;

  int _iState = -1;
  int _iErrors = -1;
  int _iFiles = -1;
  bool _hiden = true;
  set hidden(final bool b) {
    if (_hiden == b) {
      return;
    }
    _hiden = b;
    eCard.hidden = _hiden;
  }

  set iState(final int i) {
    if (i == null || _iState == i) {
      return;
    }
    _iState = i;
    switch (_iState) {
      case 0:
        eState
          ..innerText = 'Запускается'
          ..classes.clear()
          ..classes.add('task-state-init');
        break;
      case 1:
        eState
          ..innerText = 'Выполняется'
          ..classes.clear()
          ..classes.add('task-state-work');
        break;
      case 2:
        eState
          ..innerText = 'Генерируется таблица'
          ..classes.clear()
          ..classes.add('task-state-table');
        break;
      case 3:
        eState
          ..innerText = 'Завершена'
          ..classes.clear()
          ..classes.add('task-state-end');
        eReport.disabled = false;
        break;
      default:
    }
  }

  set iErrors(final int i) {
    if (i == null || _iErrors == i) {
      return;
    }
    _iErrors = i;
    if (errorsDialogOpend) {
      TaskErrorsDialog().iErrors = _iErrors;
    }
    if (_iErrors <= 0) {
      eErrors.attributes.remove('data-badge');
    } else if (_iErrors >= 1000) {
      eErrors.attributes['data-badge'] = '...';
    } else {
      eErrors.attributes['data-badge'] = _iErrors.toString();
    }
  }

  set iFiles(final int i) {
    if (i == null || _iFiles == i) {
      return;
    }
    _iFiles = i;
    if (filesDialogOpend) {
      TaskFilesDialog().iFiles = _iFiles;
    }
    if (_iFiles <= 0) {
      eFiles.attributes.remove('data-badge');
    } else if (_iFiles >= 1000) {
      eFiles.attributes['data-badge'] = '...';
    } else {
      eFiles.attributes['data-badge'] = _iFiles.toString();
    }
  }

  TaskCard(this.id)
      : eCard = eGetById('task-${id}-card'),
        eName = eGetById('task-${id}-name'),
        eState = eGetById('task-${id}-state'),
        eReport = eGetById('task-${id}-report'),
        eErrors = eGetById('task-${id}-errors'),
        eFiles = eGetById('task-${id}-files'),
        eLaunch = eGetById('task-${id}-launch'),
        eClose = eGetById('task-${id}-close') {
    eClose.onClick.listen((_) {
      eCard.remove();
      TaskViewSection().list.remove(id);
    });
    eErrors.onClick.listen((_) {
      TaskErrorsDialog().iErrors = _iErrors;
      TaskErrorsDialog().openByTaskCard(this);
    });
    eFiles.onClick.listen((_) {
      TaskFilesDialog().iFiles = _iFiles;
      TaskFilesDialog().openByTaskCard(this);
    });
    componentHandler().upgradeElement(eCard);
  }

  static String htmlTemplateSrc;

  static String html(final int id) =>
      htmlGenFromSrc(htmlTemplateSrc, {'id': id});
}
