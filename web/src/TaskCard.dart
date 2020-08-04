import 'dart:html';

import 'package:m4d_components/m4d_components.dart';

import 'TaskViewSection.dart';
import 'misc.dart';

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
