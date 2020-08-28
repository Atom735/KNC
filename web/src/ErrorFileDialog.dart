import 'dart:convert';
import 'dart:html';

import 'package:knc/knc.dart';
import 'package:path/path.dart' as p;

import 'App.dart';
import 'misc.dart';

class ErrorFileDialog {
  final DialogElement eDialog = eGetById('file-err-dialog');
  final Element eTitle = eGetById('file-err-title');
  final ButtonElement eClose = eGetById('file-err-close');
  final Element ePath = eGetById('file-err-path');
  final Element eContent = eGetById('file-err-content');
  final Element eLoader = eGetById('file-err-loader');
  final Element eErrors = eGetById('file-err-errors');

  CErrorOnLine _err;

  void close() {
    eContent.innerHtml = '';
    eErrors.innerHtml = '';
    eDialog.close();
  }

  void open(final CErrorOnLine err) {
    _err = err;

    eTitle.innerText = p.windows.basename(_err.path);
    ePath.innerText = _err.path;

    eErrors.appendHtml(_err.html2);
    eLoader.hidden = false;
    App().requestOnce('$wwwGetFileData${_err.path}').then((data) {
      final lines = LineSplitter.split(data);
      var iLine = 0;
      for (var line in lines) {
        iLine += 1;
        eContent.appendHtml('''
          <p class="file-err-line ${_err.errors.any((e) => e.line == iLine) ? 'error' : ''}"><span id="file-err-line-$iLine"></span>${htmlEscape.convert(line)}</p>
        ''');
      }
      eLoader.hidden = true;
    });
    eDialog.showModal();
  }

  ErrorFileDialog._init() {
    eClose.onClick.listen((_) => close());
  }

  static ErrorFileDialog _instance;
  factory ErrorFileDialog() =>
      (_instance) ?? (_instance = ErrorFileDialog._init());
}
