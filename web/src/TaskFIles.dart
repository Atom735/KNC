import 'dart:html';
import 'dart:convert' as c;

import 'package:knc/www.dart';

import 'App.dart';
import 'TaskCard.dart';
import 'HtmlGenerator.dart';
import 'misc.dart';

class LasFileDetails {
  static String htmlTemplateSrc;
}

class InkFileDetails {
  static String htmlTemplateSrc;
}

class TaskFilesDialog {
  final DialogElement eDialog = eGetById('task-files-dialog');
  final SpanElement eCounter = eGetById('task-files-counter');
  final DivElement eContent = eGetById('task-files-content');
  final ButtonElement eClose = eGetById('task-files-close');
  final ButtonElement eLoad = eGetById('task-files-load');
  final DivElement eSpinner = eGetById('task-files-spinner');

  TaskCard cCard;
  final listOfFiles = <dynamic>[];

  bool _loading = false;
  set loading(final bool b) {
    if (_loading == b) {
      return;
    }
    _loading = b;
    eSpinner.hidden = !_loading;
    eLoad.disabled = _loading;
  }

  void addAll(final List<dynamic> list) {
    listOfFiles.addAll(list);
    for (final item in list) {
      if (item['type'] == 'las') {
        eContent
            .appendHtml(htmlGenFromSrc(LasFileDetails.htmlTemplateSrc, item));
      } else if (item['type'] == 'ink') {
        eContent
            .appendHtml(htmlGenFromSrc(InkFileDetails.htmlTemplateSrc, item));
      }
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
        .then((s) {
      final v = c.json.decode(s);
      if (v is Map) {
        addAll([v]);
      } else if (v is List) {
        addAll(v);
      }
    });
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
    cCard.filesDialogOpend = true;
    update();
    eDialog.showModal();
  }

  void close() {
    eDialog.close();
    cCard.filesDialogOpend = false;
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
