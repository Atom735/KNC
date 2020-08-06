import 'dart:html';

import 'package:m4d_components/m4d_components.dart';

import 'HtmlGenerator.dart';
import 'TaskErrors.dart';
import 'TaskFIles.dart';
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
