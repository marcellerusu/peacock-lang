require "lexer"
require "parser"
require "compiler"

describe Compiler do
  context "literals" do
    it "1" do
      tokens = Lexer.new("1").tokenize
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("1;")
    end
    it "234.234" do
      tokens = Lexer.new("234.234").tokenize
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("234.234;")
    end
    it "\"string\"" do
      tokens = Lexer.new("\"string\"").tokenize
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("\"string\";")
    end
    it "[1, 2.3]" do
      tokens = Lexer.new("[1, 2.3]").tokenize
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("[1, 2.3];")
    end
    it "{a: 3, b: [1, 2.3, \"s\"]}" do
      tokens = Lexer.new("{a: 3, b: [1, 2.3, \"s\"]}").tokenize
      ast = Parser.new(tokens).parse!
      js = Compiler.new(ast).eval.strip
      expect(js).to eq("{
  \"a\": 3,
  \"b\": [1, 2.3, \"s\"]
};")
    end
    it "{a: 3, b: [1, 2.3, \"s\"], c: { d: 3 }}" do
      # TODO: fix indent on object
      tokens = Lexer.new("{a: 3, b: [1, 2.3, \"s\"], c: { d: 3 }}").tokenize
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
