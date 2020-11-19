import 'dart:convert';

import '../ws/index.dart';
import '../constants.dart';
import '../userbase/index.dart';

void Function() wsOpen(SocketWrapper ws, UserSessionToken token) {
  ws.send(0, msgUserConnected + token.user.toWsMsg());

  final listners = [
    ws.waitMsgAll(msgUserReg).listen((msg) {
      try {
        final usr = userReg(User.fromJson(jsonDecode(msg.s)));
        final token = userNewToken(usr);
        ws.send(msg.i, token.token);
      } catch (e) {
        ws.send(msg.i, '!$e');
      }
    }),
    ws.waitMsgAll(msgUserPass).listen((msg) {
      try {
        final usr = userPass(User.fromJson(jsonDecode(msg.s)));
        final token = userNewToken(usr);
        ws.send(msg.i, token.token);
      } catch (e) {
        ws.send(msg.i, '!$e');
      }
    }),
  ];

  return () => listners.forEach((e) {
        e.cancel();
      });
}
