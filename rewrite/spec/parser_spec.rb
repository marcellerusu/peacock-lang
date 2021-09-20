require "lexer"
require "parser"

describe Parser do
  context "assignment" do
    it "let a = 3" do
      tokens = Lexer.new("let a = 3").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :declare,
         mutable: false,
         sym: "a",
         line: 0,
         column: 4,
         expr: { node_type: :int_lit,
                 line: 0,
                 column: 8,
                 value: 3 } },
      ])
    end
    it "let a = \"3\"" do
      tokens = Lexer.new("let a = \"3\"").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :declare,
         mutable: false,
         sym: "a",
         line: 0,
         column: 4,
         expr: { node_type: :str_lit,
                 line: 0,
                 column: 8,
                 value: "3" } },
      ])
    end
    it "let a = 25.32" do
      tokens = Lexer.new("let a = 25.32").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :declare,
         mutable: false,
         sym: "a",
         line: 0,
         column: 4,
         expr: { node_type: :float_lit,
                 line: 0,
                 column: 8,
                 value: 25.32 } },
      ])
    end
    it "let mut a = 3" do
      tokens = Lexer.new("let mut a = 3").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :declare,
         mutable: true,
         sym: "a",
         line: 0,
         column: 8,
         expr: { node_type: :int_lit,
                 line: 0,
                 column: 12,
                 value: 3 } },
      ])
    end
  end
  context "literals" do
    it "true" do
      tokens = Lexer.new("true").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :bool_lit,
          line: 0,
          column: 0,
          value: true },
      ])
    end
    it "false" do
      tokens = Lexer.new("false").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :bool_lit,
          line: 0,
          column: 0,
          value: false },
      ])
    end
    it ":symbol" do
      tokens = Lexer.new(":symbol").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :symbol,
          line: 0,
          column: 0,
          value: ":symbol" },
      ])
    end
    it "[]" do
      tokens = Lexer.new("[]").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :array_lit,
          line: 0,
          column: 0,
          value: [] },
      ])
    end
    it "[false]" do
      tokens = Lexer.new("[false]").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :array_lit,
         line: 0,
         column: 0,
         value: [{ node_type: :bool_lit,
                   line: 0,
                   column: 1,
                   value: false }] },
      ])
    end
    it "[false, 1, \"3\"]" do
      tokens = Lexer.new("[false, 1, \"3\"]").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :array_lit,
         line: 0,
         column: 0,
         value: [{ node_type: :bool_lit,
                   line: 0,
                   column: 1,
                   value: false },
                 { node_type: :int_lit,
                   line: 0,
                   column: 8,
                   value: 1 },
                 { node_type: :str_lit,
                   line: 0,
                   column: 11,
                   value: "3" }] },
      ])
    end
    it "{ a: 3.5 }" do
      tokens = Lexer.new("{ a: 3.5 }").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :record_lit,
         line: 0,
         column: 0,
         value: {
          "a" => { node_type: :float_lit,
                   line: 0,
                   column: 5,
                   value: 3.5 },
        } },
      ])
    end
    it "{a: [false, 1, \"3\"]}" do
      tokens = Lexer.new("{a: [false, 1, \"3\"]}").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :record_lit,
         line: 0,
         column: 0,
         value: {
          "a" => { node_type: :array_lit,
                  line: 0,
                  column: 4,
                  value: [{ node_type: :bool_lit,
                            line: 0,
                            column: 5,
                            value: false },
                          { node_type: :int_lit,
                            line: 0,
                            column: 12,
                            value: 1 },
                          { node_type: :str_lit,
                            line: 0,
                            column: 15,
                            value: "3" }] },
        } },
      ])
    end
    it "[{ a: 3.5 }]" do
      tokens = Lexer.new("[{ a: 3.5 }]").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :array_lit,
         line: 0,
         column: 0,
         value: [{ node_type: :record_lit,
                  line: 0,
                  column: 1,
                  value: { "a" => { node_type: :float_lit,
                                   line: 0,
                                   column: 6,
                                   value: 3.5 } } }] },
      ])
    end
  end
  context "functions" do
    it "let a = () => 1" do
      tokens = Lexer.new("let a = () => 1").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :declare,
         mutable: false,
         line: 0,
         column: 4,
         sym: "a",
         expr: {
          node_type: :function,
          line: 0,
          column: 8,
          arg: nil,
          body: [{
            node_type: :return,
            line: 0,
            column: 14,
            expr: {
              node_type: :int_lit,
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
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :declare,
         mutable: false,
         line: 0,
         column: 4,
         sym: "a",
         expr: {
          node_type: :function,
          line: 0,
          column: 8,
          arg: nil,
          body: [{
            node_type: :return,
            line: 1,
            column: 2,
            expr: {
              node_type: :int_lit,
              line: 1,
              column: 9,
              value: 1,
            },
          }],
        } },
      ])
    end
    it "let id = x => x" do
      tokens = Lexer.new("let id = x => x".strip).tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :declare,
         mutable: false,
         line: 0,
         column: 4,
         sym: "id",
         expr: {
          node_type: :function,
          line: 0,
          column: 9,
          arg: "x",
          body: [{
            node_type: :return,
            line: 0,
            column: 14,
            expr: {
              node_type: :identifier_lookup,
              line: 0,
              column: 14,
              sym: "x",
            },
          }],
        } },
      ])
    end

    it "a + b" do
      tokens = Lexer.new("a + b").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :function_call,
         line: 0,
         column: 2,
         arg: {
          node_type: :identifier_lookup,
          line: 0,
          column: 4,
          sym: "b",
        },
         expr: {
          node_type: :function_call,
          line: 0,
          column: 2,
          arg: {
            node_type: :identifier_lookup,
            line: 0,
            column: 0,
            sym: "a",
          },
          expr: {
            node_type: :identifier_lookup,
            line: 0,
            column: 2,
            sym: "Peacock.plus",
          },
        } },
      ])
    end
    it "let add = (a, b) => a + b" do
      tokens = Lexer.new("let add = (a, b) => a + b").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :declare,
         mutable: false,
         line: 0,
         column: 4,
         sym: "add",
         expr: {
          node_type: :function,
          line: 0,
          column: 11,
          arg: "a",
          body: [{
            node_type: :return,
            line: 0,
            column: 14,
            expr: {
              node_type: :function,
              line: 0,
              column: 14,
              arg: "b",
              body: [{
                node_type: :return,
                line: 0,
                column: 22,
                expr: {
                  node_type: :function_call,
                  line: 0,
                  column: 22,
                  arg: { node_type: :identifier_lookup,
                         line: 0,
                         column: 24,
                         sym: "b" },
                  expr: { node_type: :function_call,
                         line: 0,
                         column: 22,
                         arg: { node_type: :identifier_lookup,
                                line: 0,
                                column: 20,
                                sym: "a" },
                         expr: { node_type: :identifier_lookup,
                                 line: 0,
                                 column: 22,
                                 sym: "Peacock.plus" } },
                },
              }],
            },
          }],
        } },
      ])
    end
  end
end
