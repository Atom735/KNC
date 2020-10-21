import 'package:xml/xml_events.dart';

/// XmlCDATAEvent
/// XmlCommentEvent
/// XmlDeclarationEvent
/// XmlDoctypeEvent
/// XmlEndElementEvent
/// XmlProcessingEvent
/// XmlStartElementEvent
/// XmlTextEvent
typedef RXmlEventFunc = bool Function(
    XmlEvent, List<bool Function(XmlEvent, List)>);

abstract class IOfficeWordElement {
  bool rXmlEventParser(XmlEvent _event, List<RXmlEventFunc> _stack);
}

/// Break Types
enum NOfficeWord_ST_BrType {
  /// Page Break
  page,

  /// Column Break
  column,

  /// Line Break
  textWrapping,
}

/// Line Break Text Wrapping Restart Location
enum NOfficeWord_ST_BrClear {
  /// Restart On Next Line
  none,

  /// Restart In Next Text Region When In Leftmost Position
  left,

  /// Restart In Next Text Region When In Rightmost Position
  right,

  /// Restart On Next Full Line
  all,
}

int /*?*/ _fromHex(final String /*?*/ str) =>
    int.tryParse(str ?? '', radix: 16);

int /*?*/ _getXmlAttributeHex(
        final String name, List<XmlEventAttribute> attributes) =>
    _fromHex(attributes
        .firstWhere((e) => e.name == name, orElse: () => null)
        ?.value);

T /*?*/ _getXmlAttributeEnum<T>(
    final String name, List<XmlEventAttribute> attributes, List<T> enumValues) {
  final value =
      attributes.firstWhere((e) => e.name == name, orElse: () => null)?.value;
  return enumValues.firstWhere((e) => e.toString().split('.')[1] == value,
      orElse: () => null);
}

NOfficeWord_ST_BrType _getXmlAttributeEnum_ST_BrType(
        final String name, List<XmlEventAttribute> attributes) =>
    _getXmlAttributeEnum(name, attributes, NOfficeWord_ST_BrType.values);

NOfficeWord_ST_BrClear _getXmlAttributeEnum_ST_BrClear(
        final String name, List<XmlEventAttribute> attributes) =>
    _getXmlAttributeEnum(name, attributes, NOfficeWord_ST_BrClear.values);

/// Sequence [1..1]
/// - from type `w:CT_PPrBase`
/// - - `w:pStyle` [0..1]    Referenced Paragraph Style
/// - - `w:keepNext` [0..1]    Keep Paragraph With Next Paragraph
/// - - `w:keepLines` [0..1]    Keep All Lines On One Page
/// - - `w:pageBreakBefore` [0..1]    Start Paragraph on Next Page
/// - - `w:framePr` [0..1]    Text Frame Properties
/// - - `w:widowControl` [0..1]    Allow First/Last Line to Display on a Separate Page
/// - - `w:numPr` [0..1]    Numbering Definition Instance Reference
/// - - `w:suppressLineNumbers` [0..1]    Suppress Line Numbers for Paragraph
/// - - `w:pBdr` [0..1]    Paragraph Borders
/// - - `w:shd` [0..1]    Paragraph Shading
/// - - `w:tabs` [0..1]    Set of Custom Tab Stops
/// - - `w:suppressAutoHyphens` [0..1]    Suppress Hyphenation for Paragraph
/// - - `w:kinsoku` [0..1]    Use East Asian Typography Rules for First and Last Character per Line
/// - - `w:wordWrap` [0..1]    Allow Line Breaking At Character Level
/// - - `w:overflowPunct` [0..1]    Allow Punctuation to Extent Past Text Extents
/// - - `w:topLinePunct` [0..1]    Compress Punctuation at Start of a Line
/// - - `w:autoSpaceDE` [0..1]    Automatically Adjust Spacing of Latin and East Asian Text
/// - - `w:autoSpaceDN` [0..1]    Automatically Adjust Spacing of East Asian Text and Numbers
/// - - `w:bidi` [0..1]    Right to Left Paragraph Layout
/// - - `w:adjustRightInd` [0..1]    Automatically Adjust Right Indent When Using Document Grid
/// - - `w:snapToGrid` [0..1]    Use Document Grid Settings for Inter-Line Paragraph Spacing
/// - - `w:spacing` [0..1]    Spacing Between Lines and Above/Below Paragraph
/// - - `w:ind` [0..1]    Paragraph Indentation
/// - - `w:contextualSpacing` [0..1]    Ignore Spacing Above and Below When Using Identical Styles
/// - - `w:mirrorIndents` [0..1]    Use Left/Right Indents as Inside/Outside Indents
/// - - `w:suppressOverlap` [0..1]    Prevent Text Frames From Overlapping
/// - - `w:jc` [0..1]    Paragraph Alignment
/// - - `w:textDirection` [0..1]    Paragraph Text Flow Direction
/// - - `w:textAlignment` [0..1]    Vertical Character Alignment on Line
/// - - `w:textboxTightWrap` [0..1]    Allow Surrounding Paragraphs to Tight Wrap to Text Box Contents
/// - - `w:outlineLvl` [0..1]    Associated Outline Level
/// - - `w:divId` [0..1]    Associated HTML div ID
/// - - `w:cnfStyle` [0..1]    Paragraph Conditional Formatting
/// - `w:rPr` [0..1]    Run Properties for the Paragraph Mark
/// - `w:sectPr` [0..1]    Section Properties
/// - `w:pPrChange` [0..1]    Revision Information for Paragraph Properties
class OfficeWordParagraphProperties extends IOfficeWordElement {
  @override
  bool rXmlEventParser(XmlEvent _event, List<RXmlEventFunc> _stack) {
    if (_event is XmlStartElementEvent) {
    } else if (_event is XmlEndElementEvent) {
      if (_event.name == 'w:pPr') {
        return true;
      }
    }
    return false;
  }
}

/// Empty content
///
/// === Attributes ===
/// - `w:type`	[0..1]	`w:ST_BrType`	Break Type
/// - `w:clear`	[0..1]	`w:ST_BrClear`	Restart Location For Text Wrapping Break
class OfficeWordBreak extends IOfficeWordElement {
  /// Break Type
  NOfficeWord_ST_BrType type;

  /// Restart Location For Text Wrapping Break
  NOfficeWord_ST_BrClear clear;

  OfficeWordBreak();
  OfficeWordBreak.fromXmlEvent(XmlStartElementEvent _event) {
    final attributes = _event.attributes;
    if (attributes != null && attributes.isNotEmpty) {
      type = _getXmlAttributeEnum_ST_BrType('type', attributes);
      clear = _getXmlAttributeEnum_ST_BrClear('clear', attributes);
    }
  }

  @override
  bool rXmlEventParser(XmlEvent _event, List<RXmlEventFunc> _stack) {
    if (_event is XmlEndElementEvent) {
      if (_event.name == 'w:br') {
        return true;
      }
    }
    return false;
  }
}

/// from type `w:ST_String`
/// `xsd:string`
///
/// === Attributes ===
/// - `xml:space`	[0..1]	Unspecified	Content Contains Significant Whitespace
class OfficeWordText extends IOfficeWordElement {
  /// Revision Identifier for Run Properties
  /// - `false` - `default`
  /// - `true` - `preserve`
  bool space = false;

  String txt = '';

  OfficeWordText();
  OfficeWordText.fromXmlEvent(XmlStartElementEvent _event) {
    final attributes = _event.attributes;
    if (attributes != null && attributes.isNotEmpty) {
      space = attributes
              .firstWhere((e) => e.name == 'xml:space', orElse: () => null)
              ?.value ==
          'preserve';
    }
  }

  @override
  bool rXmlEventParser(XmlEvent _event, List<RXmlEventFunc> _stack) {
    if (_event is XmlTextEvent) {
      txt =
          space ? '$txt${_event.text}' : '${txt.trim()} ${_event.text.trim()}';
    } else if (_event is XmlEndElementEvent) {
      if (_event.name == 'w:t') {
        return true;
      }
    }
    return false;
  }
}

/// Sequence [1..1]
/// - from group `w:EG_RPr`
/// - - Sequence [0..1]
/// - - - `w:rPr` [0..1]    Run Properties
/// - from group `w:EG_RunInnerContent`
/// - - Choice [0..*]
/// - - - `w:br`    Break
/// - - - `w:t`    Text
/// - - - `w:delText`    Deleted Text
/// - - - `w:instrText`    Field Code
/// - - - `w:delInstrText`    Deleted Field Code
/// - - - `w:noBreakHyphen`    Non Breaking Hyphen Character
/// - - - `w:softHyphen` [0..1]    Optional Hyphen Character
/// - - - `w:dayShort` [0..1]    Date Block - Short Day Format
/// - - - `w:monthShort` [0..1]    Date Block - Short Month Format
/// - - - `w:yearShort` [0..1]    Date Block - Short Year Format
/// - - - `w:dayLong` [0..1]    Date Block - Long Day Format
/// - - - `w:monthLong` [0..1]    Date Block - Long Month Format
/// - - - `w:yearLong` [0..1]    Date Block - Long Year Format
/// - - - `w:annotationRef` [0..1]    Comment Information Block
/// - - - `w:footnoteRef` [0..1]    Footnote Reference Mark
/// - - - `w:endnoteRef` [0..1]    Endnote Reference Mark
/// - - - `w:separator` [0..1]    Footnote/Endnote Separator Mark
/// - - - `w:continuationSeparator` [0..1]    Continuation Separator Mark
/// - - - `w:sym` [0..1]    Symbol Character
/// - - - `w:pgNum` [0..1]    Page Number Block
/// - - - `w:cr` [0..1]    Carriage Return
/// - - - `w:tab` [0..1]    Tab Character
/// - - - `w:object`    Inline Embedded Object
/// - - - `w:pict`    VML Object
/// - - - `w:fldChar`    Complex Field Character
/// - - - `w:ruby`    Phonetic Guide
/// - - - `w:footnoteReference`    Footnote Reference
/// - - - `w:endnoteReference`    Endnote Reference
/// - - - `w:commentReference`    Comment Content Reference Mark
/// - - - `w:drawing`    DrawingML Object
/// - - - `w:ptab` [0..1]    Absolute Position Tab Character
/// - - - `w:lastRenderedPageBreak` [0..1]    Position of Last Calculated Page Break
/// === Attributes ===
/// - `w:rsidRPr`	[0..1]	`w:ST_LongHexNumber`	Revision Identifier for Run Properties
/// - `w:rsidDel`	[0..1]	`w:ST_LongHexNumber`	Revision Identifier for Run Deletion
/// - `w:rsidR`	[0..1]	`w:ST_LongHexNumber`	Revision Identifier for Run
class OfficeWordTextRun extends IOfficeWordElement {
  /// Revision Identifier for Run Properties
  int /*?*/ rsidRPr;

  /// Revision Identifier for Run Deletion
  int /*?*/ rsidDel;

  /// Revision Identifier for Run
  int /*?*/ rsidR;

  List<IOfficeWordElement> elements = [];

  OfficeWordTextRun();
  OfficeWordTextRun.fromXmlEvent(XmlStartElementEvent _event) {
    final attributes = _event.attributes;
    if (attributes != null && attributes.isNotEmpty) {
      rsidRPr = _getXmlAttributeHex('w:rsidRPr', attributes);
      rsidR = _getXmlAttributeHex('w:rsidR', attributes);
      rsidDel = _getXmlAttributeHex('w:rsidDel', attributes);
    }
  }

  @override
  bool rXmlEventParser(XmlEvent _event, List<RXmlEventFunc> _stack) {
    if (_event is XmlStartElementEvent) {
      if (_event.name == 'w:br') {
        elements.add(OfficeWordBreak.fromXmlEvent(_event));
        if (!_event.isSelfClosing) {
          _stack.add(elements.last.rXmlEventParser);
        }
      } else if (_event.name == 'w:t') {
        elements.add(OfficeWordText.fromXmlEvent(_event));
        if (!_event.isSelfClosing) {
          _stack.add(elements.last.rXmlEventParser);
        }
      }
    } else if (_event is XmlEndElementEvent) {
      if (_event.name == 'w:r') {
        return true;
      }
    }
    return false;
  }
}

/// Sequence [1..1]
/// - `w:pPr` [0..1]    Paragraph Properties
/// - from group `w:EG_PContent`
/// - - Choice [0..*]
/// - - - from group `w:EG_ContentRunContent`
/// - - - - `w:customXml`    Inline-Level Custom XML Element
/// - - - - `w:smartTag`    Inline-Level Smart Tag
/// - - - - `w:sdt`    Inline-Level Structured Document Tag
/// - - - - `w:r`    Text Run
/// - - - - from group `w:EG_RunLevelElts`
/// - - - - - `w:proofErr` [0..1]    Proofing Error Anchor
/// - - - - - `w:permStart` [0..1]    Range Permission Start
/// - - - - - `w:permEnd` [0..1]    Range Permission End
/// - - - - - from group `w:EG_RangeMarkupElements`
/// - - - - - - `w:bookmarkStart`    Bookmark Start
/// - - - - - - `w:bookmarkEnd`    Bookmark End
/// - - - - - - `w:moveFromRangeStart`    Move Source Location Container - Start
/// - - - - - - `w:moveFromRangeEnd`    Move Source Location Container - End
/// - - - - - - `w:moveToRangeStart`    Move Destination Location Container - Start
/// - - - - - - `w:moveToRangeEnd`    Move Destination Location Container - End
/// - - - - - - `w:commentRangeStart`    Comment Anchor Range Start
/// - - - - - - `w:commentRangeEnd`    Comment Anchor Range End
/// - - - - - - `w:customXmlInsRangeStart`    Custom XML Markup Insertion Start
/// - - - - - - `w:customXmlInsRangeEnd`    Custom XML Markup Insertion End
/// - - - - - - `w:customXmlDelRangeStart`    Custom XML Markup Deletion Start
/// - - - - - - `w:customXmlDelRangeEnd`    Custom XML Markup Deletion End
/// - - - - - - `w:customXmlMoveFromRangeStart`    Custom XML Markup Move Source Start
/// - - - - - - `w:customXmlMoveFromRangeEnd`    Custom XML Markup Move Source End
/// - - - - - - `w:customXmlMoveToRangeStart`    Custom XML Markup Move Destination Location Start
/// - - - - - - `w:customXmlMoveToRangeEnd`    Custom XML Markup Move Destination Location End
/// - - - - - `w:ins` [0..1]    Inserted Run Content
/// - - - - - `w:del` [0..1]    Deleted Run Content
/// - - - - - `w:moveFrom`    Move Source Run Content
/// - - - - - `w:moveTo`    Move Destination Run Content
/// - - - - - from group `w:EG_MathContent`
/// - - - - - - `m:oMathPara`    Math Paragraph
/// - - - - - - `m:oMath`
/// - - - `w:fldSimple` [0..*]    Simple Field
/// - - - `w:hyperlink`    Hyperlink
/// - - - `w:subDoc`    Anchor for Subdocument Location
///
/// === Attributes ===
/// - `w:rsidRPr`	[0..1]	`w:ST_LongHexNumber`	Revision Identifier for Paragraph Glyph Formatting
/// - `w:rsidR`	[0..1]	`w:ST_LongHexNumber`	Revision Identifier for Paragraph
/// - `w:rsidDel`	[0..1]	`w:ST_LongHexNumber`	Revision Identifier for Paragraph Deletion
/// - `w:rsidP`	[0..1]	`w:ST_LongHexNumber`	Revision Identifier for Paragraph Properties
/// - `w:rsidRDefault`	[0..1]	`w:ST_LongHexNumber`	Default Revision Identifier for Runs
class OfficeWordParagraph extends IOfficeWordElement {
  /// Revision Identifier for Paragraph Glyph Formatting
  int /*?*/ rsidRPr;

  /// Revision Identifier for Paragraph
  int /*?*/ rsidR;

  /// Revision Identifier for Paragraph Deletion
  int /*?*/ rsidDel;

  /// Revision Identifier for Paragraph Properties
  int /*?*/ rsidP;

  /// Default Revision Identifier for Runs
  int /*?*/ rsidRDefault;

  /// Paragraph Properties
  OfficeWordParagraphProperties /*?*/ pPr;

  List<IOfficeWordElement> elements = [];

  OfficeWordParagraph();
  OfficeWordParagraph.fromXmlEvent(XmlStartElementEvent _event) {
    final attributes = _event.attributes;
    if (attributes != null && attributes.isNotEmpty) {
      rsidRPr = _getXmlAttributeHex('w:rsidRPr', attributes);
      rsidR = _getXmlAttributeHex('w:rsidR', attributes);
      rsidDel = _getXmlAttributeHex('w:rsidDel', attributes);
      rsidP = _getXmlAttributeHex('w:rsidP', attributes);
      rsidRDefault = _getXmlAttributeHex('w:rsidRDefault', attributes);
    }
  }

  @override
  bool rXmlEventParser(XmlEvent _event, List<RXmlEventFunc> _stack) {
    if (_event is XmlStartElementEvent) {
      if (_event.name == 'w:pPr') {
        pPr = OfficeWordParagraphProperties();
        if (!_event.isSelfClosing) {
          _stack.add(pPr.rXmlEventParser);
        }
      } else if (_event.name == 'w:r') {
        elements.add(OfficeWordTextRun.fromXmlEvent(_event));
        if (!_event.isSelfClosing) {
          _stack.add(elements.last.rXmlEventParser);
        }
      }
    } else if (_event is XmlEndElementEvent) {
      if (_event.name == 'w:p') {
        return true;
      }
    }
    return false;
  }
}

/// Sequence [1..1]
/// - from group `w:EG_RangeMarkupElements`
/// - - Choice [0..*]
/// - - - `w:bookmarkStart`    Bookmark Start
/// - - - `w:bookmarkEnd`    Bookmark End
/// - - - `w:moveFromRangeStart`    Move Source Location Container - Start
/// - - - `w:moveFromRangeEnd`    Move Source Location Container - End
/// - - - `w:moveToRangeStart`    Move Destination Location Container - Start
/// - - - `w:moveToRangeEnd`    Move Destination Location Container - End
/// - - - `w:commentRangeStart`    Comment Anchor Range Start
/// - - - `w:commentRangeEnd`    Comment Anchor Range End
/// - - - `w:customXmlInsRangeStart`    Custom XML Markup Insertion Start
/// - - - `w:customXmlInsRangeEnd`    Custom XML Markup Insertion End
/// - - - `w:customXmlDelRangeStart`    Custom XML Markup Deletion Start
/// - - - `w:customXmlDelRangeEnd`    Custom XML Markup Deletion End
/// - - - `w:customXmlMoveFromRangeStart`    Custom XML Markup Move Source Start
/// - - - `w:customXmlMoveFromRangeEnd`    Custom XML Markup Move Source End
/// - - - `w:customXmlMoveToRangeStart`    Custom XML Markup Move Destination Location Start
/// - - - `w:customXmlMoveToRangeEnd`    Custom XML Markup Move Destination Location End
/// - `w:tblPr` [1..1]    Table Properties
/// - `w:tblGrid` [1..1]    Table Grid
/// - from group `w:EG_ContentRowContent`
/// - - Choice [0..*]
/// - - `w:tr` [0..*]    Table Row
/// - - `w:customXml`    Row-Level Custom XML Element
/// - - `w:sdt`    Row-Level Structured Document Tag
/// - - from group `w:EG_RunLevelElts`
/// - - - `w:proofErr` [0..1]    Proofing Error Anchor
/// - - - `w:permStart` [0..1]    Range Permission Start
/// - - - `w:permEnd` [0..1]    Range Permission End
/// - - - from group `w:EG_RangeMarkupElements`
/// - - - - `w:bookmarkStart`    Bookmark Start
/// - - - - `w:bookmarkEnd`    Bookmark End
/// - - - - `w:moveFromRangeStart`    Move Source Location Container - Start
/// - - - - `w:moveFromRangeEnd`    Move Source Location Container - End
/// - - - - `w:moveToRangeStart`    Move Destination Location Container - Start
/// - - - - `w:moveToRangeEnd`    Move Destination Location Container - End
/// - - - - `w:commentRangeStart`    Comment Anchor Range Start
/// - - - - `w:commentRangeEnd`    Comment Anchor Range End
/// - - - - `w:customXmlInsRangeStart`    Custom XML Markup Insertion Start
/// - - - - `w:customXmlInsRangeEnd`    Custom XML Markup Insertion End
/// - - - - `w:customXmlDelRangeStart`    Custom XML Markup Deletion Start
/// - - - - `w:customXmlDelRangeEnd`    Custom XML Markup Deletion End
/// - - - - `w:customXmlMoveFromRangeStart`    Custom XML Markup Move Source Start
/// - - - - `w:customXmlMoveFromRangeEnd`    Custom XML Markup Move Source End
/// - - - - `w:customXmlMoveToRangeStart`    Custom XML Markup Move Destination Location Start
/// - - - - `w:customXmlMoveToRangeEnd`    Custom XML Markup Move Destination Location End
/// - - - `w:ins` [0..1]    Inserted Run Content
/// - - - `w:del` [0..1]    Deleted Run Content
/// - - - `w:moveFrom`    Move Source Run Content
/// - - - `w:moveTo`    Move Destination Run Content
/// - - - from group `w:EG_MathContent`
/// - - - `m:`oMathPara    Math Paragraph
/// - - - `m:`oMath
class OfficeWordTable extends IOfficeWordElement {
  @override
  bool rXmlEventParser(XmlEvent _event, List<RXmlEventFunc> _stack) {
    if (_event is XmlStartElementEvent) {
    } else if (_event is XmlEndElementEvent) {
      if (_event.name == 'w:tbl') {
        return true;
      }
    }
    return false;
  }
}

/// Sequence [1..1]
/// - from group `w:EG_BlockLevelElts`
/// Choice [0..*]
/// - from group `w:EG_BlockLevelChunkElts`
/// - - from group `w:EG_ContentBlockContent`
/// - - - `w:customXml`    Block-Level Custom XML Element
/// - - - `w:sdt`    Block-Level Structured Document Tag
/// - - - `w:p` [0..*]    Paragraph
/// - - - `w:tbl` [0..*]    Table
/// - - - from group `w:EG_RunLevelElts`
/// - - - - `w:proofErr` [0..1]    Proofing Error Anchor
/// - - - - `w:permStart` [0..1]    Range Permission Start
/// - - - - `w:permEnd` [0..1]    Range Permission End
/// - - - - from group `w:EG_RangeMarkupElements`
/// - - - - - `w:bookmarkStart`    Bookmark Start
/// - - - - - `w:bookmarkEnd`    Bookmark End
/// - - - - - `w:moveFromRangeStart`    Move Source Location Container - Start
/// - - - - - `w:moveFromRangeEnd`    Move Source Location Container - End
/// - - - - - `w:moveToRangeStart`    Move Destination Location Container - Start
/// - - - - - `w:moveToRangeEnd`    Move Destination Location Container - End
/// - - - - - `w:commentRangeStart`    Comment Anchor Range Start
/// - - - - - `w:commentRangeEnd`    Comment Anchor Range End
/// - - - - - `w:customXmlInsRangeStart`    Custom XML Markup Insertion Start
/// - - - - - `w:customXmlInsRangeEnd`    Custom XML Markup Insertion End
/// - - - - - `w:customXmlDelRangeStart`    Custom XML Markup Deletion Start
/// - - - - - `w:customXmlDelRangeEnd`    Custom XML Markup Deletion End
/// - - - - - `w:customXmlMoveFromRangeStart`    Custom XML Markup Move Source Start
/// - - - - - `w:customXmlMoveFromRangeEnd`    Custom XML Markup Move Source End
/// - - - - - `w:customXmlMoveToRangeStart`    Custom XML Markup Move Destination Location Start
/// - - - - - `w:customXmlMoveToRangeEnd`    Custom XML Markup Move Destination Location End
/// - - - - - `w:ins` [0..1]    Inserted Run Content
/// - - - - - `w:del` [0..1]    Deleted Run Content
/// - - - - - `w:moveFrom`    Move Source Run Content
/// - - - - - `w:moveTo`    Move Destination Run Content
/// - - - - from group `w:EG_MathContent`
/// - - - - - `m:oMathPara`    Math Paragraph
/// - - - - - `m:oMath`
/// - `w:altChunk` [0..*]    Anchor for Imported External Content
/// `w:sectPr` [0..1]    Document Final Section Properties
class OfficeWordBody extends IOfficeWordElement {
  List<IOfficeWordElement> elements;
  @override
  bool rXmlEventParser(XmlEvent _event, List<RXmlEventFunc> _stack) {
    if (_event is XmlStartElementEvent) {
      if (_event.name == 'w:p') {
        elements.add(OfficeWordParagraph.fromXmlEvent(_event));
        if (!_event.isSelfClosing) {
          _stack.add(elements.last.rXmlEventParser);
        }
        return false;
      } else if (_event.name == 'w:tbl') {
        elements.add(OfficeWordTable());
        if (!_event.isSelfClosing) {
          _stack.add(elements.last.rXmlEventParser);
        }
        return false;
      }
    } else if (_event is XmlEndElementEvent) {
      if (_event.name == 'w:body') {
        return true;
      }
    }
    return false;
  }
}

/// Sequence [1..1]
/// - from type ``w:CT_DocumentBase``
/// - - `w:background` [0..1]    Document Background
/// - `w:body` [0..1]    Document Body
class OfficeWordDocument extends IOfficeWordElement {
  OfficeWordBody body;

  @override
  bool rXmlEventParser(XmlEvent _event, List<RXmlEventFunc> _stack) {
    if (_event is XmlStartElementEvent) {
      if (_event.isSelfClosing) {
        return false;
      }
      if (_event.name == 'w:body') {
        body = OfficeWordBody();
        _stack.add(body.rXmlEventParser);
        return false;
      }
    } else if (_event is XmlEndElementEvent) {
      if (_event.name == 'w:document') {
        return true;
      }
    }
    return false;
  }

  static OfficeWordDocument /*?*/ createByXmlString(final String data) {
    OfficeWordDocument o;
    final _iEvents = parseEvents(data);

    final _stack = <RXmlEventFunc>[];

    bool _rInRoot(final XmlEvent _event, final List<RXmlEventFunc> _stack) {
      if (_event is XmlStartElementEvent) {
        if (_event.isSelfClosing) {
          return false;
        }
        if (_event.name == 'w:document') {
          o = OfficeWordDocument();
          _stack.add(o.rXmlEventParser);
          return false;
        }
      }
      return false;
    }

    _stack.add(_rInRoot);
    for (final _event in _iEvents) {
      if (_stack.last(_event, _stack)) {
        _stack.removeLast();
      }
    }
    return o;
  }
}
