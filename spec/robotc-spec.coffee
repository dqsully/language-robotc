{TextEditor} = require 'atom'

describe 'Language-ROBOTC', ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-robotc')

  describe "ROBOTC", ->
    beforeEach ->
      grammar = atom.grammars.grammarForScopeName('source.robotc')

    it 'parses the grammar', ->
      expect(grammar).toBeTruthy()
      expect(grammar.scopeName).toBe 'source.robotc'

    it 'tokenizes functions', ->
      lines = grammar.tokenizeLines '''
        int something() {
          return 0;
        }
      '''

      expect(lines[0][0]).toEqual value: 'int', scopes: ["source.robotc", "storage.type.robotc"]
      expect(lines[0][2]).toEqual value: 'something', scopes: ["source.robotc", "meta.function.robotc", "entity.name.function.robotc"]

    it 'tokenizes enums', ->
      lines = grammar.tokenizeLines '''
        TBaudRate[baudRateUndefined]
      '''

      expect(lines[0][0]).toEqual value: 'TBaudRate', scopes: ["source.robotc", "storage.type.robotc"]
      expect(lines[0][3]).toEqual value: 'baudRateUndefined', scopes: ["source.robotc", "meta.enum.robotc"]

    describe "indentation", ->
      editor = null

      beforeEach ->
        editor = new TextEditor({})
        editor.setGrammar(grammar)

      expectPreservedIndentation = (text) ->
        editor.setText(text)
        editor.autoIndentBufferRows(0, editor.getLineCount() - 1)

        expectedLines = text.split("\n")
        actualLines = editor.getText().split("\n")
        for actualLine, i in actualLines
          expect([
            actualLine,
            editor.indentLevelForLine(actualLine)
          ]).toEqual([
            expectedLines[i],
            editor.indentLevelForLine(expectedLines[i])
          ])

      it "indents allman-style curly braces", ->
        expectPreservedIndentation """
          if (a)
          {
            for (;;)
            {
              do
              {
                while (b)
                {
                  c();
                }
              }
              while (d)
            }
          }
        """

      it "indents non-allman-style curly braces", ->
        expectPreservedIndentation """
          if (a) {
            for (;;) {
              do {
                while (b) {
                  c();
                }
              } while (d)
            }
          }
        """

      it "indents function arguments", ->
        expectPreservedIndentation """
          a(
            b,
            c(
              d
            )
          );
        """

      it "indents array and struct literals", ->
        expectPreservedIndentation """
          some_t a[3] = {
            { .b = c },
            { .b = c, .d = {1, 2} },
          };
        """
