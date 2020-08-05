import 'dart:convert' as c;

import 'ArchiverOtput.dart';
import 'errors.dart';

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

/// Закрыть подписку на обновления
const wwwStreamClose = 'streamclose;';

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

  String get html {
    final s = StringBuffer();
    s.write('<details><summary>[$well] $origin</summary><p>$path</p>');
    if (this is CLasFile) {
      s.write('<p>LAS</p>');
    } else if (this is CInkFile) {
      s.write('<p>LAS</p>');
    }
    s.write('</details>');
    return s.toString();
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
    s.write('<details><summary>$origin</summary><p>$path</p>');
    for (final err in errors) {
      if (err.err == KncError.arch.index) {
        final arch = ArchiverOutput.fromWrapperMsg(err.txt);
        s.write('<p>${arch.exitCode}</p>');
        s.write('<p>${arch.stdOut}</p>');
        s.write('<p>${arch.stdErr}</p>');
      } else {
        s.write(
            '<p>${err.line}: ${kncErrorStrings[err.err]}<hr>${err.txt}</p>');
      }
    }
    s.write('</details>');
    return s.toString();
  }
}
