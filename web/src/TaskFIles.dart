import 'dart:html';

import 'package:knc/www.dart';

import 'App.dart';
import 'TaskCard.dart';
import 'misc.dart';

class TaskFilesDialog {
  final DialogElement eDialog = eGetById('task-files-dialog');
  final SpanElement eCounter = eGetById('task-files-counter');
  final DivElement eContent = eGetById('task-files-content');
  final ButtonElement eClose = eGetById('task-files-close');
  final ButtonElement eLoad = eGetById('task-files-load');
  final DivElement eSpinner = eGetById('task-files-spinner');

  TaskCard cCard;
  final listOfFiles = <C_File>[];

  bool _loading = false;
  set loading(final bool b) {
    if (_loading == b) {
      return;
    }
    _loading = b;
    eSpinner.hidden = !_loading;
    eLoad.disabled = _loading;
  }

  void addAll(final List<C_File> list) {
    listOfFiles.addAll(list);
    for (final item in list) {
      eContent.appendHtml(item.html);
    }
    eCounter.innerText = '${listOfFiles.length}/${_iFiles}';
    loading = false;
    eLoad.disabled = listOfFiles.length >= _iFiles;
  }

  void update() {
    if (listOfFiles.length >= _iFiles) {
      return;
    }
    loading = true;
    App()
        .requestOnce('$wwwTaskGetFiles${cCard.id}:${listOfFiles.length}')
        .then((s) => addAll(C_File.getByJsonString(s)));
  }

  var _iFiles = 0;
  set iFiles(final int i) {
    if (i == null || _iFiles == i) {
      return;
    }
    _iFiles = i;
    eCounter.innerText = '${listOfFiles.length}/${_iFiles}';
    eLoad.disabled = listOfFiles.length >= _iFiles || _loading;
  }

  void openByTaskCard(final TaskCard card) {
    cCard = card;
    cCard.errorsDialogOpend = true;
    update();
    eDialog.showModal();
  }

  void close() {
    eDialog.close();
    cCard.errorsDialogOpend = false;
    cCard = null;
  }

  TaskFilesDialog._init() {
    eClose.onClick.listen((_) => close());
    eLoad.onClick.listen((_) => update());
  }

  static TaskFilesDialog _instance;
  factory TaskFilesDialog() =>
      (_instance) ?? (_instance = TaskFilesDialog._init());
}
