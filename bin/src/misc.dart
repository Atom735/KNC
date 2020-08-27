import 'dart:io';

String numToXlsAlpha(int i) {
  return ((i >= 26) ? numToXlsAlpha((i ~/ 26) - 1) : '') +
      String.fromCharCode('A'.codeUnits[0] + (i % 26));
}

Future<void> copyDirectoryRecursive(
    final Directory i, final Directory o) async {
  await o.create();
  final entitys = await i.list();
  await for (var entity in entitys) {
    if (entity is File) {
      await entity.copy(o.path + entity.path.substring(i.path.length));
    } else if (entity is Directory) {
      await copyDirectoryRecursive(
          entity, Directory(o.path + entity.path.substring(i.path.length)));
    }
  }
}
