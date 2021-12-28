require "lexer"
require "parser"
require "compiler"

describe Compiler do
  # TODO: do something better for tests
  Compiler.use_std_lib = false

  context "literals" do
    it "1" do
      tokens = Lexer::tokenize("1")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("Int.create(1);")
    end
    it "234.234" do
      tokens = Lexer::tokenize("234.234")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("Float.create(234.234);")
    end
    it "\"string\"" do
      tokens = Lexer::tokenize("\"string\"")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("Str.create(\"string\");")
    end
    it "[1, 2.3]" do
      tokens = Lexer::tokenize("[1, 2.3]")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("List.create([Int.create(1), Float.create(2.3)]);")
    end
    it "{a: 3, b: [1, 2.3, \"s\"]}" do
      tokens = Lexer::tokenize("{a: 3, b: [1, 2.3, \"s\"]}")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("Record.create({
  [Peacock.symbol('a')]: Int.create(3),
  [Peacock.symbol('b')]: List.create([Int.create(1), Float.create(2.3), Str.create(\"s\")])
});")
    end
    it "{a: 3, b: [1, 2.3, \"s\"], c: { d: 3 }}" do
      # TODO: fix indent on record
      tokens = Lexer::tokenize("{a: 3, b: [1, 2.3, \"s\"], c: { d: 3 }}")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("Record.create({
  [Peacock.symbol('a')]: Int.create(3),
  [Peacock.symbol('b')]: List.create([Int.create(1), Float.create(2.3), Str.create(\"s\")]),
  [Peacock.symbol('c')]: Record.create({
    [Peacock.symbol('d')]: Int.create(3)
  })
});")
    end
  end
end
