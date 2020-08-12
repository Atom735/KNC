import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:english_words/english_words.dart';

import 'src/loginForm.dart';

@Component(
  selector: 'my-app',
  templateUrl: 'app_component.html',
  styleUrls: [
    'package:angular_components/app_layout/layout.scss.css',
    'app_component.css'
  ],
  directives: [
    coreDirectives,
    formDirectives,
    MaterialInputComponent,
    MaterialButtonComponent,
    MaterialIconComponent,
    MaterialProgressComponent,
    MaterialListComponent,
    MaterialListItemComponent,
    MaterialPopupComponent,
    PopupSourceDirective,
    MyLoginForm
  ],
  providers: [materialProviders],
)
class AppComponent implements OnInit {
  bool load = true;
  final title = 'Tour of Heroes';
  bool accountPopupVisible = false;
  final accountPopupPosition = RelativePosition.InlineBottomLeft;

  var names = <WordPair>[];
  final savedNames = Set<WordPair>();

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
