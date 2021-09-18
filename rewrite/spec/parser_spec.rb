require "lexer"
require "parser"

describe Parser do
  context "assignment" do
    it "let a = 3" do
      tokens = Lexer.new("let a = 3").tokenize
      ast = Parser.new(tokens).parse
      expect(ast).to eq([
        { type: :declare,
         mutable: false,
         sym: "a",
         line: 0,
         column: 4,
         expr: { type: :int_lit,
                 line: 0,
                 column: 8,
                 value: 3 } },
      ])
    end
    it "let a = \"3\"" do
      tokens = Lexer.new("let a = \"3\"").tokenize
      ast = Parser.new(tokens).parse
      expect(ast).to eq([
        { type: :declare,
         mutable: false,
         sym: "a",
         line: 0,
         column: 4,
         expr: { type: :str_lit,
                 line: 0,
                 column: 8,
                 value: "3" } },
      ])
    end
    it "let a = 25.32" do
      tokens = Lexer.new("let a = 25.32").tokenize
      ast = Parser.new(tokens).parse
      expect(ast).to eq([
        { type: :declare,
         mutable: false,
         sym: "a",
         line: 0,
         column: 4,
         expr: { type: :float_lit,
                 line: 0,
                 column: 8,
                 value: 25.32 } },
      ])
    end
    it "let mut a = 3" do
      tokens = Lexer.new("let mut a = 3").tokenize
      ast = Parser.new(tokens).parse
      expect(ast).to eq([
        { type: :declare,
         mutable: true,
         sym: "a",
         line: 0,
         column: 8,
         expr: { type: :int_lit,
                 line: 0,
                 column: 12,
                 value: 3 } },
      ])
    end
  end
  context "literals" do
    it "true" do
      tokens = Lexer.new("true").tokenize
      ast = Parser.new(tokens).parse
      expect(ast).to eq([
        { type: :bool_lit,
          line: 0,
          column: 0,
          value: true },
      ])
    end
    it "false" do
      tokens = Lexer.new("false").tokenize
      ast = Parser.new(tokens).parse
      expect(ast).to eq([
        { type: :bool_lit,
          line: 0,
          column: 0,
          value: false },
      ])
    end
    it "[]" do
      tokens = Lexer.new("[]").tokenize
      ast = Parser.new(tokens).parse
      expect(ast).to eq([
        { type: :array_lit,
          line: 0,
          column: 0,
          value: [] },
      ])
    end
    it "[false]" do
      tokens = Lexer.new("[false]").tokenize
      ast = Parser.new(tokens).parse
      expect(ast).to eq([
        { type: :array_lit,
         line: 0,
         column: 0,
         value: [{ type: :bool_lit,
                   line: 0,
                   column: 1,
                   value: false }] },
      ])
    end
    it "[false, 1, \"3\"]" do
      tokens = Lexer.new("[false, 1, \"3\"]").tokenize
      ast = Parser.new(tokens).parse
      expect(ast).to eq([
        { type: :array_lit,
         line: 0,
         column: 0,
         value: [{ type: :bool_lit,
                   line: 0,
                   column: 1,
                   value: false },
                 { type: :int_lit,
                   line: 0,
                   column: 8,
                   value: 1 },
                 { type: :str_lit,
                   line: 0,
                   column: 11,
                   value: "3" }] },
      ])
    end
    it "{ a: 3.5 }" do
      tokens = Lexer.new("{ a: 3.5 }").tokenize
      ast = Parser.new(tokens).parse
      expect(ast).to eq([
        { type: :record_lit,
         line: 0,
         column: 0,
         value: {
          "a" => { type: :float_lit,
                   line: 0,
                   column: 5,
                   value: 3.5 },
        } },
      ])
    end
    it "{a: [false, 1, \"3\"]}" do
      tokens = Lexer.new("{a: [false, 1, \"3\"]}").tokenize
      ast = Parser.new(tokens).parse
      expect(ast).to eq([
        { type: :record_lit,
         line: 0,
         column: 0,
         value: {
          "a" => { type: :array_lit,
                  line: 0,
                  column: 4,
                  value: [{ type: :bool_lit,
                            line: 0,
                            column: 5,
                            value: false },
                          { type: :int_lit,
                            line: 0,
                            column: 12,
                            value: 1 },
                          { type: :str_lit,
                            line: 0,
                            column: 15,
                            value: "3" }] },
        } },
      ])
    end
    it "[{ a: 3.5 }]" do
      tokens = Lexer.new("[{ a: 3.5 }]").tokenize
      ast = Parser.new(tokens).parse
      expect(ast).to eq([
        { type: :array_lit,
         line: 0,
         column: 0,
         value: [{ type: :record_lit,
                  line: 0,
                  column: 1,
                  value: { "a" => { type: :float_lit,
                                   line: 0,
                                   column: 6,
                                   value: 3.5 } } }] },
      ])
    end
  end
  context "functions" do
    it "let a = () => 1" do
      tokens = Lexer.new("let a = () => 1").tokenize
      ast = Parser.new(tokens).parse
      expect(ast).to eq([
        { type: :declare,
         mutable: false,
         line: 0,
         column: 4,
         sym: "a",
         expr: {
          type: :function,
          line: 0,
          column: 8,
          arg: nil,
          body: [{
            type: :return,
            line: 0,
            column: 11,
            expr: {
              type: :int_lit,
              line: 0,
              column: 14,
              value: 1,
            },
          }],
        } },
      ])
    end
    it "let a = () => { return 1 }" do
      tokens = Lexer.new("
let a = () => {
  return 1
}
      ".strip).tokenize
      ast = Parser.new(tokens).parse
      expect(ast).to eq([
        { type: :declare,
         mutable: false,
         line: 0,
         column: 4,
         sym: "a",
         expr: {
          type: :function,
          line: 0,
          column: 8,
          arg: nil,
          body: [{
            type: :return,
            line: 1,
            column: 2,
            expr: {
              type: :int_lit,
              line: 1,
              column: 9,
              value: 1,
            },
          }],
        } },
      ])
    end
  end
end
