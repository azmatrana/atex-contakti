CKEDITOR.editorConfig = function( config ) {
	config.toolbarGroups = [
		{ name: 'styles', groups: [ 'styles' ] },
		{ name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ] },
		{ name: 'paragraph', groups: [ 'list', 'indent', 'blocks', 'align', 'bidi', 'paragraph' ] },
		{ name: 'clipboard', groups: [ 'clipboard', 'undo' ] },
		{ name: 'editing', groups: [ 'find', 'selection', 'editing' ] },
		{ name: 'links', groups: [ 'links' ] },
		{ name: 'insert', groups: [ 'insert' ] },
		{ name: 'forms', groups: [ 'forms' ] },
		{ name: 'tools', groups: [ 'tools' ] },
		{ name: 'document', groups: [ 'mode', 'document', 'doctools' ] },
		{ name: 'others', groups: [ 'others' ] },
		{ name: 'colors', groups: [ 'colors' ] },
		{ name: 'about', groups: [ 'about' ] }
	];

	config.removeButtons = 'Link,Subscript,Superscript,Paste,PasteText,PasteFromWord,Copy,Cut,Strike,RemoveFormat,Unlink,Anchor,Table,HorizontalRule,SpecialChar,Source,Outdent,Blockquote,About,Indent,Styles,Format,Smiley';
	config.enterMode = CKEDITOR.ENTER_BR;
	config.shiftEnterMode = CKEDITOR.ENTER_BR;
	config.basicEntities = false;
  config.extraPlugins = 'iframe';
};

CKEDITOR.on('txtDescription', function (ev) {
        ev.editor.dataProcessor.writer.setRules('br',
         {
             indent: false,
             breakBeforeOpen: false,
             breakAfterOpen: false,
             breakBeforeClose: false,
             breakAfterClose: false
         });
    });

CKEDITOR.on('instanceReady', function (ev) {
    var writer = ev.editor.dataProcessor.writer;
    // The character sequence to use for every indentation step.
    writer.indentationChars = '  ';

    var dtd = CKEDITOR.dtd;
    // Elements taken as an example are: block-level elements (div or p), list items (li, dd), and table elements (td, tbody).
    for (var e in CKEDITOR.tools.extend({}, dtd.$block, dtd.$listItem, dtd.$tableContent)) {
	ev.editor.dataProcessor.writer.setRules(e, {
	    // Indicates that an element creates indentation on line breaks that it contains.
	    indent: false,
	    // Inserts a line break before a tag.
	    breakBeforeOpen: false,
	    // Inserts a line break after a tag.
	    breakAfterOpen: false,
	    // Inserts a line break before the closing tag.
	    breakBeforeClose: false,
	    // Inserts a line break after the closing tag.
	    breakAfterClose: false
	});
    }

    for (var e in CKEDITOR.tools.extend({}, dtd.$list, dtd.$listItem, dtd.$tableContent)) {
	ev.editor.dataProcessor.writer.lineBreakChars = '';
    }
});

