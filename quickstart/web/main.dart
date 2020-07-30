import 'dart:html';

import 'package:m4d_core/m4d_ioc.dart' as ioc;
import 'package:m4d_components/m4d_components.dart';

/// webdev serve --auto refresh --debug --launch-in-chrome --log-requests

Element eGetById(final String id) => document.getElementById(id);

class TaskSetsPath {
  final int id;
  final TableRowElement eRow;
  final InputElement eInput;
  final ButtonElement eRemove;
  TaskSetsPath(this.id, final TaskSetsDialog dialog)
      : eRow = eGetById('task-sets-path-${id}-row'),
        eInput = eGetById('task-sets-path-${id}-input'),
        eRemove = eGetById('task-sets-path-${id}-remove') {
    eRemove.onClick.listen((_) {
      eRow.remove();
      dialog.list[id] = null;
      dialog.validate();
    });
    componentHandler().upgradeElement(eRow);
    eInput.focus();
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

  start() {
    loading = true;
    // TODO: отправка данных
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
    eTable.appendHtml(TaskSetsPath.html(id));
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
  int iState = 0;
  int iErrors = 0;
  int iFiles = 0;

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
    <div id="task-${id}-card"
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
          class="mdl-button mdl-button--colored mdl-badge mdl-badge--overlap"
          data-badge="0">
          Ошибки
        </button>
        <button id="task-${id}-files"
          class="mdl-button mdl-button--colored mdl-badge mdl-badge--overlap"
          data-badge="0">
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

  final list = <int, TaskCard>{};

  void add(final int id) {
    eSection.appendHtml(TaskCard.html(id));
    list[id] = TaskCard(id, this);
  }

  TaskViewSection._init() {
    /// TODO: получение данных о задачах
  }

  static TaskViewSection _instance;
  factory TaskViewSection() =>
      (_instance) ?? (_instance = TaskViewSection._init());
}

Future main() async {
  ioc.Container.bindModules([CoreComponentsModule()]);
  await componentHandler().upgrade();

  final td = TaskDetailsDialog();
  TaskSetsDialog();

  final List<ButtonElement> btnsTaskDetails =
      document.querySelectorAll<ButtonElement>('.task-btn-details');
  for (var btn in btnsTaskDetails) {
    btn.onClick.listen((_) {
      td.eDialog.showModal();
    });
  }
}
