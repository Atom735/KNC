import 'dart:convert';
import 'dart:html';

import 'package:knc/knc.dart';
import 'package:m4d_components/m4d_components.dart';

import 'App.dart';
import 'HtmlGenerator.dart';
import 'misc.dart';

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

  static String htmlTemplateSrc;

  static String html(final int id) =>
      htmlGenFromSrc(htmlTemplateSrc, {'id': id});
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
  final ButtonElement eFastSet = eGetById('task-sets-fast-set');

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
      reset();
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
    eTable.appendHtml(TaskSetsPath.html(id), validator: htmlValidator);
    list[id] = TaskSetsPath(id, this);
    list[id].eInput.onInput.listen((_) => validate());
  }

  TaskSetsDialog._init() {
    eClose.onClick.listen((_) => eDialog.close());
    eStart.onClick.listen((_) => start());
    eOpen.onClick.listen((_) => eDialog.showModal());
    ePath.onClick.listen((_) => pathAdd());
    eName.onInput.listen((_) => validate());
    if (eFastSet != null) {
      eFastSet.onClick.listen((_) {
        eName.value = r'Искринское м-е';
        componentHandler().upgradeElement(eName);
        componentHandler().upgradeElement(
            list.firstWhere((element) => element != null).eInput
              ..value = r'D:\Искринское м-е');
        validate();
      });
    }
    pathAdd();
  }

  static TaskSetsDialog _instance;
  factory TaskSetsDialog() =>
      (_instance) ?? (_instance = TaskSetsDialog._init());
}
