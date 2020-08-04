import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:m4d_core/m4d_ioc.dart' as ioc;
import 'package:m4d_components/m4d_components.dart';

import 'main.fictive.dart';
import 'socketWrapper.dart';
import 'www.dart';

/// webdev serve --auto refresh --debug --launch-in-chrome --log-requests
///
/// @{{uID клиента}}
/// {{uID запроса}};{{msg}}

final uri = Uri.tryParse(document.baseUri);

Element eGetById(final String id) => document.getElementById(id);

final _htmlValidator = NodeValidatorBuilder.common()
  ..allowElement('button', attributes: ['data-badge']);

class TaskSetsPath {
  final int id;
  final TaskSetsDialog dialog;
  final TableRowElement eRow;
  final InputElement eInput;
  final ButtonElement eRemove;
  TaskSetsPath(this.id, this.dialog)
      : eRow = eGetById('task-sets-path-${id}-row'),
        eInput = eGetById('task-sets-path-${id}-input'),
        eRemove = eGetById('task-sets-path-${id}-remove') {
    eRemove.onClick.listen((_) => remove());
    componentHandler().upgradeElement(eRow);
    eInput.focus();
  }

  void remove() {
    eRow.remove();
    dialog.list[id] = null;
    dialog.validate();
  }

  bool valid() => eInput.value.isNotEmpty;

  static String html(final int id) => '''
    <tr id="task-sets-path-${id}-row">
      <td>
        <div class="mdl-textfield">
          <input id="task-sets-path-${id}-input" class=" mdl-textfield__input"
            type="text">
          <label for="task-sets-path-${id}-input" class="mdl-textfield__label">
            Путь к папке или файлу для обработки...
          </label>
        </div>
      </td>
      <td><button id="task-sets-path-${id}-remove"
          class="mdl-button mdl-button--icon mdl-button--colored">
          <i class="material-icons">remove</i>
        </button></td>
    </tr>
  ''';
}

class TaskSetsDialog {
  final DialogElement eDialog = eGetById('task-sets-dialog');
  final ButtonElement eOpen = eGetById('task-sets-open');
  final ButtonElement eClose = eGetById('task-sets-close');
  final ButtonElement eStart = eGetById('task-sets-start');
  final InputElement eName = eGetById('task-sets-name');
  final TableElement eTable = eGetById('task-sets-table');
  final ButtonElement ePath = eGetById('task-sets-path');
  final DivElement eLoader = eGetById('task-sets-loader');

  bool _loading = false;
  set loading(final bool b) {
    if (_loading == b) {
      return;
    }
    _loading = b;
    eLoader.hidden = !_loading;
    eClose.disabled = _loading;
    eStart.disabled = _loading;
    eName.disabled = _loading;
    ePath.disabled = _loading;
    for (final item in list) {
      if (item != null) {
        item.eInput.disabled = _loading;
        item.eRemove.disabled = _loading;
      }
    }
  }

  bool _valid = false;
  set valid(final bool b) {
    if (_valid == b) {
      return;
    }
    _valid = b;
    eStart.disabled = !_valid;
  }

  final list = <TaskSetsPath>[];

  void reset() {
    eDialog.close();
    for (final path in list) {
      if (path != null) {
        path.remove();
      }
    }
    eName.value = '';
    pathAdd();
    loading = false;
  }

  void start() {
    loading = true;
    final value = {
      'name': eName.value,
      'path': list
          .where((e) => e != null)
          .map((e) => e.eInput.value)
          .where((e) => e.isNotEmpty)
          .toList()
    };
    App().requestOnce('${wwwTaskNew}${json.encode(value)}').then((msg) {
      final t = App().taskView.add(int.tryParse(msg));
      t.eName.innerText = value['name'];
      t.iState = 0;
      t.iErrors = 0;
      t.iFiles = 0;
      reset();
      App().taskView.update();
    });
  }

  void validate() {
    var b = false;
    for (final path in list) {
      if (path != null) {
        if (path.valid()) {
          b = true;
        }
      }
    }
    if (eName.value.isNotEmpty) {
      valid = b;
    } else {
      valid = false;
    }
  }

  void pathAdd() {
    var id = list.indexOf(null);
    if (id == -1) {
      id = list.length;
      list.add(null);
    }
    eTable.appendHtml(TaskSetsPath.html(id), validator: _htmlValidator);
    list[id] = TaskSetsPath(id, this);
    list[id].eInput.onInput.listen((_) => validate());
  }

  TaskSetsDialog._init() {
    eClose.onClick.listen((_) => eDialog.close());
    eStart.onClick.listen((_) => start());
    eOpen.onClick.listen((_) => eDialog.showModal());
    ePath.onClick.listen((_) => pathAdd());
    eName.onInput.listen((_) => validate());
    pathAdd();
  }

  static TaskSetsDialog _instance;
  factory TaskSetsDialog() =>
      (_instance) ?? (_instance = TaskSetsDialog._init());
}

class TaskDetails {}

class TaskDetailsDialog {
  final DialogElement eDialog = eGetById('task-details-dialog');
  final ButtonElement eClose = eGetById('task-details-close');
  final DivElement eContent = eGetById('task-details-content');
  TaskDetails task;

  show(final TaskDetails _task) {
    /// TODO: обновление состояния задачи
    task = _task;
    componentHandler().upgradeElement(eContent);
    eDialog.showModal();
  }

  TaskDetailsDialog._init() {
    eClose.onClick.listen((_) {
      /// TODO: отвязка от подробностей задачи
      eDialog.close();
    });
  }

  static TaskDetailsDialog _instance;
  factory TaskDetailsDialog() =>
      (_instance) ?? (_instance = TaskDetailsDialog._init());
}

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
    if (_iFiles <= 0) {
      eFiles.attributes.remove('data-badge');
    } else if (_iFiles >= 1000) {
      eFiles.attributes['data-badge'] = '...';
    } else {
      eFiles.attributes['data-badge'] = _iFiles.toString();
    }
  }

  void update() {}

  TaskCard(this.id, final TaskViewSection section)
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
      section.list.remove(id);
    });
    componentHandler().upgradeElement(eCard);
  }

  static String html(final int id) => '''
    <div id="task-${id}-card" hidden
      class="mdl-card mdl-shadow--2dp mdl-cell mdl-cell--6-col mdl-cell--8-col-tablet">
      <div class="mdl-card__title">
        <h2 class="mdl-card__title-text">Задача</h2>
      </div>
      <div class="mdl-card__supporting-text">
        <p>
          Название:
          <strong id="task-${id}-name"></strong>
        </p>
        <p>
          Состояние:
          <strong id="task-${id}-state"></strong>
        </p>
      </div>
      <div class="mdl-card__actions mdl-card--border">
        <button id="task-${id}-report"
          class="mdl-button mdl-button--colored mdl-button--raised" disabled>
          Отчёт
        </button>
        <button id="task-${id}-errors"
          class="mdl-button mdl-button--colored mdl-badge mdl-badge--overlap">
          Ошибки
        </button>
        <button id="task-${id}-files"
          class="mdl-button mdl-button--colored mdl-badge mdl-badge--overlap">
          Файлы
        </button>
      </div>
      <div class="mdl-card__menu">
        <button id="task-${id}-launch"
          class="mdl-button mdl-button--icon mdl-button--colored task-btn-details">
          <i class="material-icons">launch</i>
        </button>
        <button id="task-${id}-close"
          class="mdl-button mdl-button--icon">
          <i class="material-icons">close</i>
        </button>
      </div>
    </div>
  ''';
}

class TaskViewSection {
  final Element eSection = eGetById('task-view-section');
  final Element eLoader = eGetById('task-view-loader');

  final list = <int, TaskCard>{};

  bool _loading = true;
  set loading(final bool b) {
    if (_loading == b) {
      return;
    }
    _loading = b;
    eLoader.hidden = !_loading;
  }

  TaskCard add(final int id) {
    eSection.appendHtml(TaskCard.html(id), validator: _htmlValidator);
    return list[id] = TaskCard(id, this);
  }

  void update() {
    list.forEach((k, v) => v.hidden = false);
    loading = false;
  }

  TaskViewSection._init() {
    Future(() {
      App().requestOnce(wwwTaskViewUpdate).then((msg) {
        final items = json.decode(msg);
        for (final item in items) {
          final t = add(item['id']);
          t.eName.innerText = item['name'];
          t.iState = item['state'];
          t.iErrors = item['errors'];
          t.iFiles = item['files'];
        }
        update();

        /// TODO: получение данных о задачах
      });
      App().waitMsgAll(wwwTaskUpdates).listen((msg) {
        final items = json.decode(msg.s);
        for (final item in items) {
          final t = list[item['id']];
          if (t != null) {
            t.iState = item['state'];
            t.iErrors = item['errors'];
            t.iFiles = item['files'];
          }
        }
      });
    });
  }

  static TaskViewSection _instance;
  factory TaskViewSection() =>
      (_instance) ?? (_instance = TaskViewSection._init());
}

class App {
  /// Сокет для связи с сервером
  final socket = WebSocket('ws://${uri.host}:80/ws');
  final socketCompleter = Completer();
  // WebSocket('ws://${uri.host}:${uri.port}');
  SocketWrapper wrapper;

  final DivElement eTitleSpinner = eGetById('page-title-spinner');
  final SpanElement eTitleText = eGetById('page-title-text');

  final taskSets = TaskSetsDialog();
  final TaskViewSection taskView = TaskViewSection();

  void onOpen() {
    eTitleText.innerText = 'Пункт приёма стеклотары.';
    eTitleSpinner.hidden = true;
    socketCompleter.complete();
  }

  void onClose() {
    eTitleText.innerText = 'Меня отключили и потеряли...';
  }

  void onMessage(final String msg) {
    print('recv: $msg');
    wrapper.recv(msg);
  }

  Future<SocketWrapperResponse> Function(String msgBegin) get waitMsg =>
      wrapper.waitMsg;
  Stream<SocketWrapperResponse> Function(String msgBegin) get waitMsgAll =>
      wrapper.waitMsgAll;
  Future<String> Function(String msg) get requestOnce => wrapper.requestOnce;
  Stream<String> Function(String msg) get requestSubscribe =>
      wrapper.requestSubscribe;

  App.init() {
    wrapper = SocketWrapper((msg) => socket.sendString(msg),
        signal: socketCompleter.future);
    socket.onOpen.listen((_) => onOpen());
    socket.onClose.listen((_) => onClose());
    socket.onMessage.listen((_) => onMessage(_.data));
  }
  static App instance;
  factory App() => (instance) ?? (instance = App.init());
}

Future main() async {
  // FictiveApp();
  App();

  ioc.Container.bindModules([CoreComponentsModule()]);
  await componentHandler().upgrade();

  final td = TaskDetailsDialog();
  final List<ButtonElement> btnsTaskDetails =
      document.querySelectorAll<ButtonElement>('.task-btn-details');
  for (var btn in btnsTaskDetails) {
    btn.onClick.listen((_) {
      td.eDialog.showModal();
    });
  }
}
