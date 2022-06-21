require "ast"
require "parser"

def parse(str)
  tokens = Lexer::tokenize(str.strip)
  ast = Parser.new(tokens, str).parse!
  ast.map(&:to_h)
end

context "snapshot" do
  it "2022-06-20 15:02:34 -0400" do
    ast = parse("a := 1")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "a", "expr" => { "klass" => "AST::Int", "value" => 1, "pos" => 5 }, "pos" => 0 }])
  end
  it "2022-06-20 15:09:48 -0400" do
    ast = parse("a := 1.1")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "a", "expr" => { "klass" => "AST::Float", "value" => 1.1, "pos" => 5 }, "pos" => 0 }])
  end
  it "2022-06-20 15:30:50 -0400" do
    ast = parse('a := [1, "20"]')
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "a", "expr" => { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "pos" => 6 }, { "klass" => "AST::SimpleString", "value" => "20", "pos" => 9 }], "pos" => 5 }, "pos" => 0 }])
  end
  it "2022-06-20 15:48:58 -0400" do
    ast = parse("a := {
  b: 10
}")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "a", "expr" => [["b", { "klass" => "AST::Int", "value" => 10, "pos" => 12 }]], "pos" => 0 }])
  end
  it "2022-06-20 20:06:22 -0400" do
    ast = parse("a := a + 10")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "a", "expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "pos" => 5 }, "type" => :+, "rhs" => { "klass" => "AST::Int", "value" => 10, "pos" => 9 }, "pos" => 5 }, "pos" => 0 }])
  end
  it "2022-06-20 21:32:08 -0400" do
    ast = parse("def add
  a := 10
end
")
    expect(ast).to eq([{ "klass" => "AST::MultilineDefWithoutArgs", "name" => "add", "body" => [{ "klass" => "AST::SimpleAssignment", "name" => "a", "expr" => { "klass" => "AST::Int", "value" => 10, "pos" => 15 }, "pos" => 10 }, { "klass" => "AST::Return", "value" => { "klass" => "AST::IdLookup", "value" => "a", "pos" => 10 }, "pos" => 10 }], "pos" => 0 }])
  end
  it "2022-06-20 21:32:50 -0400" do
    ast = parse("def a = 10")
    expect(ast).to eq([{ "klass" => "AST::SingleLineDefWithNoArgs", "name" => "a", "return_value" => { "klass" => "AST::Int", "value" => 10, "pos" => 8 }, "pos" => 0 }])
  end
  it "2022-06-20 21:33:16 -0400" do
    ast = parse("def add(a, b) = a + b")
    expect(ast).to eq([{ "klass" => "AST::SingleLineDefWithArgs", "name" => "add", "args" => ["a", "b"], "return_value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "pos" => 16 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "pos" => 20 }, "pos" => 16 }, "pos" => 0 }])
  end
end
