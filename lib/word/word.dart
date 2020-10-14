class WordElement {
  String get type => 'unknown';
}

class WordElementParagraph extends WordElement {
  @override
  String get type => 'p';
}

class WordElementTable extends WordElement {
  @override
  String get type => 'tbl';
}

class DocumentWord {
  List<WordElement> elements;
}
