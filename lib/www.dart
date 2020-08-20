import 'dart:convert' as c;

import 'package:crypto/crypto.dart' show sha256;

import 'ArchiverOtput.dart';
import 'errors.dart';

const wwwPort = 0xC000;

/// Клиент отправляет серверу запрос на обновление данных всех задач
const wwwTaskViewUpdate = 'taskview;';

/// Клиент отправляет серверу запрос на новую задачу
const wwwTaskNew = 'tasknew;';

/// Подписка на обновления состояния задачи, далее идёт айди задачи
const wwwTaskUpdates = 'taskupdates;';

/// Запрос на получение ошибок
const wwwTaskGetErrors = 'taskgeterros;';

/// Запрос на получение обработанных файлов
const wwwTaskGetFiles = 'taskgetfiles;';

/// Запрос на получение данных файла
const wwwGetFileData = 'getfiledata;';

/// Закрыть подписку на обновления
const wwwStreamClose = 'streamclose;';

/// Отправка данных для входа
const wwwSignIn = 'signin;';

/// Отправка данных для регистрации
const wwwRegistration = 'registrtion;';

const signatureDoc = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1];
const signatureZip = [
  [0x50, 0x4B, 0x03, 0x04],
  [0x50, 0x4B, 0x05, 0x06],
  [0x50, 0x4B, 0x07, 0x08]
];

bool signatureBegining(final List<int> data, final List<int> signature) {
  if (data.length < signature.length) {
    return false;
  }
  for (var i = 0; i < signature.length; i++) {
    if (data[i] != signatureDoc[i]) {
      return false;
    }
  }
  return true;
}

enum NTaskState {
  initialization,
  searchFiles,
  workFiles,
  generateTable,
  waitForCorrectErrors,
  reworkErrors,
  completed,
}

String passwordEncode(final String pass) => sha256.convert([
      ...'0x834^'.codeUnits,
      ...pass.codeUnits,
      ...'x12kdasdj'.codeUnits
    ]).toString();

class WWW_TaskSettings {
  final String name;
  static const def_name = '@unnamed';

  final List<String> path;
  static const def_path = [r'D:\Искринское м-е'];

  /// Настройки расширения для архивных файлов
  final List<String> ext_ar;
  static const def_ext_ar = ['.zip', '.rar'];

  /// Настройки расширения для файлов LAS и Инклинометрией
  final List<String> ext_files;
  static const def_ext_files = ['.las', '.doc', '.docx', '.txt', '.dbf'];

  /// Максимальный размер вскрываемого архива в байтах
  ///
  /// Для задания значения можно использовать постфиксы:
  /// * `k` = КилоБайты
  /// * `m` = МегаБайты = `kk`
  /// * `g` = ГигаБайты = `kkk`
  ///
  /// `0` - для всех архивов
  ///
  /// По умолчанию 1Gb
  final int maxsize_ar;
  static const def_maxsize_ar = 1024 * 1024 * 1024;

  /// Максимальный глубина прохода по архивам
  /// * `-1` - для бесконечной вложенности (По умолчанию)
  /// * `0` - для отбрасывания всех архивов
  /// * `1` - для входа на один уровень архива
  final int maxdepth_ar;
  static const def_maxdepth_ar = -1;

  WWW_TaskSettings(
      {this.name = def_name,
      this.path = def_path,
      this.ext_ar = def_ext_ar,
      this.ext_files = def_ext_files,
      this.maxsize_ar = def_maxsize_ar,
      this.maxdepth_ar = def_maxdepth_ar});

  WWW_TaskSettings.fromJson(dynamic json)
      : name = json['name'] ?? def_name,
        path = ((json['path'] ?? def_path) as Iterable)
            .map((e) => e as String)
            .toList(growable: false),
        ext_ar = ((json['ext_ar'] ?? def_ext_ar) as Iterable)
            .map((e) => e as String)
            .toList(growable: false),
        ext_files = ((json['ext_las'] ?? def_ext_files) as Iterable)
            .map((e) => e as String)
            .toList(growable: false),
        maxsize_ar = json['maxsize_ar'] ?? def_maxsize_ar,
        maxdepth_ar = json['maxdepth_ar'] ?? def_maxdepth_ar;

  Map get json => {
        'name': name,
        'path': path,
        'ext_ar': ext_ar,
        'ext_las': ext_files,
        'maxsize_ar': maxsize_ar,
        'maxdepth_ar': maxdepth_ar
      };
}

class CLasFileSub {
  final bool added;
  final String mnem;
  final double strt;
  final double stop;

  CLasFileSub(this.added, this.mnem, this.strt, this.stop);
  CLasFileSub.fromJson(final dynamic json)
      : added = json['added'],
        mnem = json['mnem'],
        strt = (json['strt'] as num).toDouble(),
        stop = (json['stop'] as num).toDouble();
  dynamic toJson() =>
      {'added': added, 'mnem': mnem, 'strt': strt, 'stop': stop};
}

abstract class C_File {
  final String origin;
  final String path;
  final String well;

  dynamic toJson();

  C_File(this.origin, this.path, this.well);
  C_File.fromJson(final dynamic json)
      : origin = json['origin'],
        path = json['path'],
        well = json['well'];

  static List<C_File> getByJsonString(String str) {
    final v = c.json.decode(str);
    if (v is Map) {
      switch (v['type']) {
        case 'las':
          return [CLasFile.fromJson(v)];
        case 'ink':
          return [CInkFile.fromJson(v)];
        default:
      }
    } else if (v is List) {
      return v
          .map<C_File>((e) => e['type'] == 'las'
              ? CLasFile.fromJson(e)
              : e['type'] == 'ink' ? CInkFile.fromJson(e) : null)
          .toList(growable: false);
    }
    return [];
  }
}

class CLasFile extends C_File {
  final List<CLasFileSub> subs;

  CLasFile(final String origin, final String path, final String well, this.subs)
      : super(origin, path, well);
  CLasFile.fromJson(final dynamic json)
      : subs = List(json['subc']),
        super.fromJson(json) {
    for (var i = 0; i < subs.length; i++) {
      subs[i] = CLasFileSub.fromJson(json['subs'][i]);
    }
  }

  @override
  dynamic toJson() => {
        'type': 'las',
        'origin': origin,
        'path': path,
        'well': well,
        'subc': subs.length,
        'subs': subs.map((e) => e.toJson()).toList()
      };
}

class CInkFile extends C_File {
  final double strt;
  final double stop;
  final bool added;

  CInkFile(final String origin, final String path, final String well, this.strt,
      this.stop, this.added)
      : super(origin, path, well);

  CInkFile.fromJson(final dynamic json)
      : strt = (json['strt'] as num).toDouble(),
        stop = (json['stop'] as num).toDouble(),
        added = json['added'],
        super.fromJson(json);

  @override
  dynamic toJson() => {
        'type': 'ink',
        'origin': origin,
        'path': path,
        'well': well,
        'strt': strt,
        'stop': stop,
        'added': added
      };
  @override
  String get html {
    final s = StringBuffer();
    s.write(
        '<details class="inkfile"><summary>[$well] $origin</summary><p>$path</p>');
    s.write('<p>');
    s.write(
        '<span class="material-icons">${added ? 'radio_button_checked' : 'radio_button_unchecked'}</span>');
    s.write('<span class="strt">${strt}</span>');
    s.write('<span class="stop">${stop}</span>');
    s.write('</p>');
    s.write(
        '<button class="mdl-button mdl-button--icon mdl-button--colored"><i class="material-icons">launch</i></button>');
    s.write('</details>');
    return s.toString();
  }
}

class CErrorOnLine {
  final String origin;
  final String path;
  final List<ErrorOnLine> errors;

  CErrorOnLine(this.origin, this.path, this.errors);
  CErrorOnLine.fromJson(final dynamic json)
      : origin = json['origin'],
        path = json['path'],
        errors = List(json['errorc']) {
    for (var i = 0; i < errors.length; i++) {
      errors[i] = ErrorOnLine.fromJson(json['errors'][i]);
    }
  }
  dynamic toJson() => {
        'origin': origin,
        'path': path,
        'errorc': errors.length,
        'errors': errors.map((e) => e.toJson()).toList()
      };

  static List<CErrorOnLine> getByJsonString(String str) {
    final v = c.json.decode(str);
    if (v is Map) {
      return [CErrorOnLine.fromJson(v)];
    } else if (v is List) {
      return v
          .map<CErrorOnLine>((e) => CErrorOnLine.fromJson(e))
          .toList(growable: false);
    }
    return [];
  }

  String get html {
    final s = StringBuffer();

    s.write('''
      <details class="errfile mdl-card mdl-shadow--2dp">
        <summary class="mdl-card__title mdl-card--border">
          <span class="origin">$origin</span>
        </summary>
        <div class="mdl-card__supporting-text">
          <span class="path">$path</span>''');
    for (final err in errors) {
      if (err.err == KncError.arch.index) {
        final arch = ArchiverOutput.fromWrapperMsg(err.txt);
        s.write('''
          <p class="arch">
            <span class="eco">${arch.exitCode}</span>
            <span class="out">${arch.stdOut}</span>
            <span class="err">${arch.stdErr}</span>
          </p>''');
      } else {
        s.write('''
          <p class="sub">
            <span class="line">${err.line}</span>:
            <span class="err">${kncErrorStrings[err.err]}</span>
            <span class="txt">${err.txt}</span>
          </p>''');
      }
    }
    s.write('''
        </div>
        <div class="mdl-card__actions mdl-card--border">
          <button class="mdl-button mdl-button--icon mdl-button--colored">
            <i class="material-icons">launch</i>
          </button>
        </div>
      </details>''');
    return s.toString();
  }

  String get html2 {
    final s = StringBuffer();

    for (final err in errors) {
      if (err.err == KncError.arch.index) {
        final arch = ArchiverOutput.fromWrapperMsg(err.txt);
        s.write('''
          <a class="arch" href="#file-err-line-${err.line}">
            <span class="eco">${arch.exitCode}</span>
            <span class="out">${arch.stdOut}</span>
            <span class="err">${arch.stdErr}</span>
          </a>''');
      } else {
        s.write('''
          <a class="sub" href="#file-err-line-${err.line}">
            <span class="line">${err.line}</span>:
            <span class="err">${kncErrorStrings[err.err]}</span>
          </a>''');
      }
    }
    return s.toString();
  }
}
