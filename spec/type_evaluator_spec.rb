require "type_evaluator"
require "lexer"
require "parser"

describe TypeEvaluator do
  context "literals" do
    it "3" do
      tokens = Lexer.new("3").tokenize
      ast = Parser.new(tokens).parse!
      ast_with_types = TypeEvaluator.new(ast).eval
      expect(ast_with_types).to eq([
        {
          node_type: :int_lit,
          line: 0,
          column: 0,
          type: { type: :int },
          value: 3,
        },
      ])
    end
    it ":symbol" do
      tokens = Lexer.new(":symbol").tokenize
      ast = Parser.new(tokens).parse!
      ast_with_types = TypeEvaluator.new(ast).eval
      expect(ast_with_types).to eq([
        {
          node_type: :symbol,
          line: 0,
          column: 0,
          type: { type: :symbol },
          value: "symbol",
        },
      ])
    end
    it "4.5" do
      tokens = Lexer.new("4.5").tokenize
      ast = Parser.new(tokens).parse!
      ast_with_types = TypeEvaluator.new(ast).eval
      expect(ast_with_types).to eq([
        {
          node_type: :float_lit,
          line: 0,
          column: 0,
          type: { type: :float },
          value: 4.5,
        },
      ])
    end
    it " \"some string\"" do
      tokens = Lexer.new(" \"some string\"").tokenize
      ast = Parser.new(tokens).parse!
      ast_with_types = TypeEvaluator.new(ast).eval
      expect(ast_with_types).to eq([
        {
          node_type: :str_lit,
          line: 0,
          column: 1,
          type: { type: :str },
          value: "some string",
        },
      ])
    end
    it "[1]" do
      tokens = Lexer.new("[1]").tokenize
      ast = Parser.new(tokens).parse!
      ast_with_types = TypeEvaluator.new(ast).eval
      expect(ast_with_types).to eq([
        {
          node_type: :array_lit,
          line: 0,
          column: 0,
          type: {
            type: :array,
            of: { type: :int },
          },
          value: [
            {
              node_type: :int_lit,
              value: 1,
              line: 0,
              column: 1,
            },
          ],
        },
      ])
    end
    it "[1, :sym]" do
      tokens = Lexer.new("[1, :sym]").tokenize
      ast = Parser.new(tokens).parse!
      ast_with_types = TypeEvaluator.new(ast).eval
      expect(ast_with_types).to eq([
        {
          node_type: :array_lit,
          type: {
            type: :array,
            of: {
              type: :union,
              of: [{ type: :int }, { type: :symbol }],
            },
          },
          line: 0,
          column: 0,
          value: [
            {
              node_type: :int_lit,
              value: 1,
              line: 0,
              column: 1,
            },
            {
              node_type: :symbol,
              value: "sym",
              line: 0,
              column: 4,
            },
          ],
        },
      ])
    end
    it "{ a: 3 }" do
      tokens = Lexer.new("{ a: 3 }").tokenize
      ast = Parser.new(tokens).parse!
      ast_with_types = TypeEvaluator.new(ast).eval
      expect(ast_with_types).to eq([
        node_type: :record_lit,
        type: {
          type: :record,
          of: {
            "a" => { type: :int },
          },
        },
        line: 0,
        column: 0,
        value: {
          "a" => {
            node_type: :int_lit,
            line: 0,
            column: 5,
            value: 3,
          },
        },
      ])
    end
  end
end
