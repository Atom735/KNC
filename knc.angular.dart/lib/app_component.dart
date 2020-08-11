import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:english_words/english_words.dart';

@Component(
  selector: 'my-app',
  templateUrl: 'app_component.html',
  styleUrls: ['app_component.css'],
  directives: [coreDirectives, formDirectives, materialInputDirectives],
  providers: [materialProviders],
)
class AppComponent implements OnInit {
  final title = 'Tour of Heroes';

  var names = <WordPair>[];
  final savedNames = new Set<WordPair>();

  void generateNames() {
    names = generateWordPairs().take(5).toList();
  }

  @override
  void ngOnInit() {
    generateNames();
  }

  void addToSaved(WordPair name) {
    savedNames.add(name);
  }

  void removeFromSaved(WordPair name) {
    savedNames.remove(name);
  }

  void toggleSavedState(WordPair name) {
    if (savedNames.contains(name)) {
      removeFromSaved(name);
      return;
    }
    addToSaved(name);
  }
}
