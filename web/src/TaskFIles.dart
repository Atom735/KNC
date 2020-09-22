import 'dart:convert';
import 'dart:html';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:knc/knc.dart';
import 'package:mdc_web/mdc_web.dart';

import 'CardTask.dart';
import 'FileLas.dart';
import 'misc.dart';

class TaskFiles {
  Element e;
  String lastTask;
  String lastFilter;

  String fileOpenQ;

  void openFile(final JOneFileDataa file) {
    print(file.path + (fileOpenQ != null ? ('?' + fileOpenQ) : ''));
    FileLas().open(file, fileOpenQ).then((_b) {
      if (_b) {
        var b = false;
        final _ps = p.joinAll(
            p.windows.split(file.path).where((e) => (b = (b || e == 'tasks'))));
        window.history
            .pushState('data', 'title', '/app/file/$_ps/*?*/$fileOpenQ');
        uri = Uri.parse(document.baseUri);
        uriPaths = uri.pathSegments;
      }
      fileOpenQ = null;
    });
  }

  void close() {
    if (e != null) {
      e.classes.add('a-closing');
    }
    fileOpenQ = null;
  }

  Future<bool> open(final String task, [String filter]) async {
    filter ??= '';
    fileOpenQ = null;
    print(filter);
    final _msg = await requestOnce('$wwwTaskGetFiles$task');
    if (_msg.isEmpty) {
      return false;
    }
    if ((e != null && !e.classes.contains('task-$task')) ||
        (lastTask != task) ||
        (lastFilter != filter)) {
      e?.remove();
      e = null;
      lastTask = task;
      lastFilter = filter;
    }
    if (e == null) {
      e = document.createElement('main')
        ..classes.addAll(['task-files', 'a-opening', 'task-$task'])
        ..append(DivElement()
          ..classes.add('tbl-head')
          ..classes.add('mdc-top-app-bar--fixed-adjust')
          ..append(SpanElement()
            ..classes.add('tbl-index')
            ..innerText = '#')
          ..append(SpanElement()
            ..classes.add('tbl-name')
            ..innerText = 'Название файла')
          ..append(SpanElement()
            ..classes.add('tbl-type')
            ..innerText = 'Тип')
          ..append(SpanElement()
            ..classes.add('tbl-size')
            ..innerText = 'Размер')
          ..append(SpanElement()
            ..classes.add('tbl-origin')
            ..innerText = 'Оригинал')
          ..append(SpanElement()
            ..classes.add('tbl-path')
            ..innerText = 'Рабочая копия')
          ..append(SpanElement()
            ..classes.add('tbl-encode')
            ..innerText = 'Кодировка')
          ..append(SpanElement()
            ..classes.add('tbl-notes')
            ..innerText = 'Заметки')
          ..append(SpanElement()
            ..classes.add('tbl-well')
            ..innerText = 'Скважина')
          ..append(SpanElement()
            ..classes.add('tbl-c-name')
            ..innerText = 'ГИС')
          ..append(SpanElement()
            ..classes.add('tbl-c-strt')
            ..innerText = 'Начало')
          ..append(SpanElement()
            ..classes.add('tbl-c-stop')
            ..innerText = 'Конец')
          ..append(SpanElement()
            ..classes.add('tbl-c-step')
            ..innerText = 'Шаг'));
      e.addEventListener('animationend', (event) {
        if ((event as AnimationEvent).animationName == 'slideout') {
          e.hidden = true;
          e.classes.remove('a-closing');
        } else if ((event as AnimationEvent).animationName == 'slidein') {
          e.hidden = false;
          e.classes.remove('a-opening');
        }
      });
    } else {
      e.classes.add('a-opening');
      e.hidden = false;
    }
    closeAll('task-files');
    final f = (jsonDecode(_msg) as List)
        .map((e) => JOneFileDataa.byJson(e))
        .toList(growable: false);
    final _fL = f.length; //min(f.length, 100);

    for (var i = 0; i < _fL; i++) {
      final _i = f[i];
      if (filter != null &&
          ((filter.contains('e') &&
                  !filter.contains('w') &&
                  (_i.notes == null ||
                      _i.notes.isEmpty ||
                      _i.notesError == 0)) ||
              (filter.contains('w') &&
                  !filter.contains('e') &&
                  (_i.notes == null ||
                      _i.notes.isEmpty ||
                      _i.notesWarnings == 0)) ||
              (filter.contains('e') &&
                  filter.contains('w') &&
                  (_i.notes == null ||
                      _i.notes.isEmpty ||
                      (_i.notesError == 0 && _i.notesWarnings == 0))))) {
        continue;
      }
      final eRow = DivElement()
        ..onClick.listen((event) {
          if (event.ctrlKey) {
            openFile(_i);
          }
        })
        ..onKeyDown.listen((event) {
          if (event.keyCode == KeyCode.ENTER) {
            event.target.dispatchEvent(MouseEvent('click', ctrlKey: true));
          }
        })
        ..classes.add('tbl-row')
        ..append(SpanElement()
          ..attributes['tabindex'] = '0'
          ..classes.add('tbl-index')
          ..innerText = (i + 1).toString())
        ..append(SpanElement()
          ..attributes['tabindex'] = '0'
          ..classes.add('tbl-name')
          ..innerText = p.windows.basename(_i.origin))
        ..append(SpanElement()
          ..attributes['tabindex'] = '0'
          ..classes.add('tbl-type')
          ..innerText = _i.type
              .toString()
              .substring(_i.type.runtimeType.toString().length))
        ..append(SpanElement()
          ..attributes['tabindex'] = '0'
          ..classes.add('tbl-size')
          ..innerText = _i.size.toString())
        ..append(SpanElement()
          ..attributes['tabindex'] = '0'
          ..classes.add('tbl-origin')
          ..innerText = _i.origin)
        ..append(SpanElement()
          ..attributes['tabindex'] = '0'
          ..classes.add('tbl-path')
          ..innerText = _i.path.substring(_i.path.lastIndexOf('tasks')))
        ..append(SpanElement()
          ..attributes['tabindex'] = '0'
          ..classes.add('tbl-encode')
          ..innerText = _i.encode)
        ..append((_i.notes == null || _i.notes.isEmpty)
            ? (SpanElement()
              ..attributes['tabindex'] = '0'
              ..classes.add('tbl-notes'))
            : (SpanElement()
              ..attributes['tabindex'] = '0'
              ..classes.add('tbl-notes')
              ..append(SpanElement()
                ..classes.add('tbl-notes-count')
                ..innerText = _i.notes.length.toString())
              ..append(SpanElement()
                ..classes.add('tbl-notes-warn')
                ..innerText = _i.notesWarnings.toString())
              ..append(SpanElement()
                ..classes.add('tbl-notes-error')
                ..innerText = _i.notesError.toString())));

      if (_i.curves != null && _i.curves.isNotEmpty) {
        final c = _i.curves.first;
        eRow
          ..append(SpanElement()
            ..onClick.listen((event) {
              if (event.ctrlKey) {
                fileOpenQ = 'well=${c.well}';
              }
            })
            ..onKeyDown.listen((event) {
              if (event.keyCode == KeyCode.ENTER) {
                event.target.dispatchEvent(MouseEvent('click', ctrlKey: true));
              }
            })
            ..attributes['tabindex'] = '0'
            ..classes.add('tbl-well')
            ..innerText = c.well)
          ..append(SpanElement()
            ..onClick.listen((event) {
              if (event.ctrlKey) {
                fileOpenQ = 'well=${c.well}&curve=${c.name}';
              }
            })
            ..onKeyDown.listen((event) {
              if (event.keyCode == KeyCode.ENTER) {
                event.target.dispatchEvent(MouseEvent('click', ctrlKey: true));
              }
            })
            ..attributes['tabindex'] = '0'
            ..classes.add('tbl-c-name')
            ..innerText = c.name)
          ..append(SpanElement()
            ..onClick.listen((event) {
              if (event.ctrlKey) {
                fileOpenQ = 'well=${c.well}&curve=${c.name}&point=strt';
              }
            })
            ..onKeyDown.listen((event) {
              if (event.keyCode == KeyCode.ENTER) {
                event.target.dispatchEvent(MouseEvent('click', ctrlKey: true));
              }
            })
            ..attributes['tabindex'] = '0'
            ..classes.add('tbl-c-strt')
            ..innerText = c.strt)
          ..append(SpanElement()
            ..onClick.listen((event) {
              if (event.ctrlKey) {
                fileOpenQ = 'well=${c.well}&curve=${c.name}&point=stop';
              }
            })
            ..onKeyDown.listen((event) {
              if (event.keyCode == KeyCode.ENTER) {
                event.target.dispatchEvent(MouseEvent('click', ctrlKey: true));
              }
            })
            ..attributes['tabindex'] = '0'
            ..classes.add('tbl-c-stop')
            ..innerText = c.stop)
          ..append(SpanElement()
            ..attributes['tabindex'] = '0'
            ..classes.add('tbl-c-step')
            ..innerText = c.step);
        e.append(eRow);
        final _l = _i.curves.length;
        for (var j = 1; j < _l; j++) {
          final c = _i.curves[j];
          e.append(DivElement()
            ..onClick.listen((event) {
              if (event.ctrlKey) {
                openFile(_i);
              }
            })
            ..onKeyDown.listen((event) {
              if (event.keyCode == KeyCode.ENTER) {
                event.target.dispatchEvent(MouseEvent('click', ctrlKey: true));
              }
            })
            ..classes.add('tbl-row')
            ..append(SpanElement()..classes.add('tbl-up'))
            ..append(SpanElement()
              ..onClick.listen((event) {
                if (event.ctrlKey) {
                  fileOpenQ = 'well=${c.well}';
                }
              })
              ..onKeyDown.listen((event) {
                if (event.keyCode == KeyCode.ENTER) {
                  event.target
                      .dispatchEvent(MouseEvent('click', ctrlKey: true));
                }
              })
              ..attributes['tabindex'] = '0'
              ..classes.add('tbl-well')
              ..innerText = c.well)
            ..append(SpanElement()
              ..onClick.listen((event) {
                if (event.ctrlKey) {
                  fileOpenQ = 'well=${c.well}&curve=${c.name}';
                }
              })
              ..onKeyDown.listen((event) {
                if (event.keyCode == KeyCode.ENTER) {
                  event.target
                      .dispatchEvent(MouseEvent('click', ctrlKey: true));
                }
              })
              ..attributes['tabindex'] = '0'
              ..classes.add('tbl-c-name')
              ..innerText = c.name)
            ..append(SpanElement()
              ..onClick.listen((event) {
                if (event.ctrlKey) {
                  fileOpenQ = 'well=${c.well}&curve=${c.name}&point=strt';
                }
              })
              ..onKeyDown.listen((event) {
                if (event.keyCode == KeyCode.ENTER) {
                  event.target
                      .dispatchEvent(MouseEvent('click', ctrlKey: true));
                }
              })
              ..attributes['tabindex'] = '0'
              ..classes.add('tbl-c-strt')
              ..innerText = c.strt)
            ..append(SpanElement()
              ..onClick.listen((event) {
                if (event.ctrlKey) {
                  fileOpenQ = 'well=${c.well}&curve=${c.name}&point=stop';
                }
              })
              ..onKeyDown.listen((event) {
                if (event.keyCode == KeyCode.ENTER) {
                  event.target
                      .dispatchEvent(MouseEvent('click', ctrlKey: true));
                }
              })
              ..attributes['tabindex'] = '0'
              ..classes.add('tbl-c-stop')
              ..innerText = c.stop)
            ..append(SpanElement()
              ..onClick.listen((event) {
                if (event.ctrlKey) {
                  fileOpenQ = 'well=${c.well}&curve=${c.name}';
                }
              })
              ..onKeyDown.listen((event) {
                if (event.keyCode == KeyCode.ENTER) {
                  event.target
                      .dispatchEvent(MouseEvent('click', ctrlKey: true));
                }
              })
              ..attributes['tabindex'] = '0'
              ..classes.add('tbl-c-step')
              ..innerText = c.step));
        }
      } else {
        e.append(eRow);
      }
    }
    document.body.append(e);
    return true;
  }

  TaskFiles._init();
  static TaskFiles _instance;
  factory TaskFiles() => _instance ?? (_instance = TaskFiles._init());
}
