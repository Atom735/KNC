import 'dart:html';

final htmlValidator = NodeValidatorBuilder.common()
  ..allowElement('button', attributes: ['data-badge']);

final uri = Uri.tryParse(document.baseUri);

Element eGetById(final String id) => document.getElementById(id);
