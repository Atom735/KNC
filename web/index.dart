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

void main() {
  _jsJMsgUserSignin = allowInterop(JMsgUserSignin.jsFunc);
  _jsJMsgUserLogout = allowInterop(JMsgUserLogout.jsFunc);
  _jsJMsgUserRegistration = allowInterop(JMsgUserRegistration.jsFunc);
  _jsJMsgDoc2X = allowInterop(JMsgDoc2X.jsFunc);
  _jsJMsgZip = allowInterop(JMsgZip.jsFunc);
  _jsJMsgUnzip = allowInterop(JMsgUnzip.jsFunc);
}
