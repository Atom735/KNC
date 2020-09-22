import 'dart:html';

main(List<String> args) {
  print('Hello World/*!*/');

  window.onPopState.listen((event) {
    print(event.state);
    print(window.location.href);
  });
  window.onLoad.listen((event) {
    window.history.pushState('Data of state', 'title', '/url');
  });
}
