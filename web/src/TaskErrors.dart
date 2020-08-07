import 'dart:html';

import 'package:knc/www.dart';

import 'App.dart';
import 'ErrorFileDialog.dart';
import 'TaskCard.dart';
import 'misc.dart';

class TaskErrorsDialog {
  final DialogElement eDialog = eGetById('task-errors-dialog');
  final SpanElement eCounter = eGetById('task-errors-counter');
  final DivElement eContent = eGetById('task-errors-content');
  final ButtonElement eClose = eGetById('task-errors-close');
  final ButtonElement eLoad = eGetById('task-errors-load');
  final DivElement eSpinner = eGetById('task-errors-spinner');

  TaskCard cCard;
  final listOfErrors = <CErrorOnLine>[];
  final listOfErrorsButton = <ButtonElement>[];

  bool _loading = false;
  set loading(final bool b) {
    if (_loading == b) {
      return;
    }
    _loading = b;
    eSpinner.hidden = !_loading;
    eLoad.disabled = _loading;
  }

  void addAll(final List<CErrorOnLine> list) {
    listOfErrors.addAll(list);
    for (final item in list) {
      eContent.appendHtml(item.html);
      ButtonElement btn =
          (eContent.lastChild as Element).querySelector('button');
      btn.onClick.listen((_) => ErrorFileDialog().open(item));
      listOfErrorsButton.add(btn);
    }
    eCounter.innerText = '${listOfErrors.length}/${_iErrors}';
    loading = false;
    eLoad.disabled = listOfErrors.length >= _iErrors;
  }

  void update() {
    if (listOfErrors.length >= _iErrors) {
      return;
    }
    loading = true;
    App()
        .requestOnce('$wwwTaskGetErrors${cCard.id}:${listOfErrors.length}')
        .then((s) => addAll(CErrorOnLine.getByJsonString(s)));
  }

  var _iErrors = 0;
  set iErrors(final int i) {
    if (i == null || _iErrors == i) {
      return;
    }
    _iErrors = i;
    eCounter.innerText = '${listOfErrors.length}/${_iErrors}';
    eLoad.disabled = listOfErrors.length >= _iErrors || _loading;
  }

  void openByTaskCard(final TaskCard card) {
    cCard = card;
    cCard.errorsDialogOpend = true;
    update();
    eDialog.showModal();
  }

  void close() {
    eDialog.close();
    listOfErrors.clear();
    listOfErrorsButton.clear();
    cCard.errorsDialogOpend = false;
    cCard = null;
  }

  TaskErrorsDialog._init() {
    eClose.onClick.listen((_) => close());
    eLoad.onClick.listen((_) => update());
  }

  static TaskErrorsDialog _instance;
  factory TaskErrorsDialog() =>
      (_instance) ?? (_instance = TaskErrorsDialog._init());
}
