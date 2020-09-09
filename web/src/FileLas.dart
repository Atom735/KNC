import 'dart:convert';
import 'dart:html';

import 'package:knc/knc.dart';

import 'misc.dart';

class FileLas {
  Element e;
  OneFileData oneFileData;
  List<String> fileData;

  Future<bool> open(OneFileData file, [final String query]) async {
    if (file == null || file.path == null) {
      return false;
    }
    print('try to open ${file.path}');

    /// Обновляем данные о файле
    if (oneFileData == null || !oneFileData.path.endsWith(file.path)) {
      final _msg = await requestOnce('$wwwGetOneFileData${file.path}');
      if (_msg.isEmpty) {
        return false;
      }

      oneFileData = OneFileData.byJsonFull(jsonDecode(_msg));
      file = oneFileData;
      e?.remove();
      fileData = LineSplitter.split(await requestOnce(
              '$wwwGetFileData${file.path}$msgRecordSeparator${file.encode}'))
          .toList(growable: false);
    }
    if (file.type != NOneFileDataType.las) {
      return false;
    }
    if (e == null) {
      e = document.createElement('main')
        ..classes.addAll(
            ['mdc-top-app-bar--fixed-adjust', 'opend-file', 'a-opening', 'las'])
        ..append(DivElement()
          ..classes.add('file-sets-bar')
          ..append(SpanElement()
            ..classes.add('file-sets')
            ..classes.add('size')
            ..innerText = '${file.size} байт')
          ..append(SpanElement()
            ..classes.add('file-sets')
            ..classes.add('notes')
            ..append(SpanElement()
              ..classes.add('file-sets-notes')
              ..classes.add('errors')
              ..innerText = file.notesError?.toString() ?? '0')
            ..append(SpanElement()
              ..classes.add('file-sets-notes')
              ..classes.add('warnings')
              ..innerText = file.notesWarnings?.toString() ?? '0'))
          ..append(
              SpanElement()..classes.add('file-sets')..classes.add('space'))
          ..append(SpanElement()
            ..classes.add('file-sets')
            ..classes.add('encode')
            ..innerText = file.encode)
          ..append(SpanElement()
            ..classes.add('file-sets')
            ..classes.add('type')
            ..innerText = file.type
                .toString()
                .substring(file.type.runtimeType.toString().length)));
      final _l = fileData.length;
      for (var i = 0; i < _l; i++) {
        final _lineData = fileData[i];
        final _notes =
            file.notes.where((e) => e.line == i + 1).toList(growable: false);
        print('$i');
        var _noteError = false;
        var _noteWarning = false;
        var _noteIgnore = false;
        var _noteSection = false;
        final _l = _notes.length;
        for (var j = 0; j < _l; j++) {
          _noteWarning |= _notes[j].text.startsWith('!W');
          _noteError |= _notes[j].text.startsWith('!E');
          _noteIgnore |= _notes[j].text.startsWith('!Pignore');
          _noteSection |= _notes[j].text.startsWith('!Psection');
          print(jsonEncode(_notes[j]));
        }

        final _eLine = DivElement()..classes.add('file-line');

        final _eLineIndex = DivElement()
          ..id = 'line-${i + 1}'
          ..classes.add('line-index')
          ..innerText = '${i + 1}';

        final _eLineData = PreElement()
          ..innerText = _lineData
          ..classes.add('line-data');

        if (_noteWarning) {
          _eLineData.classes.add('warning');
        }
        if (_noteError) {
          _eLineData.classes.add('error');
        }
        if (_noteSection) {
          _eLineData.classes.add('section');
        } else if (_noteIgnore) {
          _eLineData.classes.add('ignore');
        }

        _eLine..append(_eLineIndex)..append(_eLineData);

        if (_notes.isNotEmpty) {
          final _eLineNotes = DivElement()..classes.add('line-notes');

          for (var j = 0; j < _l; j++) {
            final _note = _notes[j].text;
            final _eNote = DivElement();
            if (_note.startsWith('!W')) {
              _eNote
                ..classes.add('line-notes-w')
                ..innerText = _note.substring(2);
            }
            if (_note.startsWith('!E')) {
              _eNote
                ..classes.add('line-notes-e')
                ..innerText = _note.substring(2);
            }
            if (_note.startsWith('!P')) {
              final _parses = _note.substring(2).split(msgRecordSeparator);
              _eNote.innerText = _parses.first;
              for (var k = 1; k < _parses.length; k++) {
                _eNote.append(SpanElement()
                  ..classes.add('line-notes-p')
                  ..innerText = _parses[k]);
              }
            }
            _eLineNotes.append(_eNote);
          }

          _eLine.append(_eLineNotes);
        }
        e.append(_eLine);
      }

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
    closeAll('opend-file');
    document.body.append(e);
    return true;
  }

  FileLas._init();
  static FileLas _instance;
  factory FileLas() => _instance ?? (_instance = FileLas._init());
}
