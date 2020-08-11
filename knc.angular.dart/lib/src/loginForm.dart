import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:crypto/crypto.dart' as crypto;

@Component(
  selector: 'my-login-form',
  templateUrl: 'loginForm.html',
  styleUrls: ['loginForm.css'],
  directives: [
    materialInputDirectives,
    MaterialIconComponent,
    MaterialButtonComponent
  ],
)
class MyLoginForm {
  bool _valid = false;
  bool get valid => _valid;
  set valid(bool b) {
    if (b == _valid) {
      return;
    }
    _valid = b;
  }

  bool _validPass = false;
  set validPass(bool b) {
    if (b == _validPass) {
      return;
    }
    _validPass = b;
    valid = _validMail && _validPass;
  }

  String _pass = '';
  String get pass => _pass;
  set pass(String v) {
    validPass = v.length >= 1 && v.length <= 32;
    _pass = crypto.sha256.convert('$v.x71j9cjiASD'.codeUnits).toString();
  }

  bool _validMail = false;
  set validMail(bool b) {
    if (b == _validMail) {
      return;
    }
    _validMail = b;
    valid = _validMail && _validPass;
  }

  String _mail = '';
  String get mail => _mail;
  set mail(String v) {
    final f = _reMailValidator.stringMatch(v);
    print(f);
    validMail = v != null && f != null && f.length == v.length;
    _mail = v;
  }

  static final _reMailValidator = RegExp(
      r"^[-a-z0-9!#$%&'*+/=?^_`{|}~]+(?:\.[-a-z0-9!#$%&'*+/=?^_`{|}~]+)*@(?:[a-z0-9]([-a-z0-9]{0,61}[a-z0-9])?\.)*(?:aero|arpa|asia|biz|cat|com|coop|edu|gov|info|int|jobs|mil|mobi|museum|name|net|org|pro|tel|travel|[a-z][a-z])$",
      caseSensitive: false);

  void submit() {
    if (!valid) {
      return;
    }
    print('mail: $mail');
    print('pass: $pass');
  }

  void Function() onClose;
}
