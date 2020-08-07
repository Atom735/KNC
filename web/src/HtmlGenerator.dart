import 'dart:html';

final _reGenerator = RegExp(
    r'<gen\s+(?:(for)(?:\s*\(([\w\.]+)\s+in\s+([\w\.]+)\s*\))|(if)\s*\(([\w\.]+)\)|(else))\s*>|\$(?:{([\w\.]+)}|(\w+))|(<\/gen>)');

String htmlGenFromSrc(final String src, final dynamic v) {
  final buf = StringBuffer();

  final matches = _reGenerator.allMatches(src).toList(growable: false);
  final matchesCount = matches.length;

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
    return matchesCount - 1;
  }

  int _main(int iBegin, int iMatch, int iDepth) {
    bool lastIf;
    for (var i = iMatch; i < matchesCount; i++) {
      final match = matches[i];
      buf.write(src.substring(iBegin, match.start));
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
    buf.write(src.substring(iBegin));
    return matchesCount - 1;
  }

  _main(0, 0, 0);

  return buf.toString();
}

final _templates = <String, String>{};

Future<String> htmlGenFromUri(final String uri, final dynamic v) async =>
    _templates[uri] != null
        ? htmlGenFromSrc(_templates[uri], v)
        : htmlGenFromSrc(_templates[uri] = await HttpRequest.getString(uri), v);
