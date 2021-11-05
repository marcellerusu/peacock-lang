require "lexer"
require "parser"

describe Parser do
  context "assignment" do
    it "a := 3" do
      tokens = Lexer.new("a := 3").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :assign,
         sym: "a",
         line: 0,
         column: 0,
         expr: { node_type: :int_lit,
                 line: 0,
                 column: 5,
                 value: 3 } },
      ])
    end
    it "a := \"3\"" do
      tokens = Lexer.new("a := \"3\"").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :assign,
         sym: "a",
         line: 0,
         column: 0,
         expr: { node_type: :str_lit,
                 line: 0,
                 column: 5,
                 value: "3" } },
      ])
    end
    it "a := 25.32" do
      tokens = Lexer.new("a := 25.32").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :assign,
         sym: "a",
         line: 0,
         column: 0,
         expr: { node_type: :float_lit,
                 line: 0,
                 column: 5,
                 value: 25.32 } },
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
          value: "symbol" },
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
    it "a := fn => 1" do
      tokens = Lexer.new("a := fn => 1").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :assign,
         line: 0,
         column: 0,
         sym: "a",
         expr: {
          node_type: :function,
          line: 0,
          column: 5,
          args: [],
          body: [{
            node_type: :return,
            line: 0,
            column: 11,
            expr: {
              node_type: :int_lit,
              line: 0,
              column: 11,
              value: 1,
            },
          }],
        } },
      ])
    end
    it "id := fn x => x" do
      tokens = Lexer.new("id := fn x => x".strip).tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :assign,
         line: 0,
         column: 0,
         sym: "id",
         expr: {
          node_type: :function,
          line: 0,
          column: 6,
          args: [
            { node_type: :function_argument,
              line: 0,
              column: 9,
              sym: "x" },
          ],
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
         args: [
          { node_type: :identifier_lookup,
            line: 0,
            column: 0,
            sym: "a" },
          { node_type: :identifier_lookup,
            line: 0,
            column: 4,
            sym: "b" },
        ],
         expr: { node_type: :identifier_lookup,
                 line: 0,
                 column: 2,
                 sym: "Peacock.plus" } },
      ])
    end

    it "1.5 + 2.4" do
      tokens = Lexer.new("1.5 + 2.4").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :function_call,
         line: 0,
         column: 4,
         args: [
          {
            node_type: :float_lit,
            line: 0,
            column: 0,
            value: 1.5,
          }, {
            node_type: :float_lit,
            line: 0,
            column: 6,
            value: 2.4,
          },
        ],
         expr: { node_type: :identifier_lookup,
                 line: 0,
                 column: 4,
                 sym: "Peacock.plus" } },
      ])
    end

    it "add a b = a + b" do
      tokens = Lexer.new("add a b = a + b").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :declare,
         line: 0,
         column: 0,
         sym: "add",
         expr: {
          node_type: :function,
          line: 0,
          column: 0,
          args: [
            { node_type: :function_argument,
              line: 0,
              column: 4,
              sym: "a" },
            { node_type: :function_argument,
              line: 0,
              column: 6,
              sym: "b" },
          ],
          body: [{
            node_type: :return,
            line: 0,
            column: 10,
            expr: {
              node_type: :function_call,
              line: 0,
              column: 12,
              args: [
                { node_type: :identifier_lookup,
                  line: 0,
                  column: 10,
                  sym: "a" },
                { node_type: :identifier_lookup,
                  line: 0,
                  column: 14,
                  sym: "b" },
              ],
              expr: { node_type: :identifier_lookup,
                      line: 0,
                      column: 12,
                      sym: "Peacock.plus" },
            },
          }],
        } },
      ])
    end
    it "add a b = return a + b" do
      tokens = Lexer.new("
add a b =
  return a + b
".strip).tokenize
      ast = Parser.new(tokens).parse!
      # puts "#{ast}"
      expect(ast).to eq([
        { node_type: :declare,
         line: 0,
         column: 0,
         sym: "add",
         expr: {
          node_type: :function,
          line: 0,
          column: 0,
          args: [
            { node_type: :function_argument,
              line: 0,
              column: 4,
              sym: "a" },
            { node_type: :function_argument,
              line: 0,
              column: 6,
              sym: "b" },
          ],
          body: [{
            node_type: :return,
            line: 1,
            column: 2,
            expr: {
              node_type: :function_call,
              line: 1,
              column: 11,
              args: [
                { node_type: :identifier_lookup,
                  line: 1,
                  column: 9,
                  sym: "a" },
                { node_type: :identifier_lookup,
                  line: 1,
                  column: 13,
                  sym: "b" },
              ],
              expr: { node_type: :identifier_lookup,
                      line: 1,
                      column: 11,
                      sym: "Peacock.plus" },
            },
          }],
        } },
      ])
    end

    it "add(1, 2)" do
      tokens = Lexer.new("add(1, 2)").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq(
        [
          { node_type: :function_call,
           line: 0,
           column: 0,
           args: [{ node_type: :int_lit,
                    line: 0,
                    column: 4,
                    value: 1 },
                  { node_type: :int_lit,
                    line: 0,
                    column: 7,
                    value: 2 }],
           expr: { node_type: :identifier_lookup,
                   line: 0,
                   column: 0,
                   sym: "add" } },
        ]
      )
    end
  end

  context "if expressions" do
    it "if true end" do
      tokens = Lexer.new("if true end").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :if,
          line: 0,
          column: 0,
          expr: { node_type: :bool_lit,
                  line: 0,
                  column: 3,
                  value: true },
          pass: [],
          fail: [] },
      ])
    end
    it "if true else end" do
      tokens = Lexer.new("if true else end").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :if,
          line: 0,
          column: 0,
          expr: { node_type: :bool_lit,
                  line: 0,
                  column: 3,
                  value: true },
          pass: [],
          fail: [] },
      ])
    end
    it "if true else if false end" do
      tokens = Lexer.new("if true else if false end").tokenize
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :if,
         line: 0,
         column: 0,
         expr: { node_type: :bool_lit,
                 line: 0,
                 column: 3,
                 value: true },
         pass: [],
         fail: [
          { node_type: :if,
            line: 0,
            column: 13,
            expr: { node_type: :bool_lit,
                    line: 0,
                    column: 16,
                    value: false },
            pass: [],
            fail: [] },
        ] },
      ])
    end
  end

  context "statements" do
    it "statements in multiple lines" do
      tokens = Lexer.new("
a := 1

a := 1".strip).tokenize
      # puts "#{tokens}"
      ast = Parser.new(tokens).parse!
      expect(ast).to eq([
        { node_type: :assign,
         column: 0,
         line: 0,
         sym: "a",
         expr: { node_type: :int_lit,
                 line: 0,
                 column: 5,
                 value: 1 } },
        { node_type: :assign,
         column: 0,
         line: 2,
         sym: "a",
         expr: { node_type: :int_lit,
                 line: 2,
                 column: 5,
                 value: 1 } },
      ])
    end
  end
end
