import 'dart:convert' as c;

import 'package:crypto/crypto.dart' show sha256;

import 'ArchiverOtput.dart';
import 'errors.dart';

const wwwPort = 80;

/// Клиент отправляет серверу запрос на обновление данных всех задач
const wwwTaskViewUpdate = 'taskview;';

/// Клиент отправляет серверу запрос на новую задачу
const wwwTaskNew = 'tasknew;';

/// Подписка на обновления состояния задачи, далее идёт айди задачи
const wwwTaskUpdates = 'taskupdates;';

/// Запрос на получение ошибок
const wwwFileNotes = 'taskgeterros;';

/// Запрос на получение обработанных файлов
const wwwTaskGetFiles = 'taskgetfiles;';

/// Запрос на получение данных файла
const wwwGetFileData = 'getfiledata;';

/// Закрыть подписку на обновления
const wwwStreamClose = 'streamclose;';

/// Отправка данных для входа
const wwwUserSignin = 'signin;';

/// Отправка данных для регистрации
const wwwUserRegistration = 'registrtion;';

/// Отправка запроса на выход из системы
const wwwUserLogout = 'logout;';

/// Запрос на восстановление "мёртвой" задачи
const wwwTaskRestart = 'taskrestart;';

/// Получение OneFileData файла находящегося по пути `path`
const wwwGetOneFileData = 'getonefiledata;';

const msgDoc2x = 'doc2x;';
const msgZip = 'zip;';
const msgUnzip = 'unzip;';

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
    if (data[i] != signature[i]) {
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
