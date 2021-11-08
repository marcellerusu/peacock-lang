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
      expect(js).to eq("1;")
    end
    it "234.234" do
      tokens = Lexer::tokenize("234.234")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("234.234;")
    end
    it "\"string\"" do
      tokens = Lexer::tokenize("\"string\"")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("\"string\";")
    end
    it "[1, 2.3]" do
      tokens = Lexer::tokenize("[1, 2.3]")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("[1, 2.3];")
    end
    it "{a: 3, b: [1, 2.3, \"s\"]}" do
      tokens = Lexer::tokenize("{a: 3, b: [1, 2.3, \"s\"]}")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("{
  \"a\": 3,
  \"b\": [1, 2.3, \"s\"]
};")
    end
    it "{a: 3, b: [1, 2.3, \"s\"], c: { d: 3 }}" do
      # TODO: fix indent on object
      tokens = Lexer::tokenize("{a: 3, b: [1, 2.3, \"s\"], c: { d: 3 }}")
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("{
  \"a\": 3,
  \"b\": [1, 2.3, \"s\"],
  \"c\": {
    \"d\": 3
  }
};")
    end
  end
end
