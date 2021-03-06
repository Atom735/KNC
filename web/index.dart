@JS()
library callable_function;

import 'package:js/js.dart';

import 'package:knc/knc.dart';

@JS('dartJMsgUserSignin')
external set _jsJMsgUserSignin(Function f);
@JS('dartJMsgUserLogout')
external set _jsJMsgUserLogout(Function f);
@JS('dartJMsgUserRegistration')
external set _jsJMsgUserRegistration(Function f);
@JS('dartJMsgDoc2X')
external set _jsJMsgDoc2X(Function f);
@JS('dartJMsgZip')
external set _jsJMsgZip(Function f);
@JS('dartJMsgUnzip')
external set _jsJMsgUnzip(Function f);
@JS('dartJMsgNewTask')
external set _jsJMsgNewTask(Function f);
@JS('dartJMsgGetTasks')
external set _jsJMsgGetTasks(Function f);
@JS('dartJMsgGetTaskFileList')
external set _jsJMsgGetTaskFileList(Function f);
@JS('dartJMsgGetTaskFileNotesAndCurves')
external set _jsJMsgGetTaskFileNotesAndCurves(Function f);
@JS('dartJMsgTaskKill')
external set _jsJMsgTaskKill(Function f);

@JS('dartIdJMsgTaskNew')
external set _jsIdJMsgTaskNew(Function f);
@JS('dartIdJMsgTaskUpdate')
external set _jsIdJMsgTaskUpdate(Function f);
@JS('dartIdJMsgTasksAll')
external set _jsIdJMsgTasksAll(Function f);
@JS('dartIdJMsgTaskKill')
external set _jsIdJMsgTaskKill(Function f);

@JS('dartJTaskSettingsDefs')
external set _jsJTaskSettingsDefs(Function f);

void main() {
  _jsJMsgUserSignin = allowInterop(JMsgUserSignin.jsFunc);
  _jsJMsgUserLogout = allowInterop(JMsgUserLogout.jsFunc);
  _jsJMsgUserRegistration = allowInterop(JMsgUserRegistration.jsFunc);
  _jsJMsgDoc2X = allowInterop(JMsgDoc2X.jsFunc);
  _jsJMsgZip = allowInterop(JMsgZip.jsFunc);
  _jsJMsgUnzip = allowInterop(JMsgUnzip.jsFunc);
  _jsJMsgNewTask = allowInterop(JMsgNewTask.jsFunc);
  _jsJMsgGetTasks = allowInterop(JMsgGetTasks.jsFunc);
  _jsJMsgGetTaskFileList = allowInterop(JMsgGetTaskFileList.jsFunc);
  _jsJMsgGetTaskFileNotesAndCurves =
      allowInterop(JMsgGetTaskFileNotesAndCurves.jsFunc);
  _jsJMsgTaskKill = allowInterop(JMsgTaskKill.jsFunc);

  _jsIdJMsgTaskNew = allowInterop(() => JMsgTaskNew.msgId);
  _jsIdJMsgTaskUpdate = allowInterop(() => JMsgTaskUpdate.msgId);
  _jsIdJMsgTasksAll = allowInterop(() => JMsgTasksAll.msgId);
  _jsIdJMsgTaskKill = allowInterop(() => JMsgTaskKill.msgId);

  _jsJTaskSettingsDefs = allowInterop(() => JTaskSettings().js());
}
