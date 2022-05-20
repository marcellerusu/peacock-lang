require "lexer"
require "parser"
require "compiler"

describe Compiler do
  # TODO: do something better for tests
  Compiler.use_std_lib = false

  context "literals" do
    it "1" do
      program = "1"
      tokens = Lexer::tokenize(program)
      ast = Parser.new(tokens, program).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("1;")
    end
    it "234.234" do
      program = "234.234"
      tokens = Lexer::tokenize(program)
      ast = Parser.new(tokens, program).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("234.234;")
    end
    it "\"string\"" do
      program = "\"string\""
      tokens = Lexer::tokenize(program)
      ast = Parser.new(tokens, program).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("`string`;")
    end
    it "[1, 2.3]" do
      program = "[1, 2.3]"
      tokens = Lexer::tokenize(program)
      ast = Parser.new(tokens, program).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("[1, 2.3];")
    end
    it "{a: 3, b: [1, 2.3, \"s\"]}" do
      program = "{a: 3, b: [1, 2.3, \"s\"]}"
      tokens = Lexer::tokenize(program)
      ast = Parser.new(tokens, program).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("{
  a: 3,
  b: [1, 2.3, `s`]
};")
    end
    it "{a: 3, b: [1, 2.3, \"s\"], c: { d: 3 }}" do
      program = "{a: 3, b: [1, 2.3, \"s\"], c: { d: 3 }}"
      tokens = Lexer::tokenize(program)
      ast = Parser.new(tokens, program).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("{
  a: 3,
  b: [1, 2.3, `s`],
  c: {
    d: 3
  }
};")
    end
  end
end
