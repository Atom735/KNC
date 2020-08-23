import 'dart:html';
import 'dart:convert';

import 'package:knc/OneFile.dart';
import 'package:knc/www.dart';
import 'package:mdc_web/mdc_web.dart';

import 'App.dart';
import 'TaskCard.dart';
import 'HtmlGenerator.dart';
import 'misc.dart';

class MyTaskFilesDialog extends MDCDialog {
  MyTaskCard _task;
  final MDCLinearProgress eLinearProgress =
      MDCLinearProgress(eGetById('my-task-files-dialog-linear-progress'));
  final ButtonElement eBtnLoad = eGetById('my-task-files-dialog-load');
  final Element eTitle;
  final Element eContent;

  final files = <OneFileData>[];

  set task(MyTaskCard i) {
    if (i == null || i == _task) {
      return;
    }
    _task = i;
    files.clear();
    eContent.innerHtml = '';
    update();
  }

  bool _loading = false;
  set loading(final bool b) {
    if (_loading == b) {
      return;
    }
    _loading = b;
    if (_loading) {
      eLinearProgress.open();
    } else {
      eLinearProgress.close();
    }
  }

  void update() {
    if (files.length >= _task.iFiles) {
      return;
    }
    loading = true;
    eTitle.innerText =
        'Файлы [${_task.uid}] ${_task.sName} (${files.length}/${_task.iFiles})';
    App()
        .requestOnce('$wwwTaskGetFiles${_task.uid}:${files.length}')
        .then((msg) {
      final v = jsonDecode(msg);
      final id = v['task'];
      if (id != _task.uid) {
        return;
      }
      final vf = v['first'];
      final vd = v['data'] as List<Object>;
      if (files.length <= vf) {
        files.length = vf;
      }
      final vv = files.length - vf;
      if (vv <= vd.length) {
        final sb = vd.sublist(vv);
        print(sb);
        final f = sb.map((e) => OneFileData.byJson(e)).toList(growable: false);
        for (var item in f) {
          files.add(item);
          if (item.curves == null) {
            eContent.appendHtml('''
                    <tr class="mdc-data-table__row">
                      <th class="mdc-data-table__cell">${item.origin}</th>
                      <td class="mdc-data-table__cell">${item.path}</td>
                      <td class="mdc-data-table__cell mdc-data-table__cell--numeric">
                        ${item.size}</td>
                      <td class="mdc-data-table__cell">${item.encode}</td>
                      <td class="mdc-data-table__cell">${item.type}</td>
                      <td class="mdc-data-table__cell">${item.well}</td>
                      <td class="mdc-data-table__cell">-</td>
                      <td
                        class="mdc-data-table__cell mdc-data-table__cell--numeric">
                        -</td>
                      <td
                        class="mdc-data-table__cell mdc-data-table__cell--numeric">
                        -</td>
                      <td
                        class="mdc-data-table__cell mdc-data-table__cell--numeric">
                        -</td>
                    </tr>''');
          } else {
            for (var i = 0; i < item.curves.length; i++) {
              eContent.appendHtml('''
                    <tr class="mdc-data-table__row">
                      <th class="mdc-data-table__cell">${item.origin}</th>
                      <td class="mdc-data-table__cell">${item.path}</td>
                      <td class="mdc-data-table__cell mdc-data-table__cell--numeric">
                        ${item.size}</td>
                      <td class="mdc-data-table__cell">${item.encode}</td>
                      <td class="mdc-data-table__cell">${item.type}</td>
                      <td class="mdc-data-table__cell">${item.well}</td>
                      <td class="mdc-data-table__cell">$i:${item.curves[i].name}</td>
                      <td
                        class="mdc-data-table__cell mdc-data-table__cell--numeric">
                        ${item.curves[i].strt}</td>
                      <td
                        class="mdc-data-table__cell mdc-data-table__cell--numeric">
                        ${item.curves[i].stop}</td>
                      <td
                        class="mdc-data-table__cell mdc-data-table__cell--numeric">
                        ${item.curves[i].step}</td>
                    </tr>''');
            }
          }
          eTitle.innerText =
              'Файлы [${_task.uid}] ${_task.sName} (${files.length}/${_task.iFiles})';
        }
      }

      loading = false;
    });
  }

  MyTaskFilesDialog._init(Element root)
      : eTitle = root.querySelector('.mdc-dialog__title'),
        eContent =
            root.querySelector('.mdc-dialog__content .mdc-data-table__content'),
        super(root) {
    print('$runtimeType created: $hashCode');

    eBtnLoad.onClick.listen((_) => update());
  }

  static MyTaskFilesDialog _instance;
  factory MyTaskFilesDialog([final MyTaskCard task]) => (_instance) ??
      (_instance = MyTaskFilesDialog._init(eGetById('my-task-files-dialog')))
    ..task = task;
}

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
      final v = jsonDecode(s);
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
