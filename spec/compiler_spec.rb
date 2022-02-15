require "lexer"
require "parser"
require "compiler"

def comp_init_module
  "let pea_module;
pea_module = Record.new([

], List.new([]));\n"
end

describe Compiler do
  # TODO: do something better for tests
  Compiler.use_std_lib = false

  context "literals" do
    it "1" do
      program = "1"
      tokens = Lexer::tokenize(program)
      ast = Parser.new(tokens, program).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("#{comp_init_module}Int.new(1);")
    end
    it "234.234" do
      program = "234.234"
      tokens = Lexer::tokenize(program)
      ast = Parser.new(tokens, program).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("#{comp_init_module}Float.new(234.234);")
    end
    it "\"string\"" do
      program = "\"string\""
      tokens = Lexer::tokenize(program)
      ast = Parser.new(tokens, program).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("#{comp_init_module}Str.new(`string`);")
    end
    it "[1, 2.3]" do
      program = "[1, 2.3]"
      tokens = Lexer::tokenize(program)
      ast = Parser.new(tokens, program).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("#{comp_init_module}List.new([Int.new(1), Float.new(2.3)]);")
    end
    it "{a: 3, b: [1, 2.3, \"s\"]}" do
      program = "{a: 3, b: [1, 2.3, \"s\"]}"
      tokens = Lexer::tokenize(program)
      ast = Parser.new(tokens, program).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("#{comp_init_module}Record.new([
  [Sym.new(\"a\"), Int.new(3)],
  [Sym.new(\"b\"), List.new([Int.new(1), Float.new(2.3), Str.new(`s`)])]
], List.new([]));")
    end
    it "{a: 3, b: [1, 2.3, \"s\"], c: { d: 3 }}" do
      program = "{a: 3, b: [1, 2.3, \"s\"], c: { d: 3 }}"
      tokens = Lexer::tokenize(program)
      ast = Parser.new(tokens, program).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("#{comp_init_module}Record.new([
  [Sym.new(\"a\"), Int.new(3)],
  [Sym.new(\"b\"), List.new([Int.new(1), Float.new(2.3), Str.new(`s`)])],
  [Sym.new(\"c\"), Record.new([
    [Sym.new(\"d\"), Int.new(3)]
  ], List.new([]))]
], List.new([]));")
    end
  end
end
