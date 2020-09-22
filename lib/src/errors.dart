void Function(dynamic error, StackTrace stackTrace) getErrorFunc(
        final String txt) =>
    (error, StackTrace stackTrace) {
      print(txt);
      print(error);
      print('StackTrace:');
      print(stackTrace);
    };
