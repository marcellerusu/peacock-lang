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
      tokens = Lexer::tokenize("1")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("#{comp_init_module}Int.new(1);")
    end
    it "234.234" do
      tokens = Lexer::tokenize("234.234")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("#{comp_init_module}Float.new(234.234);")
    end
    it "\"string\"" do
      tokens = Lexer::tokenize("\"string\"")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("#{comp_init_module}Str.new(`string`);")
    end
    it "[1, 2.3]" do
      tokens = Lexer::tokenize("[1, 2.3]")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("#{comp_init_module}List.new([Int.new(1), Float.new(2.3)]);")
    end
    it "{a: 3, b: [1, 2.3, \"s\"]}" do
      tokens = Lexer::tokenize("{a: 3, b: [1, 2.3, \"s\"]}")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("#{comp_init_module}Record.new([
  [Sym.new(Peacock.symbol(\"a\")), Int.new(3)],
  [Sym.new(Peacock.symbol(\"b\")), List.new([Int.new(1), Float.new(2.3), Str.new(`s`)])]
], List.new([]));")
    end
    it "{a: 3, b: [1, 2.3, \"s\"], c: { d: 3 }}" do
      tokens = Lexer::tokenize("{a: 3, b: [1, 2.3, \"s\"], c: { d: 3 }}")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("#{comp_init_module}Record.new([
  [Sym.new(Peacock.symbol(\"a\")), Int.new(3)],
  [Sym.new(Peacock.symbol(\"b\")), List.new([Int.new(1), Float.new(2.3), Str.new(`s`)])],
  [Sym.new(Peacock.symbol(\"c\")), Record.new([
    [Sym.new(Peacock.symbol(\"d\")), Int.new(3)]
  ], List.new([]))]
], List.new([]));")
    end
  end
end
