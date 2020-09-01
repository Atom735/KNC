import 'dart:async';
import 'dart:html';
import 'dart:convert';

import 'package:knc/knc.dart';
import 'package:mdc_web/mdc_web.dart';

import 'App.dart';
import 'CardTask.dart';
import 'misc.dart';

class MyTaskFilesDialog extends MDCDialog {
  CardTask _task;
  final MDCLinearProgress eLinearProgress =
      MDCLinearProgress(eGetById('my-task-files-dialog-linear-progress'));
  final ButtonElement eBtnLoad = eGetById('my-task-files-dialog-load');
  final Element eTitle;
  final Element eContent;
  final eTableRows = <TableRowElement>[];

  final files = <OneFileData>[];

  set task(CardTask i) {
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
    // if (files.length >= _task.iFiles) {
    //   return;
    // }
    // loading = true;
    // eTitle.innerText =
    //     'Файлы [${_task.uid}] ${_task.sName} (${files.length}/${_task.iFiles})';
    // App()
    //     .requestOnce('$wwwTaskGetFiles${_task.uid}:${files.length}')
    //     .then((msg) {
    //   final v = jsonDecode(msg);
    //   final id = v['task'];
    //   if (id != _task.uid) {
    //     return;
    //   }
    //   final vf = v['first'];
    //   final vd = v['data'] as List<Object>;
    //   if (files.length <= vf) {
    //     files.length = vf;
    //   }
    //   final vv = files.length - vf;
    //   if (vv <= vd.length) {
    //     final sb = vd.sublist(vv);
    //     print(sb);
    //     final f = sb.map((e) => OneFileData.byJson(e)).toList(growable: false);
    //     for (var item in f) {
    //       files.add(item);
    //       var eRow = TableRowElement();
    //       eRow.onClick.listen((_) => MyFileViewer(_task, item).open());
    //       eTableRows.add(eRow);
    //       eRow.classes.add('mdc-data-table__row');
    //       if (item.curves == null) {
    //         eRow.innerHtml = '''
    //                   <th class="mdc-data-table__cell">${item.origin}</th>
    //                   <td class="mdc-data-table__cell">${item.path}</td>
    //                   <td class="mdc-data-table__cell mdc-data-table__cell--numeric">
    //                     ${item.size}</td>
    //                   <td class="mdc-data-table__cell">${item.encode}</td>
    //                   <td class="mdc-data-table__cell">${item.type.toString().substring(item.type.runtimeType.toString().length)}</td>
    //                   <td class="mdc-data-table__cell mdc-data-table__cell--numeric">
    //                     ${item.errors != null ? item.errors.length : ""}</td>
    //                   <td class="mdc-data-table__cell mdc-data-table__cell--numeric">
    //                     ${item.warnings != null ? item.warnings.length : ""}</td>
    //                   <td class="mdc-data-table__cell">${item.well}</td>
    //                   <td class="mdc-data-table__cell"></td>
    //                   <td class="mdc-data-table__cell mdc-data-table__cell--numeric"></td>
    //                   <td class="mdc-data-table__cell mdc-data-table__cell--numeric"></td>
    //                   <td class="mdc-data-table__cell mdc-data-table__cell--numeric"></td>''';
    //       } else {
    //         for (var i = 0; i < item.curves.length; i++) {
    //           if (i != 0) {
    //             eContent.append(eRow);
    //             eRow = TableRowElement();
    //             eRow.onClick.listen((_) => MyFileViewer(_task, item).open());
    //             eTableRows.add(eRow);
    //             eRow.classes.add('mdc-data-table__row');
    //             eRow.classes.add('my-double');
    //           }
    //           if (item.errors != null) {
    //             eRow.classes.add('error');
    //           } else if (item.warnings != null) {
    //             eRow.classes.add('warning');
    //           }
    //           eRow.innerHtml = '''
    //                   <th class="mdc-data-table__cell">${i == 0 ? item.origin : ""}</th>
    //                   <td class="mdc-data-table__cell">${i == 0 ? item.path : ""}</td>
    //                   <td class="mdc-data-table__cell mdc-data-table__cell--numeric">
    //                     ${i == 0 ? item.size : ""}</td>
    //                   <td class="mdc-data-table__cell">${i == 0 ? item.encode : ""}</td>
    //                   <td class="mdc-data-table__cell">${i == 0 ? item.type.toString().substring(item.type.runtimeType.toString().length) : ""}</td>
    //                   <td class="mdc-data-table__cell mdc-data-table__cell--numeric">
    //                     ${i == 0 && item.errors != null ? item.errors.length : ""}</td>
    //                   <td class="mdc-data-table__cell mdc-data-table__cell--numeric">
    //                     ${i == 0 && item.warnings != null ? item.warnings.length : ""}</td>
    //                   <td class="mdc-data-table__cell">${i == 0 ? item.well : ""}</td>
    //                   <td class="mdc-data-table__cell">$i:${item.curves[i].name}</td>
    //                   <td
    //                     class="mdc-data-table__cell mdc-data-table__cell--numeric">
    //                     ${item.curves[i].strt}</td>
    //                   <td
    //                     class="mdc-data-table__cell mdc-data-table__cell--numeric">
    //                     ${item.curves[i].stop}</td>
    //                   <td
    //                     class="mdc-data-table__cell mdc-data-table__cell--numeric">
    //                     ${item.curves[i].step}</td>''';
    //         }
    //       }
    //       eContent.append(eRow);
    //     }
    //     eTitle.innerText =
    //         'Файлы [${_task.uid}] ${_task.sName} (${files.length}/${_task.iFiles})';
    //   }

    //   loading = false;
    // });
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
  factory MyTaskFilesDialog([final CardTask task]) => (_instance) ??
      (_instance = MyTaskFilesDialog._init(eGetById('my-task-files-dialog')))
    ..task = task;
}

class MyFileViewer extends MDCDialog {
  final MDCLinearProgress eLinearProgress =
      MDCLinearProgress(eGetById('my-files-dialog-linear-progress'));
  final ButtonElement eBtnUpdate = eGetById('my-files-dialog-update');
  final Element eTitle;
  final Element eContent = eGetById('my-files-dialog-content');
  final Element eErrors = eGetById('my-files-dialog-errors');

  CardTask _task;
  OneFileData _file;
  String _fileData;
  void update() {
    // if (_file.errors != null) {
    //   for (var item in _file.errors) {
    //     eErrors.appendHtml('''
    //           <a class="error" href="#my-file-line-${item.line}">
    //             (${item.line}:${item.column}) ${item.text}
    //           </a>
    //           ''');
    //   }
    // }
    // if (_file.warnings != null) {
    //   for (var item in _file.warnings) {
    //     eErrors.appendHtml('''
    //           <a class="warning" href="#my-file-line-${item.line}">
    //             (${item.line}:${item.column}) ${item.text}
    //           </a>
    //           ''');
    //   }
    // }

    // final lines = LineSplitter().convert(_fileData);

    // for (var i = 0; i < lines.length; i++) {
    //   final errors = _file.errors?.where((e) => e.line == i + 1);
    //   final warnings = _file.warnings?.where((e) => e.line == i + 1);
    //   final s = StringBuffer();
    //   final ignore = (errors == null || errors.isEmpty) &&
    //       warnings != null &&
    //       warnings.isNotEmpty &&
    //       warnings.length == 1 &&
    //       warnings.first.text == 'проигнорированная строка';
    //   s.write('<div id="my-file-line-${i + 1}" class="line');
    //   if (ignore) {
    //     s.write(' ignore">');
    //   } else {
    //     s.write(
    //         '${errors != null && errors.isNotEmpty ? " error" : ""}${warnings != null && warnings.isNotEmpty ? " warning" : ""}">');
    //   }
    //   s.writeln(
    //       '<div class="data"><div>${i + 1}:</div><div>${lines[i]}</div></div>');
    //   if (!ignore) {
    //     if ((errors != null && errors.isNotEmpty) ||
    //         (warnings != null && warnings.isNotEmpty)) {
    //       s.writeln('<div class="errors">');
    //       if (errors != null && errors.isNotEmpty) {
    //         errors.forEach((e) {
    //           s.write('''
    //           <div class="error">
    //             <div>
    //               (${e.line}:${e.column}) ${e.text}
    //             </div>
    //           </div>
    //           ''');
    //         });
    //       }
    //       if (warnings != null && warnings.isNotEmpty) {
    //         warnings.forEach((e) {
    //           s.write('''
    //           <div class="warning">
    //             <div>
    //               (${e.line}:${e.column}) ${e.text}
    //             </div>
    //           </div>
    //         ''');
    //         });
    //       }
    //       s.writeln('</div>');
    //     }
    //   }
    //   s.writeln('</div>');
    //   eContent.appendHtml(s.toString());
    // }
    // loading = false;
  }

  set file(OneFileData i) {
    // if (i == null || i == _file) {
    //   return;
    // }
    // _file = i;
    // eContent.innerHtml = '';
    // eErrors.innerHtml = '';
    // loading = true;
    // Future.wait([
    //   (_file.warnings.isNotEmpty && _file.warnings[0] == null) ||
    //           (_file.errors.isNotEmpty && _file.errors[0] == null)
    //       ? App()
    //           .requestOnce('$wwwFileNotes${_task.uid}:${_file.path}')
    //           .then((msg) {
    //           _file.updateErrorsByJson(jsonDecode(msg));
    //         })
    //       : null,
    //   App()
    //       .requestOnce('$wwwGetFileData${_file.path}')
    //       .then((msg) => _fileData = msg)
    // ]).then((_) => update());
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

  MyFileViewer._init(Element root)
      : eTitle = root.querySelector('.mdc-dialog__title'),
        super(root) {
    print('$runtimeType created: $hashCode');
  }

  static MyFileViewer _instance;
  factory MyFileViewer([final CardTask task, final OneFileData file]) =>
      (_instance) ??
          (_instance = MyFileViewer._init(eGetById('my-files-dialog')))
        .._task = task
        ..file = file;
}
