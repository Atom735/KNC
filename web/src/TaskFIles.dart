import 'dart:convert';
import 'dart:html';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:knc/knc.dart';
import 'package:mdc_web/mdc_web.dart';

import 'CardTask.dart';
import 'misc.dart';

class TaskFiles {
  Element e;
  void close() {
    if (e != null) {
      e.classes.add('a-closing');
    }
  }

  Future<bool> open(final String task) async {
    final _msg = await requestOnce('$wwwTaskGetFiles$task');
    if (e != null && !e.classes.contains('task-$task')) {
      e.remove();
      e = null;
    }
    if (e == null) {
      e = document.createElement('main')
        ..classes.addAll(['task-files', 'a-opening', 'task-$task'])
        ..append(document.createElement('div')
          ..classes.add('tbl-head')
          ..classes.add('mdc-top-app-bar--fixed-adjust')
          ..append(document.createElement('span')
            ..classes.add('tbl-index')
            ..innerText = '#')
          ..append(document.createElement('span')
            ..classes.add('tbl-name')
            ..innerText = 'Название файла')
          ..append(document.createElement('span')
            ..classes.add('tbl-type')
            ..innerText = 'Тип')
          ..append(document.createElement('span')
            ..classes.add('tbl-size')
            ..innerText = 'Размер')
          ..append(document.createElement('span')
            ..classes.add('tbl-origin')
            ..innerText = 'Оригинал')
          ..append(document.createElement('span')
            ..classes.add('tbl-path')
            ..innerText = 'Рабочая копия')
          ..append(document.createElement('span')
            ..classes.add('tbl-encode')
            ..innerText = 'Кодировка')
          ..append(document.createElement('span')
            ..classes.add('tbl-notes')
            ..innerText = 'Заметки')
          ..append(document.createElement('span')
            ..classes.add('tbl-well')
            ..innerText = 'Скважина')
          ..append(document.createElement('span')
            ..classes.add('tbl-c-name')
            ..innerText = 'ГИС')
          ..append(document.createElement('span')
            ..classes.add('tbl-c-strt')
            ..innerText = 'Начало')
          ..append(document.createElement('span')
            ..classes.add('tbl-c-stop')
            ..innerText = 'Конец')
          ..append(document.createElement('span')
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
    if (_msg.isEmpty) {
      return false;
    } else {
      closeAll('task-files');
      final f = (jsonDecode(_msg) as List)
          .map((e) => OneFileData.byJson(e))
          .toList(growable: false);
      final _fL = min(f.length, 100);

      for (var i = 0; i < _fL; i++) {
        final _i = f[i];
        final eRow = document.createElement('div')
          ..classes.add('tbl-row')
          ..append(document.createElement('span')
            ..attributes['tabindex'] = '0'
            ..classes.add('tbl-index')
            ..innerText = (i + 1).toString())
          ..append(document.createElement('span')
            ..attributes['tabindex'] = '0'
            ..classes.add('tbl-name')
            ..innerText = p.windows.basename(_i.origin))
          ..append(document.createElement('span')
            ..attributes['tabindex'] = '0'
            ..classes.add('tbl-type')
            ..innerText =
                _i.type.toString().substring('NOneFileDataType.'.length))
          ..append(document.createElement('span')
            ..attributes['tabindex'] = '0'
            ..classes.add('tbl-size')
            ..innerText = _i.size.toString())
          ..append(document.createElement('span')
            ..attributes['tabindex'] = '0'
            ..classes.add('tbl-origin')
            ..innerText = _i.origin)
          ..append(document.createElement('span')
            ..attributes['tabindex'] = '0'
            ..classes.add('tbl-path')
            ..innerText = _i.path)
          ..append(document.createElement('span')
            ..attributes['tabindex'] = '0'
            ..classes.add('tbl-encode')
            ..innerText = _i.encode)
          ..append((_i.notes == null || _i.notes.isEmpty)
              ? (document.createElement('span')
                ..attributes['tabindex'] = '0'
                ..classes.add('tbl-notes'))
              : (document.createElement('span')
                ..attributes['tabindex'] = '0'
                ..classes.add('tbl-notes')
                ..append(document.createElement('span')
                  ..classes.add('tbl-notes-count')
                  ..innerText = _i.notes.length.toString())
                ..append(document.createElement('span')
                  ..classes.add('tbl-notes-warn')
                  ..innerText = _i.notesWarnings.toString())
                ..append(document.createElement('span')
                  ..classes.add('tbl-notes-error')
                  ..innerText = _i.notesError.toString())));

        if (_i.curves != null && _i.curves.isNotEmpty) {
          final c = _i.curves.first;
          eRow
            ..append(document.createElement('span')
              ..attributes['tabindex'] = '0'
              ..classes.add('tbl-well')
              ..innerText = _i.well)
            ..append(document.createElement('span')
              ..attributes['tabindex'] = '0'
              ..classes.add('tbl-c-name')
              ..innerText = c.name)
            ..append(document.createElement('span')
              ..attributes['tabindex'] = '0'
              ..classes.add('tbl-c-strt')
              ..innerText = c.strt)
            ..append(document.createElement('span')
              ..attributes['tabindex'] = '0'
              ..classes.add('tbl-c-stop')
              ..innerText = c.stop)
            ..append(document.createElement('span')
              ..attributes['tabindex'] = '0'
              ..classes.add('tbl-c-step')
              ..innerText = c.step);
          e.append(eRow);
          final _l = _i.curves.length;
          for (var j = 1; j < _l; j++) {
            final c = _i.curves[j];
            e.append(document.createElement('div')
              ..classes.add('tbl-row')
              ..append(document.createElement('span')..classes.add('tbl-up'))
              ..append(document.createElement('span')
                ..attributes['tabindex'] = '0'
                ..classes.add('tbl-well')
                ..innerText = _i.well)
              ..append(document.createElement('span')
                ..attributes['tabindex'] = '0'
                ..classes.add('tbl-c-name')
                ..innerText = c.name)
              ..append(document.createElement('span')
                ..attributes['tabindex'] = '0'
                ..classes.add('tbl-c-strt')
                ..innerText = c.strt)
              ..append(document.createElement('span')
                ..attributes['tabindex'] = '0'
                ..classes.add('tbl-c-stop')
                ..innerText = c.stop)
              ..append(document.createElement('span')
                ..attributes['tabindex'] = '0'
                ..classes.add('tbl-c-step')
                ..innerText = c.step));
          }
        }
      }
      document.body.append(e);
      return true;
    }
  }

  TaskFiles._init();
  static TaskFiles _instance;
  factory TaskFiles() => _instance ?? (_instance = TaskFiles._init());
}
