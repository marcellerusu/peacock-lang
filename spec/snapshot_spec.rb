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
  it "2022-06-20 20:06:22 -0400" do
    ast = parse("a := a + 10")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "a", "expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "pos" => 5 }, "type" => :+, "rhs" => { "klass" => "AST::Int", "value" => 10, "pos" => 9 }, "pos" => 5 }, "pos" => 0 }])
  end
  it "2022-06-21 09:48:20 -0400" do
    ast = parse('add(1, "10", [1, 2])')
    expect(ast).to eq([{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Int", "value" => 1, "pos" => 4 }, { "klass" => "AST::SimpleString", "value" => "10", "pos" => 7 }, { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "pos" => 14 }, { "klass" => "AST::Int", "value" => 2, "pos" => 17 }], "pos" => 13 }], "expr" => { "klass" => "AST::IdLookup", "value" => "add", "pos" => 0 }, "pos" => 3 }])
  end
  it "2022-06-21 15:21:51 -0400" do
    ast = parse("double := () => 10 * 2

console.log double()")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "double", "expr" => { "klass" => "AST::SingleLineArrowFnWithoutArgs", "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::Int", "value" => 10, "pos" => 16 }, "type" => :*, "rhs" => { "klass" => "AST::Int", "value" => 2, "pos" => 21 }, "pos" => 16 }, "pos" => 10 }, "pos" => 0 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::FnCall", "args" => [], "expr" => { "klass" => "AST::IdLookup", "value" => "double", "pos" => 36 }, "pos" => 42 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "pos" => 24 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "pos" => 32 }, "pos" => 31 }, "pos" => 42 }])
  end
  it "2022-06-21 15:37:31 -0400" do
    ast = parse("double := x => x * 2
")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "double", "expr" => { "klass" => "AST::SingleLineArrowFnWithOneArg", "arg" => "x", "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "x", "pos" => 15 }, "type" => :*, "rhs" => { "klass" => "AST::Int", "value" => 2, "pos" => 19 }, "pos" => 15 }, "pos" => 10 }, "pos" => 0 }])
  end
  it "2022-06-21 16:25:07 -0400" do
    ast = parse("arr := [1, 2, 3]

for elem of arr
  console.log elem
end
")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "arr", "expr" => { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "pos" => 8 }, { "klass" => "AST::Int", "value" => 2, "pos" => 11 }, { "klass" => "AST::Int", "value" => 3, "pos" => 14 }], "pos" => 7 }, "pos" => 0 }, { "klass" => "AST::SimpleForOfLoop", "iter_name" => "elem", "arr_expr" => { "klass" => "AST::IdLookup", "value" => "arr", "pos" => 30 }, "body" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "elem", "pos" => 48 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "pos" => 36 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "pos" => 44 }, "pos" => 43 }, "pos" => 48 }], "pos" => 18 }])
  end
  it "2022-06-21 23:19:22 -0400" do
    ast = parse("schema User = { id }")
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "User", "schema_expr" => [["id", { "klass" => "AST::SchemaCapture", "name" => "id", "pos" => 16 }]], "pos" => 0 }])
  end
  it "2022-06-21 23:20:25 -0400" do
    ast = parse("schema User = { id: 10 }")
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "User", "schema_expr" => [["id", { "klass" => "AST::Int", "value" => 10, "pos" => 20 }]], "pos" => 0 }])
  end
  it "2022-06-22 23:38:51 -0400" do
    ast = parse("function add(a, b) = a + b")
    expect(ast).to eq([{ "klass" => "AST::SingleLineDefWithArgs", "name" => "add", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "a", "pos" => 13 }, { "klass" => "AST::SimpleArg", "name" => "b", "pos" => 16 }], "pos" => 12 }, "return_value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "pos" => 21 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "pos" => 25 }, "pos" => 21 }, "pos" => 0 }])
  end
  it "2022-06-22 23:40:50 -0400" do
    ast = parse("function add(a, b)
  a + b
end
")
    expect(ast).to eq([{ "klass" => "AST::MultilineDefWithArgs", "name" => "add", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "a", "pos" => 13 }, { "klass" => "AST::SimpleArg", "name" => "b", "pos" => 16 }], "pos" => 12 }, "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "pos" => 21 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "pos" => 25 }, "pos" => 21 }, "pos" => 21 }], "pos" => 0 }])
  end
  it "2022-06-22 23:41:28 -0400" do
    ast = parse("function add(a, b) = a + b

console.log(add(10, 20))")
    expect(ast).to eq([{ "klass" => "AST::SingleLineDefWithArgs", "name" => "add", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "a", "pos" => 13 }, { "klass" => "AST::SimpleArg", "name" => "b", "pos" => 16 }], "pos" => 12 }, "return_value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "pos" => 21 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "pos" => 25 }, "pos" => 21 }, "pos" => 0 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Int", "value" => 10, "pos" => 44 }, { "klass" => "AST::Int", "value" => 20, "pos" => 48 }], "expr" => { "klass" => "AST::IdLookup", "value" => "add", "pos" => 40 }, "pos" => 43 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "pos" => 28 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "pos" => 36 }, "pos" => 35 }, "pos" => 39 }])
  end
  it "2022-06-22 23:46:22 -0400" do
    ast = parse('double := #{ it * 2 }')
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "double", "expr" => { "klass" => "AST::ShortFn", "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::AnonIdLookup", "pos" => 13 }, "type" => :*, "rhs" => { "klass" => "AST::Int", "value" => 2, "pos" => 18 }, "pos" => 13 }, "pos" => 10 }, "pos" => 0 }])
  end
  it "2022-06-22 23:46:42 -0400" do
    ast = parse("double := (x) => x * 2")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "double", "expr" => { "klass" => "AST::SingleLineArrowFnWithArgs", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "x", "pos" => 11 }], "pos" => 10 }, "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "x", "pos" => 17 }, "type" => :*, "rhs" => { "klass" => "AST::Int", "value" => 2, "pos" => 21 }, "pos" => 17 }, "pos" => 10 }, "pos" => 0 }])
  end
  it "2022-06-22 23:47:04 -0400" do
    ast = parse('schema User = { id: #{ it > 10 } }')
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "User", "schema_expr" => [["id", { "klass" => "AST::ShortFn", "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::AnonIdLookup", "pos" => 23 }, "type" => :>, "rhs" => { "klass" => "AST::Int", "value" => 10, "pos" => 28 }, "pos" => 23 }, "pos" => 20 }]], "pos" => 0 }])
  end
  it "2022-06-22 23:47:52 -0400" do
    ast = parse("function a() = 10")
    expect(ast).to eq([{ "klass" => "AST::SingleLineDefWithArgs", "name" => "a", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [], "pos" => 10 }, "return_value" => { "klass" => "AST::Int", "value" => 10, "pos" => 15 }, "pos" => 0 }])
  end
  it "2022-07-04 21:39:27 -0400" do
    ast = parse("PMath := {
  add(a, b) => a + b,
}
")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "PMath", "expr" => { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::ArrowMethodObjectEntry", "key_name" => "add", "value" => { "klass" => "AST::SingleLineArrowFnWithArgs", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "a", "pos" => 17 }, { "klass" => "AST::SimpleArg", "name" => "b", "pos" => 20 }], "pos" => 16 }, "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "pos" => 26 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "pos" => 30 }, "pos" => 26 }, "pos" => 13 }, "pos" => 13 }], "pos" => 9 }, "pos" => 0 }])
  end
  it "2022-07-04 21:39:55 -0400" do
    ast = parse("a := {
  b: 10
}")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "a", "expr" => { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "b", "value" => { "klass" => "AST::Int", "value" => 10, "pos" => 12 }, "pos" => 9 }], "pos" => 5 }, "pos" => 0 }])
  end
  it "2022-07-04 21:43:06 -0400" do
    ast = parse("console.log a.b")
    expect(ast).to eq([{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "pos" => 12 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "pos" => 14 }, "pos" => 13 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "pos" => 0 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "pos" => 8 }, "pos" => 7 }, "pos" => 13 }])
  end
  it "2022-07-04 21:44:06 -0400" do
    ast = parse("schema User = { id }

user := { id: 10 }

User(user) := user

console.log user")
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "User", "schema_expr" => [["id", { "klass" => "AST::SchemaCapture", "name" => "id", "pos" => 16 }]], "pos" => 0 }, { "klass" => "AST::SimpleAssignment", "name" => "user", "expr" => { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "id", "value" => { "klass" => "AST::Int", "value" => 10, "pos" => 36 }, "pos" => 32 }], "pos" => 30 }, "pos" => 22 }, { "klass" => "AST::SimpleSchemaAssignment", "schema_name" => "User", "name" => "user", "expr" => { "klass" => "AST::IdLookup", "value" => "user", "pos" => 56 }, "pos" => 42 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "user", "pos" => 74 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "pos" => 62 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "pos" => 70 }, "pos" => 69 }, "pos" => 74 }])
  end
  it "2022-07-04 21:44:52 -0400" do
    ast = parse("schema User = { id, user: :id }

user := { id: 10, user: 10 }

User(user) := user

console.log user")
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "User", "schema_expr" => [["id", { "klass" => "AST::SchemaCapture", "name" => "id", "pos" => 16 }], ["user", { "klass" => "AST::SchemaCapture", "name" => "id", "pos" => 26 }]], "pos" => 0 }, { "klass" => "AST::SimpleAssignment", "name" => "user", "expr" => { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "id", "value" => { "klass" => "AST::Int", "value" => 10, "pos" => 47 }, "pos" => 43 }, { "klass" => "AST::SimpleObjectEntry", "key_name" => "user", "value" => { "klass" => "AST::Int", "value" => 10, "pos" => 57 }, "pos" => 51 }], "pos" => 41 }, "pos" => 33 }, { "klass" => "AST::SimpleSchemaAssignment", "schema_name" => "User", "name" => "user", "expr" => { "klass" => "AST::IdLookup", "value" => "user", "pos" => 77 }, "pos" => 63 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "user", "pos" => 95 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "pos" => 83 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "pos" => 91 }, "pos" => 90 }, "pos" => 95 }])
  end
  it "2022-07-04 21:45:30 -0400" do
    ast = parse('schema Todo = { id, userId: :id }

request := await fetch("https://jsonplaceholder.typicode.com/todos/1")
Todo(todo) := await request.json()

console.log todo')
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "Todo", "schema_expr" => [["id", { "klass" => "AST::SchemaCapture", "name" => "id", "pos" => 16 }], ["userId", { "klass" => "AST::SchemaCapture", "name" => "id", "pos" => 28 }]], "pos" => 0 }, { "klass" => "AST::SimpleAssignment", "name" => "request", "expr" => { "klass" => "AST::Await", "value" => { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::SimpleString", "value" => "https://jsonplaceholder.typicode.com/todos/1", "pos" => 58 }], "expr" => { "klass" => "AST::IdLookup", "value" => "fetch", "pos" => 52 }, "pos" => 57 }, "pos" => 46 }, "pos" => 35 }, { "klass" => "AST::SimpleSchemaAssignment", "schema_name" => "Todo", "name" => "todo", "expr" => { "klass" => "AST::Await", "value" => { "klass" => "AST::FnCall", "args" => [], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "request", "pos" => 126 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "json", "pos" => 134 }, "pos" => 133 }, "pos" => 138 }, "pos" => 120 }, "pos" => 106 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "todo", "pos" => 154 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "pos" => 142 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "pos" => 150 }, "pos" => 149 }, "pos" => 154 }])
  end
  it "2022-07-04 21:45:46 -0400" do
    ast = parse("function add(a, b) = a + b

console.log add(10, 20)")
    expect(ast).to eq([{ "klass" => "AST::SingleLineDefWithArgs", "name" => "add", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "a", "pos" => 13 }, { "klass" => "AST::SimpleArg", "name" => "b", "pos" => 16 }], "pos" => 12 }, "return_value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "pos" => 21 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "pos" => 25 }, "pos" => 21 }, "pos" => 0 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Int", "value" => 10, "pos" => 44 }, { "klass" => "AST::Int", "value" => 20, "pos" => 48 }], "expr" => { "klass" => "AST::IdLookup", "value" => "add", "pos" => 40 }, "pos" => 43 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "pos" => 28 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "pos" => 36 }, "pos" => 35 }, "pos" => 43 }])
  end
  it "2022-07-04 21:46:03 -0400" do
    ast = parse("schema Ten = 10
schema Eleven = 11

function add(Ten(a), Eleven(b)) = a + b

console.log add(10, 11)")
    expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "Ten", "schema_expr" => { "klass" => "AST::Int", "value" => 10, "pos" => 13 }, "pos" => 0 }, { "klass" => "AST::SchemaDefinition", "name" => "Eleven", "schema_expr" => { "klass" => "AST::Int", "value" => 11, "pos" => 32 }, "pos" => 16 }, { "klass" => "AST::SingleLineDefWithArgs", "name" => "add", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleSchemaArg", "schema_name" => "Ten", "name" => "a", "pos" => 49 }, { "klass" => "AST::SimpleSchemaArg", "schema_name" => "Eleven", "name" => "b", "pos" => 57 }], "pos" => 48 }, "return_value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "pos" => 70 }, "type" => :+, "rhs" => { "klass" => "AST::IdLookup", "value" => "b", "pos" => 74 }, "pos" => 70 }, "pos" => 36 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Int", "value" => 10, "pos" => 93 }, { "klass" => "AST::Int", "value" => 11, "pos" => 97 }], "expr" => { "klass" => "AST::IdLookup", "value" => "add", "pos" => 89 }, "pos" => 92 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "pos" => 77 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "pos" => 85 }, "pos" => 84 }, "pos" => 92 }])
  end
  it "2022-07-04 21:49:17 -0400" do
    ast = parse("arr := [{ num: 10 }, { num: 11 }]

for { num } of arr
  console.log(num)
end")
    expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "arr", "expr" => { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "num", "value" => { "klass" => "AST::Int", "value" => 10, "pos" => 15 }, "pos" => 10 }], "pos" => 8 }, { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "num", "value" => { "klass" => "AST::Int", "value" => 11, "pos" => 28 }, "pos" => 23 }], "pos" => 21 }], "pos" => 7 }, "pos" => 0 }, { "klass" => "AST::ForOfObjDeconstructLoop", "iter_properties" => ["num"], "arr_expr" => { "klass" => "AST::IdLookup", "value" => "arr", "pos" => 50 }, "body" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "num", "pos" => 68 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "pos" => 56 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "pos" => 64 }, "pos" => 63 }, "pos" => 67 }], "pos" => 35 }])
  end
end
