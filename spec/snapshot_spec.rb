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
  it "2022-06-20 21:58:14 -0400" do
    ast = parse("def add(a, b)
  return a + b
end
")
    expect(ast).to eq([{ "klass" => "AST::MultilineDefWithArgs", "name" => "add", "args" => ["a", "b"], "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "pos" => 23 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "pos" => 27 }, "pos" => 23 }, "pos" => 16 }], "pos" => 0 }])
  end
  it "2022-06-20 22:01:23 -0400" do
    ast = parse("def add(a, b)
  a + b
end
")
    expect(ast).to eq([{ "klass" => "AST::MultilineDefWithArgs", "name" => "add", "args" => ["a", "b"], "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "pos" => 16 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "pos" => 20 }, "pos" => 16 }, "pos" => 16 }], "pos" => 0 }])
  end
  it "2022-06-21 09:48:20 -0400" do
    ast = parse('add(1, "10", [1, 2])')
    expect(ast).to eq([{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Int", "value" => 1, "pos" => 4 }, { "klass" => "AST::SimpleString", "value" => "10", "pos" => 7 }, { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "pos" => 14 }, { "klass" => "AST::Int", "value" => 2, "pos" => 17 }], "pos" => 13 }], "expr" => { "klass" => "AST::IdLookup", "value" => "add", "pos" => 0 }, "pos" => 3 }])
  end
  it "2022-06-21 09:50:25 -0400" do
    ast = parse("def add(a, b) = a + b

console.log(add(10, 20))")
    expect(ast).to eq([{ "klass" => "AST::SingleLineDefWithArgs", "name" => "add", "args" => ["a", "b"], "return_value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "pos" => 16 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "pos" => 20 }, "pos" => 16 }, "pos" => 0 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Int", "value" => 10, "pos" => 39 }, { "klass" => "AST::Int", "value" => 20, "pos" => 43 }], "expr" => { "klass" => "AST::IdLookup", "value" => "add", "pos" => 35 }, "pos" => 38 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "pos" => 23 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "pos" => 31 }, "pos" => 30 }, "pos" => 34 }])
  end
  it "2022-06-21 09:52:49 -0400" do
    ast = parse("def add(a, b) = a + b

console.log add(10, 20)")
    expect(ast).to eq([{ "klass" => "AST::SingleLineDefWithArgs", "name" => "add", "args" => ["a", "b"], "return_value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "pos" => 16 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "pos" => 20 }, "pos" => 16 }, "pos" => 0 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Int", "value" => 10, "pos" => 39 }, { "klass" => "AST::Int", "value" => 20, "pos" => 43 }], "expr" => { "klass" => "AST::IdLookup", "value" => "add", "pos" => 35 }, "pos" => 38 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "pos" => 23 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "pos" => 31 }, "pos" => 30 }, "pos" => 30 }])
  end
  it "2022-06-21 15:21:36 -0400" do
    ast = parse('double := #{ % * 2 }')
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "double", "expr" => { "klass" => "AST::ShortFn", "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::AnonIdLookup", "pos" => 13 }, "type" => :*, "rhs" => { "klass" => "AST::Int", "value" => 2, "pos" => 17 }, "pos" => 13 }, "pos" => 10 }, "pos" => 0 }])
  end
  it "2022-06-21 15:21:51 -0400" do
    ast = parse("double := () => 10 * 2

console.log double()")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "double", "expr" => { "klass" => "AST::SingleLineArrowFnWithoutArgs", "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::Int", "value" => 10, "pos" => 16 }, "type" => :*, "rhs" => { "klass" => "AST::Int", "value" => 2, "pos" => 21 }, "pos" => 16 }, "pos" => 10 }, "pos" => 0 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::FnCall", "args" => [], "expr" => { "klass" => "AST::IdLookup", "value" => "double", "pos" => 36 }, "pos" => 42 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "pos" => 24 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "pos" => 32 }, "pos" => 31 }, "pos" => 31 }])
  end
  it "2022-06-21 15:28:11 -0400" do
    ast = parse("double := (x) => x * 2
")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "double", "expr" => { "klass" => "AST::SingleLineArrowFnWithArgs", "args" => ["x"], "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "x", "pos" => 17 }, "type" => :*, "rhs" => { "klass" => "AST::Int", "value" => 2, "pos" => 21 }, "pos" => 17 }, "pos" => 10 }, "pos" => 0 }])
  end
  it "2022-06-21 15:37:31 -0400" do
    ast = parse('double := x => x * 2
')
    expect(ast).to eq([{"klass"=>"AST::SimpleAssignment", "name"=>"double", "expr"=>{"klass"=>"AST::SingleLineArrowFnWithOneArg", "arg"=>"x", "return_expr"=>{"klass"=>"AST::Op", "lhs"=>{"klass"=>"AST::IdLookup", "value"=>"x", "pos"=>15}, "type"=>:*, "rhs"=>{"klass"=>"AST::Int", "value"=>2, "pos"=>19}, "pos"=>15}, "pos"=>10}, "pos"=>0}])
  end
end