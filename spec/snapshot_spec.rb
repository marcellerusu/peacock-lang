require "ast"
require "parser"

def parse(str)
  tokens = Lexer::tokenize(str.strip)
  ast = Parser.new(tokens, str).parse!
  ast.map(&:to_h)
end

context "snapshot" do
  it "2022-07-08 14:21:48 -0400" do
    ast = parse("a := 1")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "a", "expr" => { "klass" => "AST::Int", "value" => 1, "start_pos" => 5, "end_pos" => 6 }, "start_pos" => 0, "end_pos" => 6 }])
  end
  it "2022-07-08 14:22:01 -0400" do
    ast = parse("a := 1.1")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "a", "expr" => { "klass" => "AST::Float", "value" => 1.1, "start_pos" => 5, "end_pos" => 8 }, "start_pos" => 0, "end_pos" => 8 }])
  end
  it "2022-07-08 14:26:08 -0400" do
    ast = parse('a := [1, "20"]')
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "a", "expr" => { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 6, "end_pos" => 7 }, { "klass" => "AST::SimpleString", "value" => "20", "start_pos" => 9, "end_pos" => 13 }], "start_pos" => 5, "end_pos" => 14 }, "start_pos" => 0, "end_pos" => 14 }])
  end
  it "2022-07-08 14:27:03 -0400" do
    ast = parse("a := a + 10")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "a", "expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "start_pos" => 5, "end_pos" => 6 }, "type" => :+, "rhs" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 9, "end_pos" => 11 }, "start_pos" => 5, "end_pos" => 11 }, "start_pos" => 0, "end_pos" => 11 }])
  end
  it "2022-07-08 14:35:38 -0400" do
    ast = parse('add(1, "10", [1, 2])')
    expect(ast).to eq([{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 4, "end_pos" => 5 }, { "klass" => "AST::SimpleString", "value" => "10", "start_pos" => 7, "end_pos" => 11 }, { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 14, "end_pos" => 15 }, { "klass" => "AST::Int", "value" => 2, "start_pos" => 17, "end_pos" => 18 }], "start_pos" => 13, "end_pos" => 19 }], "expr" => { "klass" => "AST::IdLookup", "value" => "add", "start_pos" => 0, "end_pos" => 3 }, "start_pos" => 3, "end_pos" => 20 }])
  end
  it "2022-07-09 00:06:08 -0400" do
    ast = parse("double := () => 10 * 2

console.log double()")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "double", "expr" => { "klass" => "AST::SingleLineArrowFnWithoutArgs", "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 16, "end_pos" => 18 }, "type" => :*, "rhs" => { "klass" => "AST::Int", "value" => 2, "start_pos" => 21, "end_pos" => 22 }, "start_pos" => 16, "end_pos" => 22 }, "start_pos" => 10, "end_pos" => 22 }, "start_pos" => 0, "end_pos" => 22 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::FnCall", "args" => [], "expr" => { "klass" => "AST::IdLookup", "value" => "double", "start_pos" => 36, "end_pos" => 42 }, "start_pos" => 42, "end_pos" => 44 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 24, "end_pos" => 31 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 32, "end_pos" => 35 }, "start_pos" => 31, "end_pos" => 35 }, "start_pos" => 35, "end_pos" => 44 }])
  end
  it "2022-07-09 00:07:16 -0400" do
    ast = parse("double := x => x * 2")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "double", "expr" => { "klass" => "AST::SingleLineArrowFnWithOneArg", "arg" => "x", "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "x", "start_pos" => 15, "end_pos" => 16 }, "type" => :*, "rhs" => { "klass" => "AST::Int", "value" => 2, "start_pos" => 19, "end_pos" => 20 }, "start_pos" => 15, "end_pos" => 20 }, "start_pos" => 10, "end_pos" => 20 }, "start_pos" => 0, "end_pos" => 20 }])
  end
  it "2022-07-09 00:11:18 -0400" do
    ast = parse("arr := [1, 2, 3]

for elem of arr
  console.log elem
end")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "arr", "expr" => { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 8, "end_pos" => 9 }, { "klass" => "AST::Int", "value" => 2, "start_pos" => 11, "end_pos" => 12 }, { "klass" => "AST::Int", "value" => 3, "start_pos" => 14, "end_pos" => 15 }], "start_pos" => 7, "end_pos" => 16 }, "start_pos" => 0, "end_pos" => 16 }, { "klass" => "AST::SimpleForOfLoop", "iter_name" => "elem", "arr_expr" => { "klass" => "AST::IdLookup", "value" => "arr", "start_pos" => 30, "end_pos" => 33 }, "body" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "elem", "start_pos" => 48, "end_pos" => 52 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 36, "end_pos" => 43 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 44, "end_pos" => 47 }, "start_pos" => 43, "end_pos" => 47 }, "start_pos" => 47, "end_pos" => 52 }], "start_pos" => 18, "end_pos" => 56 }])
  end
  it "2022-07-09 00:12:09 -0400" do
    ast = parse("schema User = { id }")
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "User", "schema_expr" => [["id", { "klass" => "AST::SchemaCapture", "name" => "id", "start_pos" => 16, "end_pos" => 18 }]], "start_pos" => 0, "end_pos" => 20 }])
  end
  it "2022-07-09 00:12:45 -0400" do
    ast = parse("schema User = { id: 10 }")
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "User", "schema_expr" => [["id", { "klass" => "AST::Int", "value" => 10, "start_pos" => 20, "end_pos" => 22 }]], "start_pos" => 0, "end_pos" => 24 }])
  end
  it "2022-07-09 00:13:25 -0400" do
    ast = parse("function add(a, b) = a + b")
    expect(ast).to eq([{ "klass" => "AST::SingleLineDefWithArgs", "name" => "add", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "a", "start_pos" => 13, "end_pos" => 14 }, { "klass" => "AST::SimpleArg", "name" => "b", "start_pos" => 16, "end_pos" => 17 }], "start_pos" => 12, "end_pos" => 18 }, "return_value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "start_pos" => 21, "end_pos" => 22 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "start_pos" => 25, "end_pos" => 26 }, "start_pos" => 21, "end_pos" => 26 }, "start_pos" => 0, "end_pos" => 26 }])
  end
  it "2022-07-09 00:14:09 -0400" do
    ast = parse("function add(a, b)
  a + b
end")
    expect(ast).to eq([{ "klass" => "AST::MultilineDefWithArgs", "name" => "add", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "a", "start_pos" => 13, "end_pos" => 14 }, { "klass" => "AST::SimpleArg", "name" => "b", "start_pos" => 16, "end_pos" => 17 }], "start_pos" => 12, "end_pos" => 18 }, "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "start_pos" => 21, "end_pos" => 22 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "start_pos" => 25, "end_pos" => 26 }, "start_pos" => 21, "end_pos" => 26 }, "start_pos" => 21, "end_pos" => 26 }], "start_pos" => 0, "end_pos" => 30 }])
  end
  it "2022-07-09 00:20:44 -0400" do
    ast = parse("function add(a, b) = a + b

console.log(add(10, 20))")
    expect(ast).to eq([{ "klass" => "AST::SingleLineDefWithArgs", "name" => "add", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "a", "start_pos" => 13, "end_pos" => 14 }, { "klass" => "AST::SimpleArg", "name" => "b", "start_pos" => 16, "end_pos" => 17 }], "start_pos" => 12, "end_pos" => 18 }, "return_value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "start_pos" => 21, "end_pos" => 22 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "start_pos" => 25, "end_pos" => 26 }, "start_pos" => 21, "end_pos" => 26 }, "start_pos" => 0, "end_pos" => 26 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Int", "value" => 10, "start_pos" => 44, "end_pos" => 46 }, { "klass" => "AST::Int", "value" => 20, "start_pos" => 48, "end_pos" => 50 }], "expr" => { "klass" => "AST::IdLookup", "value" => "add", "start_pos" => 40, "end_pos" => 43 }, "start_pos" => 43, "end_pos" => 51 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 28, "end_pos" => 35 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 36, "end_pos" => 39 }, "start_pos" => 35, "end_pos" => 39 }, "start_pos" => 39, "end_pos" => 52 }])
  end
  it "2022-07-09 00:20:59 -0400" do
    ast = parse('double := #{ it * 2 }')
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "double", "expr" => { "klass" => "AST::ShortFn", "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::AnonIdLookup", "start_pos" => 13, "end_pos" => 15 }, "type" => :*, "rhs" => { "klass" => "AST::Int", "value" => 2, "start_pos" => 18, "end_pos" => 19 }, "start_pos" => 13, "end_pos" => 19 }, "start_pos" => 10, "end_pos" => 21 }, "start_pos" => 0, "end_pos" => 21 }])
  end
  it "2022-07-09 00:21:12 -0400" do
    ast = parse("double := (x) => x * 2")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "double", "expr" => { "klass" => "AST::SingleLineArrowFnWithArgs", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "x", "start_pos" => 11, "end_pos" => 12 }], "start_pos" => 10, "end_pos" => 13 }, "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "x", "start_pos" => 17, "end_pos" => 18 }, "type" => :*, "rhs" => { "klass" => "AST::Int", "value" => 2, "start_pos" => 21, "end_pos" => 22 }, "start_pos" => 17, "end_pos" => 22 }, "start_pos" => 10, "end_pos" => 22 }, "start_pos" => 0, "end_pos" => 22 }])
  end
  it "2022-07-09 00:21:24 -0400" do
    ast = parse('schema User = { id: #{ it > 10 } }')
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "User", "schema_expr" => [["id", { "klass" => "AST::ShortFn", "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::AnonIdLookup", "start_pos" => 23, "end_pos" => 25 }, "type" => :>, "rhs" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 28, "end_pos" => 30 }, "start_pos" => 23, "end_pos" => 30 }, "start_pos" => 20, "end_pos" => 32 }]], "start_pos" => 0, "end_pos" => 34 }])
  end
  it "2022-07-09 00:21:34 -0400" do
    ast = parse("function a() = 10")
    expect(ast).to eq([{ "klass" => "AST::SingleLineDefWithArgs", "name" => "a", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [], "start_pos" => 10, "end_pos" => 12 }, "return_value" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 15, "end_pos" => 17 }, "start_pos" => 0, "end_pos" => 17 }])
  end
  it "2022-07-09 00:21:57 -0400" do
    ast = parse("PMath := {
  add(a, b) => a + b,
}")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "PMath", "expr" => { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::ArrowMethodObjectEntry", "key_name" => "add", "value" => { "klass" => "AST::SingleLineArrowFnWithArgs", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "a", "start_pos" => 17, "end_pos" => 18 }, { "klass" => "AST::SimpleArg", "name" => "b", "start_pos" => 20, "end_pos" => 21 }], "start_pos" => 16, "end_pos" => 22 }, "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "start_pos" => 26, "end_pos" => 27 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "start_pos" => 30, "end_pos" => 31 }, "start_pos" => 26, "end_pos" => 31 }, "start_pos" => 16, "end_pos" => 31 }, "start_pos" => 13, "end_pos" => 31 }], "start_pos" => 9, "end_pos" => 34 }, "start_pos" => 0, "end_pos" => 34 }])
  end
  it "2022-07-09 00:22:08 -0400" do
    ast = parse("a := {
  b: 10
}")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "a", "expr" => { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "b", "value" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 12, "end_pos" => 14 }, "start_pos" => 9, "end_pos" => 14 }], "start_pos" => 5, "end_pos" => 16 }, "start_pos" => 0, "end_pos" => 16 }])
  end
  it "2022-07-09 00:22:19 -0400" do
    ast = parse("console.log a.b")
    expect(ast).to eq([{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "start_pos" => 12, "end_pos" => 13 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "start_pos" => 14, "end_pos" => 15 }, "start_pos" => 13, "end_pos" => 15 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 0, "end_pos" => 7 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 8, "end_pos" => 11 }, "start_pos" => 7, "end_pos" => 11 }, "start_pos" => 11, "end_pos" => 15 }])
  end
  it "2022-07-09 00:22:32 -0400" do
    ast = parse("schema User = { id }

user := { id: 10 }

User(user) := user

console.log user")
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "User", "schema_expr" => [["id", { "klass" => "AST::SchemaCapture", "name" => "id", "start_pos" => 16, "end_pos" => 18 }]], "start_pos" => 0, "end_pos" => 20 }, { "klass" => "AST::SimpleAssignment", "name" => "user", "expr" => { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "id", "value" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 36, "end_pos" => 38 }, "start_pos" => 32, "end_pos" => 38 }], "start_pos" => 30, "end_pos" => 40 }, "start_pos" => 22, "end_pos" => 40 }, { "klass" => "AST::SimpleSchemaAssignment", "schema_name" => "User", "name" => "user", "expr" => { "klass" => "AST::IdLookup", "value" => "user", "start_pos" => 56, "end_pos" => 60 }, "start_pos" => 42, "end_pos" => 60 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "user", "start_pos" => 74, "end_pos" => 78 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 62, "end_pos" => 69 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 70, "end_pos" => 73 }, "start_pos" => 69, "end_pos" => 73 }, "start_pos" => 73, "end_pos" => 78 }])
  end
  it "2022-07-09 00:22:47 -0400" do
    ast = parse("schema User = { id, user: :id }

user := { id: 10, user: 10 }

User(user) := user

console.log user")
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "User", "schema_expr" => [["id", { "klass" => "AST::SchemaCapture", "name" => "id", "start_pos" => 16, "end_pos" => 18 }], ["user", { "klass" => "AST::SchemaCapture", "name" => "id", "start_pos" => 26, "end_pos" => 29 }]], "start_pos" => 0, "end_pos" => 31 }, { "klass" => "AST::SimpleAssignment", "name" => "user", "expr" => { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "id", "value" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 47, "end_pos" => 49 }, "start_pos" => 43, "end_pos" => 49 }, { "klass" => "AST::SimpleObjectEntry", "key_name" => "user", "value" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 57, "end_pos" => 59 }, "start_pos" => 51, "end_pos" => 59 }], "start_pos" => 41, "end_pos" => 61 }, "start_pos" => 33, "end_pos" => 61 }, { "klass" => "AST::SimpleSchemaAssignment", "schema_name" => "User", "name" => "user", "expr" => { "klass" => "AST::IdLookup", "value" => "user", "start_pos" => 77, "end_pos" => 81 }, "start_pos" => 63, "end_pos" => 81 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "user", "start_pos" => 95, "end_pos" => 99 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 83, "end_pos" => 90 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 91, "end_pos" => 94 }, "start_pos" => 90, "end_pos" => 94 }, "start_pos" => 94, "end_pos" => 99 }])
  end
  it "2022-07-09 00:23:21 -0400" do
    ast = parse('schema Todo = { id, userId: :id }

request := await fetch("https://jsonplaceholder.typicode.com/todos/1")
Todo(todo) := await request.json()

console.log todo')
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "Todo", "schema_expr" => [["id", { "klass" => "AST::SchemaCapture", "name" => "id", "start_pos" => 16, "end_pos" => 18 }], ["userId", { "klass" => "AST::SchemaCapture", "name" => "id", "start_pos" => 28, "end_pos" => 31 }]], "start_pos" => 0, "end_pos" => 33 }, { "klass" => "AST::SimpleAssignment", "name" => "request", "expr" => { "klass" => "AST::Await", "value" => { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::SimpleString", "value" => "https://jsonplaceholder.typicode.com/todos/1", "start_pos" => 58, "end_pos" => 104 }], "expr" => { "klass" => "AST::IdLookup", "value" => "fetch", "start_pos" => 52, "end_pos" => 57 }, "start_pos" => 57, "end_pos" => 105 }, "start_pos" => 46, "end_pos" => 105 }, "start_pos" => 35, "end_pos" => 105 }, { "klass" => "AST::SimpleSchemaAssignment", "schema_name" => "Todo", "name" => "todo", "expr" => { "klass" => "AST::Await", "value" => { "klass" => "AST::FnCall", "args" => [], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "request", "start_pos" => 126, "end_pos" => 133 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "json", "start_pos" => 134, "end_pos" => 138 }, "start_pos" => 133, "end_pos" => 138 }, "start_pos" => 138, "end_pos" => 140 }, "start_pos" => 120, "end_pos" => 140 }, "start_pos" => 106, "end_pos" => 140 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "todo", "start_pos" => 154, "end_pos" => 158 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 142, "end_pos" => 149 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 150, "end_pos" => 153 }, "start_pos" => 149, "end_pos" => 153 }, "start_pos" => 153, "end_pos" => 158 }])
  end
  it "2022-07-09 00:23:48 -0400" do
    ast = parse("function add(a, b) = a + b

console.log add(10, 20)")
    expect(ast).to eq([{ "klass" => "AST::SingleLineDefWithArgs", "name" => "add", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "a", "start_pos" => 13, "end_pos" => 14 }, { "klass" => "AST::SimpleArg", "name" => "b", "start_pos" => 16, "end_pos" => 17 }], "start_pos" => 12, "end_pos" => 18 }, "return_value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "start_pos" => 21, "end_pos" => 22 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "start_pos" => 25, "end_pos" => 26 }, "start_pos" => 21, "end_pos" => 26 }, "start_pos" => 0, "end_pos" => 26 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Int", "value" => 10, "start_pos" => 44, "end_pos" => 46 }, { "klass" => "AST::Int", "value" => 20, "start_pos" => 48, "end_pos" => 50 }], "expr" => { "klass" => "AST::IdLookup", "value" => "add", "start_pos" => 40, "end_pos" => 43 }, "start_pos" => 43, "end_pos" => 51 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 28, "end_pos" => 35 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 36, "end_pos" => 39 }, "start_pos" => 35, "end_pos" => 39 }, "start_pos" => 39, "end_pos" => 51 }])
  end
  it "2022-07-09 00:24:40 -0400" do
    ast = parse("schema Ten = 10
schema Eleven = 11

function add(Ten(a), Eleven(b)) = a + b

console.log add(10, 11)")
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "Ten", "schema_expr" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 13, "end_pos" => 15 }, "start_pos" => 0, "end_pos" => 15 }, { "klass" => "AST::SchemaDefinition", "name" => "Eleven", "schema_expr" => { "klass" => "AST::Int", "value" => 11, "start_pos" => 32, "end_pos" => 34 }, "start_pos" => 16, "end_pos" => 34 }, { "klass" => "AST::SingleLineDefWithArgs", "name" => "add", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleSchemaArg", "schema_name" => "Ten", "name" => "a", "start_pos" => 49, "end_pos" => 55 }, { "klass" => "AST::SimpleSchemaArg", "schema_name" => "Eleven", "name" => "b", "start_pos" => 57, "end_pos" => 66 }], "start_pos" => 48, "end_pos" => 67 }, "return_value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "start_pos" => 70, "end_pos" => 71 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "start_pos" => 74, "end_pos" => 75 }, "start_pos" => 70, "end_pos" => 75 }, "start_pos" => 36, "end_pos" => 75 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Int", "value" => 10, "start_pos" => 93, "end_pos" => 95 }, { "klass" => "AST::Int", "value" => 11, "start_pos" => 97, "end_pos" => 99 }], "expr" => { "klass" => "AST::IdLookup", "value" => "add", "start_pos" => 89, "end_pos" => 92 }, "start_pos" => 92, "end_pos" => 100 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 77, "end_pos" => 84 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 85, "end_pos" => 88 }, "start_pos" => 84, "end_pos" => 88 }, "start_pos" => 88, "end_pos" => 100 }])
  end
  it "2022-07-09 00:25:42 -0400" do
    ast = parse("arr := [{ num: 10 }, { num: 11 }]

for { num } of arr
  console.log(num)
end")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "arr", "expr" => { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "num", "value" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 15, "end_pos" => 17 }, "start_pos" => 10, "end_pos" => 17 }], "start_pos" => 8, "end_pos" => 19 }, { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "num", "value" => { "klass" => "AST::Int", "value" => 11, "start_pos" => 28, "end_pos" => 30 }, "start_pos" => 23, "end_pos" => 30 }], "start_pos" => 21, "end_pos" => 32 }], "start_pos" => 7, "end_pos" => 33 }, "start_pos" => 0, "end_pos" => 33 }, { "klass" => "AST::ForOfObjDeconstructLoop", "iter_properties" => ["num"], "arr_expr" => { "klass" => "AST::IdLookup", "value" => "arr", "start_pos" => 50, "end_pos" => 53 }, "body" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "num", "start_pos" => 68, "end_pos" => 71 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 56, "end_pos" => 63 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 64, "end_pos" => 67 }, "start_pos" => 63, "end_pos" => 67 }, "start_pos" => 67, "end_pos" => 72 }], "start_pos" => 35, "end_pos" => 76 }])
  end
  it "2022-07-09 00:26:05 -0400" do
    ast = parse("PMath := {
  function add(a, b)
    a + b
  end
}")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "PMath", "expr" => { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::FunctionObjectEntry", "key_name" => "add", "value" => { "klass" => "AST::MultilineDefWithArgs", "name" => "add", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "a", "start_pos" => 26, "end_pos" => 27 }, { "klass" => "AST::SimpleArg", "name" => "b", "start_pos" => 29, "end_pos" => 30 }], "start_pos" => 25, "end_pos" => 31 }, "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "start_pos" => 36, "end_pos" => 37 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "start_pos" => 40, "end_pos" => 41 }, "start_pos" => 36, "end_pos" => 41 }, "start_pos" => 36, "end_pos" => 41 }], "start_pos" => 13, "end_pos" => 47 }, "start_pos" => 13, "end_pos" => 47 }], "start_pos" => 9, "end_pos" => 49 }, "start_pos" => 0, "end_pos" => 49 }])
  end
  it "2022-07-09 00:26:25 -0400" do
    ast = parse("o1 := { ...o }")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "o1", "expr" => { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SpreadObjectEntry", "value" => { "klass" => "AST::IdLookup", "value" => "o", "start_pos" => 11, "end_pos" => 12 }, "start_pos" => 8, "end_pos" => 11 }], "start_pos" => 6, "end_pos" => 14 }, "start_pos" => 0, "end_pos" => 14 }])
  end
  it "2022-07-09 00:26:39 -0400" do
    ast = parse("console.log false")
    expect(ast).to eq([{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Bool", "value" => false, "start_pos" => 12, "end_pos" => 17 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 0, "end_pos" => 7 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 8, "end_pos" => 11 }, "start_pos" => 7, "end_pos" => 11 }, "start_pos" => 11, "end_pos" => 17 }])
  end
  it "2022-07-09 00:26:49 -0400" do
    ast = parse("schema Nums = 1 | 2 | 3")
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "Nums", "schema_expr" => { "klass" => "AST::SchemaUnion", "schema_exprs" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 14, "end_pos" => 15 }, { "klass" => "AST::Int", "value" => 2, "start_pos" => 18, "end_pos" => 19 }, { "klass" => "AST::Int", "value" => 3, "start_pos" => 22, "end_pos" => 23 }], "start_pos" => 14, "end_pos" => 23 }, "start_pos" => 0, "end_pos" => 23 }])
  end
  it "2022-07-09 00:27:00 -0400" do
    ast = parse("schema User = { id, admin }

schema Admin = User & { admin: true }")
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "User", "schema_expr" => [["id", { "klass" => "AST::SchemaCapture", "name" => "id", "start_pos" => 16, "end_pos" => 18 }], ["admin", { "klass" => "AST::SchemaCapture", "name" => "admin", "start_pos" => 20, "end_pos" => 25 }]], "start_pos" => 0, "end_pos" => 27 }, { "klass" => "AST::SchemaDefinition", "name" => "Admin", "schema_expr" => { "klass" => "AST::SchemaIntersect", "schema_exprs" => [{ "klass" => "AST::IdLookup", "value" => "User", "start_pos" => 44, "end_pos" => 48 }, [["admin", { "klass" => "AST::Bool", "value" => true, "start_pos" => 60, "end_pos" => 64 }]]], "start_pos" => 44, "end_pos" => 66 }, "start_pos" => 29, "end_pos" => 66 }])
  end
  it "2022-07-13 20:47:08 -0400" do
    ast = parse('component WordCount in
  "
    <div>test</div>
  "
end
')
    expect(ast).to eq([{ "klass" => "AST::ExprComponent", "name" => "WordCount", "expr" => { "klass" => "AST::SimpleString", "value" => "\n    <div>test</div>\n  ", "start_pos" => 25, "end_pos" => 50 }, "start_pos" => 0, "end_pos" => 54 }])
  end
  it "2022-07-13 21:12:04 -0400" do
    ast = parse('component ProfileCard { name } in
  "
    <div>
      profile
      <div>${name}</div>
    </div>
  "
end
')
    expect(ast).to eq([{ "klass" => "AST::ExprComponentWithAttributes", "name" => "ProfileCard", "attributes" => [["name", { "klass" => "AST::SchemaCapture", "name" => "name", "start_pos" => 24, "end_pos" => 28 }]], "expr" => { "klass" => "AST::SimpleString", "value" => "\n    <div>\n      profile\n      <div>${name}</div>\n    </div>\n  ", "start_pos" => 36, "end_pos" => 101 }, "start_pos" => 0, "end_pos" => 105 }])
  end
  it "2022-07-13 22:55:36 -0400" do
    ast = parse('component CardEntry 
  name := "string"
in
"
  <div>${this.name}</div>
"
end

')
    expect(ast).to eq([{ "klass" => "AST::BodyComponentWithoutAttrs", "name" => "CardEntry", "constructor_body" => [{ "klass" => "AST::SimpleAssignment", "name" => "name", "expr" => { "klass" => "AST::SimpleString", "value" => "string", "start_pos" => 31, "end_pos" => 39 }, "start_pos" => 23, "end_pos" => 39 }], "expr" => { "klass" => "AST::SimpleString", "value" => "\n  <div>${this.name}</div>\n", "start_pos" => 43, "end_pos" => 72 }, "start_pos" => 0, "end_pos" => 76 }])
  end
  it "2022-07-13 23:53:09 -0400" do
    ast = parse("component CardEntry { name } in
  <div></div>
end

")
    expect(ast).to eq([{ "klass" => "AST::ExprComponentWithAttributes", "name" => "CardEntry", "attributes" => [["name", { "klass" => "AST::SchemaCapture", "name" => "name", "start_pos" => 22, "end_pos" => 26 }]], "expr" => { "klass" => "AST::SimpleElement", "name" => "div", "children" => [], "start_pos" => 34, "end_pos" => 45 }, "start_pos" => 0, "end_pos" => 49 }])
  end
  it "2022-07-14 01:24:13 -0400" do
    ast = parse("component CardEntry { name } in
  <div>{name}</div>
end
")
    expect(ast).to eq([{ "klass" => "AST::ExprComponentWithAttributes", "name" => "CardEntry", "attributes" => [["name", { "klass" => "AST::SchemaCapture", "name" => "name", "start_pos" => 22, "end_pos" => 26 }]], "expr" => { "klass" => "AST::SimpleElement", "name" => "div", "children" => [{ "klass" => "AST::EscapedElementExpr", "value" => { "klass" => "AST::IdLookup", "value" => "name", "start_pos" => 40, "end_pos" => 44 }, "start_pos" => 39, "end_pos" => 45 }], "start_pos" => 34, "end_pos" => 51 }, "start_pos" => 0, "end_pos" => 55 }])
  end
  it "2022-07-16 13:52:01 -0400" do
    ast = parse("class Parser
  function constructor(name)
    this.name := name
  end
end")
    expect(ast).to eq([{ "klass" => "AST::Class", "name" => "Parser", "parent_class" => nil, "entries" => [{ "klass" => "AST::ConstructorWithArgs", "name" => "constructor", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "name", "start_pos" => 36, "end_pos" => 40 }], "start_pos" => 35, "end_pos" => 41 }, "body" => [{ "klass" => "AST::DotAssignment", "lhs" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::This", "value" => nil, "start_pos" => 46, "end_pos" => 50 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "name", "start_pos" => 51, "end_pos" => 55 }, "start_pos" => 50, "end_pos" => 55 }, "expr" => { "klass" => "AST::IdLookup", "value" => "name", "start_pos" => 59, "end_pos" => 63 }, "start_pos" => 56, "end_pos" => 63 }], "start_pos" => 15, "end_pos" => 69 }], "start_pos" => 0, "end_pos" => 73 }])
  end
  it "2022-07-16 16:38:25 -0400" do
    ast = parse("class Parser
  static function from(that)
    new this(that.tokens, that.program_string, that.pos)
  end

  function constructor(tokens, program_string, pos)
    this.tokens := tokens
    this.program_string := program_string
    this.pos := pos
  end
end
")
    expect(ast).to eq([{ "klass" => "AST::Class", "name" => "Parser", "parent_class" => nil, "entries" => [{ "klass" => "AST::StaticMethod", "name" => "from", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "that", "start_pos" => 36, "end_pos" => 40 }], "start_pos" => 35, "end_pos" => 41 }, "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::New", "class_expr" => { "klass" => "AST::This", "value" => nil, "start_pos" => 50, "end_pos" => 54 }, "args" => [{ "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "that", "start_pos" => 55, "end_pos" => 59 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "tokens", "start_pos" => 60, "end_pos" => 66 }, "start_pos" => 59, "end_pos" => 66 }, { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "that", "start_pos" => 68, "end_pos" => 72 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "program_string", "start_pos" => 73, "end_pos" => 87 }, "start_pos" => 72, "end_pos" => 87 }, { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "that", "start_pos" => 89, "end_pos" => 93 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "pos", "start_pos" => 94, "end_pos" => 97 }, "start_pos" => 93, "end_pos" => 97 }], "start_pos" => 46, "end_pos" => 98 }, "start_pos" => 46, "end_pos" => 98 }], "start_pos" => 15, "end_pos" => 104 }, { "klass" => "AST::ConstructorWithArgs", "name" => "constructor", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "tokens", "start_pos" => 129, "end_pos" => 135 }, { "klass" => "AST::SimpleArg", "name" => "program_string", "start_pos" => 137, "end_pos" => 151 }, { "klass" => "AST::SimpleArg", "name" => "pos", "start_pos" => 153, "end_pos" => 156 }], "start_pos" => 128, "end_pos" => 157 }, "body" => [{ "klass" => "AST::DotAssignment", "lhs" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::This", "value" => nil, "start_pos" => 162, "end_pos" => 166 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "tokens", "start_pos" => 167, "end_pos" => 173 }, "start_pos" => 166, "end_pos" => 173 }, "expr" => { "klass" => "AST::IdLookup", "value" => "tokens", "start_pos" => 177, "end_pos" => 183 }, "start_pos" => 174, "end_pos" => 183 }, { "klass" => "AST::DotAssignment", "lhs" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::This", "value" => nil, "start_pos" => 188, "end_pos" => 192 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "program_string", "start_pos" => 193, "end_pos" => 207 }, "start_pos" => 192, "end_pos" => 207 }, "expr" => { "klass" => "AST::IdLookup", "value" => "program_string", "start_pos" => 211, "end_pos" => 225 }, "start_pos" => 208, "end_pos" => 225 }, { "klass" => "AST::DotAssignment", "lhs" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::This", "value" => nil, "start_pos" => 230, "end_pos" => 234 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "pos", "start_pos" => 235, "end_pos" => 238 }, "start_pos" => 234, "end_pos" => 238 }, "expr" => { "klass" => "AST::IdLookup", "value" => "pos", "start_pos" => 242, "end_pos" => 245 }, "start_pos" => 239, "end_pos" => 245 }], "start_pos" => 108, "end_pos" => 251 }], "start_pos" => 0, "end_pos" => 255 }])
  end
  it "2022-07-16 16:58:26 -0400" do
    ast = parse("class Parser
  function constructor(@tokens, @program_string, @pos)

  static function from(that)
    new this(that.tokens, that.program_string, that.pos)
  end
end
")
    expect(ast).to eq([{ "klass" => "AST::Class", "name" => "Parser", "parent_class" => nil, "entries" => [{ "klass" => "AST::ShortHandConstructor", "instance_vars" => ["tokens", "program_string", "pos"], "start_pos" => 15, "end_pos" => 67 }, { "klass" => "AST::StaticMethod", "name" => "from", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "that", "start_pos" => 92, "end_pos" => 96 }], "start_pos" => 91, "end_pos" => 97 }, "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::New", "class_expr" => { "klass" => "AST::This", "value" => nil, "start_pos" => 106, "end_pos" => 110 }, "args" => [{ "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "that", "start_pos" => 111, "end_pos" => 115 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "tokens", "start_pos" => 116, "end_pos" => 122 }, "start_pos" => 115, "end_pos" => 122 }, { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "that", "start_pos" => 124, "end_pos" => 128 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "program_string", "start_pos" => 129, "end_pos" => 143 }, "start_pos" => 128, "end_pos" => 143 }, { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "that", "start_pos" => 145, "end_pos" => 149 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "pos", "start_pos" => 150, "end_pos" => 153 }, "start_pos" => 149, "end_pos" => 153 }], "start_pos" => 102, "end_pos" => 154 }, "start_pos" => 102, "end_pos" => 154 }], "start_pos" => 71, "end_pos" => 160 }], "start_pos" => 0, "end_pos" => 164 }])
  end
  it "2022-07-16 18:02:41 -0400" do
    ast = parse("class Parser
  get current_token = this.tokens[this.pos]  
end
")
    expect(ast).to eq([{ "klass" => "AST::Class", "name" => "Parser", "parent_class" => nil, "entries" => [{ "klass" => "AST::OneLineGetter", "name" => "current_token", "expr" => { "klass" => "AST::DynamicLookup", "lhs" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::This", "value" => nil, "start_pos" => 35, "end_pos" => 39 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "tokens", "start_pos" => 40, "end_pos" => 46 }, "start_pos" => 39, "end_pos" => 46 }, "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::This", "value" => nil, "start_pos" => 47, "end_pos" => 51 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "pos", "start_pos" => 52, "end_pos" => 55 }, "start_pos" => 51, "end_pos" => 55 }, "start_pos" => 46, "end_pos" => 56 }, "start_pos" => 15, "end_pos" => 56 }], "start_pos" => 0, "end_pos" => 62 }])
  end
  it "2022-07-18 18:46:38 -0400" do
    ast = parse("class Parser
  body := []
end
")
    expect(ast).to eq([{ "klass" => "AST::Class", "name" => "Parser", "parent_class" => nil, "entries" => [{ "klass" => "AST::InstanceProperty", "name" => "body", "expr" => { "klass" => "AST::ArrayLiteral", "value" => [], "start_pos" => 23, "end_pos" => 25 }, "start_pos" => 15, "end_pos" => 25 }], "start_pos" => 0, "end_pos" => 29 }])
  end
  it "2022-07-18 20:58:43 -0400" do
    ast = parse('schema Gt1 = #{ it > 1 }

case function factorial
when (Gt1(n))
  factorial(n - 1) + factorial(n - 2)
when (1)
  1
when (0)
  0
end

console.log factorial(20)')
    expect(ast).to eq([{"klass"=>"AST::SchemaDefinition", "name"=>"Gt1", "schema_expr"=>{"klass"=>"AST::ShortFn", "return_expr"=>{"klass"=>"AST::Op", "lhs"=>{"klass"=>"AST::AnonIdLookup", "start_pos"=>16, "end_pos"=>18}, "type"=>:>, "rhs"=>{"klass"=>"AST::Int", "value"=>1, "start_pos"=>21, "end_pos"=>22}, "start_pos"=>16, "end_pos"=>22}, "start_pos"=>13, "end_pos"=>24}, "start_pos"=>0, "end_pos"=>24}, {"klass"=>"AST::CaseFunctionDefinition", "name"=>"factorial", "patterns"=>[{"klass"=>"AST::CaseFnPattern", "patterns"=>[{"klass"=>"AST::SimpleSchemaArg", "schema_name"=>"Gt1", "name"=>"n", "start_pos"=>56, "end_pos"=>62}], "body"=>[{"klass"=>"AST::Return", "value"=>{"klass"=>"AST::Op", "lhs"=>{"klass"=>"AST::FnCall", "args"=>[{"klass"=>"AST::Op", "lhs"=>{"klass"=>"AST::IdLookup", "value"=>"n", "start_pos"=>76, "end_pos"=>77}, "type"=>:-, "rhs"=>{"klass"=>"AST::Int", "value"=>1, "start_pos"=>80, "end_pos"=>81}, "start_pos"=>76, "end_pos"=>81}], "expr"=>{"klass"=>"AST::IdLookup", "value"=>"factorial", "start_pos"=>66, "end_pos"=>75}, "start_pos"=>75, "end_pos"=>82}, "type"=>:+, "rhs"=>{"klass"=>"AST::FnCall", "args"=>[{"klass"=>"AST::Op", "lhs"=>{"klass"=>"AST::IdLookup", "value"=>"n", "start_pos"=>95, "end_pos"=>96}, "type"=>:-, "rhs"=>{"klass"=>"AST::Int", "value"=>2, "start_pos"=>99, "end_pos"=>100}, "start_pos"=>95, "end_pos"=>100}], "expr"=>{"klass"=>"AST::IdLookup", "value"=>"factorial", "start_pos"=>85, "end_pos"=>94}, "start_pos"=>94, "end_pos"=>101}, "start_pos"=>75, "end_pos"=>101}, "start_pos"=>75, "end_pos"=>101}], "start_pos"=>50, "end_pos"=>101}, {"klass"=>"AST::CaseFnPattern", "patterns"=>[{"klass"=>"AST::Int", "value"=>1, "start_pos"=>108, "end_pos"=>109}], "body"=>[{"klass"=>"AST::Return", "value"=>{"klass"=>"AST::Int", "value"=>1, "start_pos"=>113, "end_pos"=>114}, "start_pos"=>113, "end_pos"=>114}], "start_pos"=>102, "end_pos"=>114}, {"klass"=>"AST::CaseFnPattern", "patterns"=>[{"klass"=>"AST::Int", "value"=>0, "start_pos"=>121, "end_pos"=>122}], "body"=>[{"klass"=>"AST::Return", "value"=>{"klass"=>"AST::Int", "value"=>0, "start_pos"=>126, "end_pos"=>127}, "start_pos"=>126, "end_pos"=>127}], "start_pos"=>115, "end_pos"=>127}], "start_pos"=>26, "end_pos"=>131}, {"klass"=>"AST::FnCall", "args"=>[{"klass"=>"AST::FnCall", "args"=>[{"klass"=>"AST::Int", "value"=>20, "start_pos"=>155, "end_pos"=>157}], "expr"=>{"klass"=>"AST::IdLookup", "value"=>"factorial", "start_pos"=>145, "end_pos"=>154}, "start_pos"=>154, "end_pos"=>158}], "expr"=>{"klass"=>"AST::Dot", "lhs"=>{"klass"=>"AST::IdLookup", "value"=>"console", "start_pos"=>133, "end_pos"=>140}, "type"=>".", "rhs"=>{"klass"=>"AST::IdLookup", "value"=>"log", "start_pos"=>141, "end_pos"=>144}, "start_pos"=>140, "end_pos"=>144}, "start_pos"=>144, "end_pos"=>158}])
  end
  it "2022-07-18 21:30:28 -0400" do
    ast = parse('function length
  this.length
end

console.log "abc"::length')
    expect(ast).to eq([{"klass"=>"AST::MultilineDefWithoutArgs", "name"=>"length", "body"=>[{"klass"=>"AST::Return", "value"=>{"klass"=>"AST::Dot", "lhs"=>{"klass"=>"AST::This", "value"=>nil, "start_pos"=>18, "end_pos"=>22}, "type"=>".", "rhs"=>{"klass"=>"AST::IdLookup", "value"=>"length", "start_pos"=>23, "end_pos"=>29}, "start_pos"=>22, "end_pos"=>29}, "start_pos"=>22, "end_pos"=>29}], "start_pos"=>0, "end_pos"=>33}, {"klass"=>"AST::FnCall", "args"=>[{"klass"=>"AST::Bind", "lhs"=>{"klass"=>"AST::SimpleString", "value"=>"abc", "start_pos"=>47, "end_pos"=>52}, "function"=>{"klass"=>"AST::IdLookup", "value"=>"length", "start_pos"=>54, "end_pos"=>60}, "args"=>[]}], "expr"=>{"klass"=>"AST::Dot", "lhs"=>{"klass"=>"AST::IdLookup", "value"=>"console", "start_pos"=>35, "end_pos"=>42}, "type"=>".", "rhs"=>{"klass"=>"AST::IdLookup", "value"=>"log", "start_pos"=>43, "end_pos"=>46}, "start_pos"=>42, "end_pos"=>46}, "start_pos"=>46, "end_pos"=>nil}])
  end
  it "2022-07-18 21:30:42 -0400" do
    ast = parse('function length
  this.length
end

console.log "abc"::length(10, 20)')
    expect(ast).to eq([{"klass"=>"AST::MultilineDefWithoutArgs", "name"=>"length", "body"=>[{"klass"=>"AST::Return", "value"=>{"klass"=>"AST::Dot", "lhs"=>{"klass"=>"AST::This", "value"=>nil, "start_pos"=>18, "end_pos"=>22}, "type"=>".", "rhs"=>{"klass"=>"AST::IdLookup", "value"=>"length", "start_pos"=>23, "end_pos"=>29}, "start_pos"=>22, "end_pos"=>29}, "start_pos"=>22, "end_pos"=>29}], "start_pos"=>0, "end_pos"=>33}, {"klass"=>"AST::FnCall", "args"=>[{"klass"=>"AST::Bind", "lhs"=>{"klass"=>"AST::SimpleString", "value"=>"abc", "start_pos"=>47, "end_pos"=>52}, "function"=>{"klass"=>"AST::IdLookup", "value"=>"length", "start_pos"=>54, "end_pos"=>60}, "args"=>[{"klass"=>"AST::Int", "value"=>10, "start_pos"=>61, "end_pos"=>63}, {"klass"=>"AST::Int", "value"=>20, "start_pos"=>65, "end_pos"=>67}]}], "expr"=>{"klass"=>"AST::Dot", "lhs"=>{"klass"=>"AST::IdLookup", "value"=>"console", "start_pos"=>35, "end_pos"=>42}, "type"=>".", "rhs"=>{"klass"=>"AST::IdLookup", "value"=>"log", "start_pos"=>43, "end_pos"=>46}, "start_pos"=>42, "end_pos"=>46}, "start_pos"=>46, "end_pos"=>nil}])
  end
  it "2022-07-18 21:50:01 -0400" do
    ast = parse('a := {}

console.log a?.b')
    expect(ast).to eq([{"klass"=>"AST::SimpleAssignment", "name"=>"a", "expr"=>{"klass"=>"AST::ObjectLiteral", "value"=>[], "start_pos"=>5, "end_pos"=>7}, "start_pos"=>0, "end_pos"=>7}, {"klass"=>"AST::FnCall", "args"=>[{"klass"=>"AST::OptionalChain", "lhs"=>{"klass"=>"AST::IdLookup", "value"=>"a", "start_pos"=>21, "end_pos"=>22}, "property"=>"b", "start_pos"=>22, "end_pos"=>25}], "expr"=>{"klass"=>"AST::Dot", "lhs"=>{"klass"=>"AST::IdLookup", "value"=>"console", "start_pos"=>9, "end_pos"=>16}, "type"=>".", "rhs"=>{"klass"=>"AST::IdLookup", "value"=>"log", "start_pos"=>17, "end_pos"=>20}, "start_pos"=>16, "end_pos"=>20}, "start_pos"=>20, "end_pos"=>25}])
  end
  it "2022-07-18 23:55:11 -0400" do
    ast = parse('function ten = 10')
    expect(ast).to eq([{"klass"=>"AST::SingleLineDefWithoutArgs", "name"=>"ten", "return_value"=>{"klass"=>"AST::Int", "value"=>10, "start_pos"=>15, "end_pos"=>17}, "start_pos"=>0, "end_pos"=>17}])
  end
  it "2022-07-21 20:26:07 -0400" do
    ast = parse('[a] := [1]')
    expect(ast).to eq([{"klass"=>"AST::ArrayAssignment", "variables"=>["a"], "expr"=>{"klass"=>"AST::ArrayLiteral", "value"=>[{"klass"=>"AST::Int", "value"=>1, "start_pos"=>8, "end_pos"=>9}], "start_pos"=>7, "end_pos"=>10}, "start_pos"=>0, "end_pos"=>10}])
  end
  it "2022-07-21 21:55:29 -0400" do
    ast = parse('obj := {
  a: 10,
  b: "str"
}

for key in obj
  console.log key
end')
    expect(ast).to eq([{"klass"=>"AST::SimpleAssignment", "name"=>"obj", "expr"=>{"klass"=>"AST::ObjectLiteral", "value"=>[{"klass"=>"AST::SimpleObjectEntry", "key_name"=>"a", "value"=>{"klass"=>"AST::Int", "value"=>10, "start_pos"=>14, "end_pos"=>16}, "start_pos"=>11, "end_pos"=>16}, {"klass"=>"AST::SimpleObjectEntry", "key_name"=>"b", "value"=>{"klass"=>"AST::SimpleString", "value"=>"str", "start_pos"=>23, "end_pos"=>28}, "start_pos"=>20, "end_pos"=>28}], "start_pos"=>7, "end_pos"=>30}, "start_pos"=>0, "end_pos"=>30}, {"klass"=>"AST::SimpleForInLoop", "variable"=>"key", "object_expr"=>{"klass"=>"AST::IdLookup", "value"=>"obj", "start_pos"=>43, "end_pos"=>46}, "body"=>[{"klass"=>"AST::FnCall", "args"=>[{"klass"=>"AST::IdLookup", "value"=>"key", "start_pos"=>61, "end_pos"=>64}], "expr"=>{"klass"=>"AST::Dot", "lhs"=>{"klass"=>"AST::IdLookup", "value"=>"console", "start_pos"=>49, "end_pos"=>56}, "type"=>".", "rhs"=>{"klass"=>"AST::IdLookup", "value"=>"log", "start_pos"=>57, "end_pos"=>60}, "start_pos"=>56, "end_pos"=>60}, "start_pos"=>60, "end_pos"=>64}], "start_pos"=>32, "end_pos"=>68}])
  end
  it "2022-07-21 23:04:33 -0400" do
    ast = parse('assert 1 + 1 === 3
')
    expect(ast).to eq([{"klass"=>"AST::Assert", "expr"=>{"klass"=>"AST::Op", "lhs"=>{"klass"=>"AST::Int", "value"=>1, "start_pos"=>7, "end_pos"=>8}, "type"=>:+, "rhs"=>{"klass"=>"AST::Op", "lhs"=>{"klass"=>"AST::Int", "value"=>1, "start_pos"=>11, "end_pos"=>12}, "type"=>:===, "rhs"=>{"klass"=>"AST::Int", "value"=>3, "start_pos"=>17, "end_pos"=>18}, "start_pos"=>11, "end_pos"=>18}, "start_pos"=>7, "end_pos"=>18}, "string"=>"1 + 1 === 3", "start_pos"=>0, "end_pos"=>18}])
  end
end