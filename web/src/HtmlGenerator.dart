import 'dart:convert';
import 'dart:html';

/// Абстрактный класс, который говорит что класс наследник
/// может сгененрировать html фрагмент
abstract class HtmlGenerable {}

final _htmlValidator = NodeValidatorBuilder.common()
  ..allowElement('gen', attributes: ['for', 'in', 'if', 'else']);

final _reGenerator = RegExp(
    r'<gen\s+(?:(for)(?:\s*\(([\w\.]+)\s+in\s+([\w\.]+)\s*\))|(if)\s*\(([\w\.]+)\)|(else))\s*>|\$(?:{([\w\.]+)}|(\w+))|(<\/gen>)');

void generator() {
  HttpRequest.getString('templates/LasFileDetails.html').then((str) {
    print(str);

    final vRaw = {
      'origin': 'Путь к оригиналу файла',
      'well': 'наименование скважины',
      'path': 'путь к копии файла',
      'subs': [
        {'added': false, 'mnem': 'Мнемоника №1', 'strt': 453.3, 'stop': 1208},
        {'added': true, 'mnem': 'M2222', 'strt': 2, 'stop': 13.34}
      ]
    };
    final jstr = json.encode(vRaw);
    final v = json.decode(jstr);

    final buf = StringBuffer();

    final matches = _reGenerator.allMatches(str).toList(growable: false);
    final matchesCount = matches.length;
    var i0 = 0;

    dynamic _getSub(final String s, [dynamic d]) {
      d ??= v;
      final iP = s.indexOf('.');
      if (iP == -1) {
        return d[s];
      } else {
        // Если точка найдена первее
        return _getSub(s.substring(iP + 1), d[s.substring(0, iP)]);
      }
    }

    /// Пропускает вложенные скобки
    int _skips(int iMatch, int iDepth) {
      for (var i = iMatch; i < matchesCount; i++) {
        final match = matches[i];
        if (match[1] != null || match[4] != null || match[6] != null) {
          i = _skips(i + 1, iDepth + 1);
        } else if (match[9] != null) {
          return i;
        }
      }
    }

    int _main(int iBegin, int iMatch, int iDepth) {
      bool lastIf;
      for (var i = iMatch; i < matchesCount; i++) {
        final match = matches[i];
        buf.write(str.substring(iBegin, match.start));
        if (match[7] != null) {
          iBegin = match.end;
          // ${ident.sub}

          buf.write(_getSub(match[7]));
        } else if (match[8] != null) {
          iBegin = match.end;
          // $ident
          buf.write(v[match[8]]);
        } else if (match[1] != null) {
          iBegin = match.end;
          int i0;
          // for ($2 in $3)
          for (final _i in _getSub(match[3])) {
            v[match[2]] = _i;
            i0 = _main(iBegin, i + 1, iDepth + 1);
          }
          i = i0;
          iBegin = matches[i].end;
        } else if (match[4] != null) {
          iBegin = match.end;
          // if ($5)
          lastIf = _getSub(match[5]);
          if (lastIf) {
            i = _main(iBegin, i + 1, iDepth + 1);
          } else {
            i = _skips(i + 1, iDepth + 1);
          }
          iBegin = matches[i].end;
        } else if (match[6] != null) {
          iBegin = match.end;
          // else
          if (!lastIf) {
            i = _main(iBegin, i + 1, iDepth + 1);
          } else {
            i = _skips(i + 1, iDepth + 1);
          }
          iBegin = matches[i].end;
        } else if (match[9] != null) {
          return i;
        }
      }
      buf.write(str.substring(iBegin));
    }

    _main(0, 0, 0);

    print(buf.toString());

    final div = DivElement();
    div.appendHtml(str, validator: _htmlValidator);

    document.body.append(div);
  });
}
