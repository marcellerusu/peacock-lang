require "ast"
require "parser"
require "compiler"

def compile(str)
  tokens = Lexer::tokenize(str.strip)
  ast = Parser.new(tokens, str).parse!
  Compiler.new(ast).eval
end

def entries(dir)
  Dir.entries(dir).select { |file| ![".", ".."].include? file }
end

entries("spec/codegen").each do |category|
  context category do
    entries("spec/codegen/#{category}").each do |name|
      it name do
        contents = File.read("spec/codegen/#{category}/#{name}")
        output = compile(contents)
        expected_output = contents.split("\n")
          .select { |line| line.include? "#" }
          .map { |line| line[2..].rstrip }.join "\n"

        expect(output).to eq(expected_output)
      end
    end
  end
end
context "snapshot" do
  #   it "2022-07-13 21:12:04 -0400" do
  #     ast = parse('component ProfileCard { name } in
  #   "
  #     <div>
  #       profile
  #       <div>${name}</div>
  #     </div>
  #   "
  # end
  # ')
  #     expect(ast).to eq([{ "klass" => "AST::ExprComponentWithAttributes", "name" => "ProfileCard", "attributes" => [["name", { "klass" => "AST::SchemaCapture", "name" => "name", "start_pos" => 24, "end_pos" => 28 }]], "expr" => { "klass" => "AST::SimpleString", "value" => "\n    <div>\n      profile\n      <div>${name}</div>\n    </div>\n  ", "start_pos" => 36, "end_pos" => 101 }, "start_pos" => 0, "end_pos" => 105 }])
  #   end
  #   it "2022-07-13 22:55:36 -0400" do
  #     ast = parse('component CardEntry
  #   name := "string"
  # in
  # "
  #   <div>${this.name}</div>
  # "
  # end

  # ')
  #     expect(ast).to eq([{ "klass" => "AST::BodyComponentWithoutAttrs", "name" => "CardEntry", "constructor_body" => [{ "klass" => "AST::SimpleAssignment", "name" => "name", "expr" => { "klass" => "AST::SimpleString", "value" => "string", "start_pos" => 31, "end_pos" => 39 }, "start_pos" => 23, "end_pos" => 39 }], "expr" => { "klass" => "AST::SimpleString", "value" => "\n  <div>${this.name}</div>\n", "start_pos" => 43, "end_pos" => 72 }, "start_pos" => 0, "end_pos" => 76 }])
  #   end
  #   it "2022-07-13 23:53:09 -0400" do
  #     ast = parse("component CardEntry { name } in
  #   <div></div>
  # end

  # ")
  #     expect(ast).to eq([{ "klass" => "AST::ExprComponentWithAttributes", "name" => "CardEntry", "attributes" => [["name", { "klass" => "AST::SchemaCapture", "name" => "name", "start_pos" => 22, "end_pos" => 26 }]], "expr" => { "klass" => "AST::SimpleElement", "name" => "div", "children" => [], "start_pos" => 34, "end_pos" => 45 }, "start_pos" => 0, "end_pos" => 49 }])
  #   end
  #   it "2022-07-14 01:24:13 -0400" do
  #     ast = parse("component CardEntry { name } in
  #   <div>{name}</div>
  # end
  # ")
  #     expect(ast).to eq([{ "klass" => "AST::ExprComponentWithAttributes", "name" => "CardEntry", "attributes" => [["name", { "klass" => "AST::SchemaCapture", "name" => "name", "start_pos" => 22, "end_pos" => 26 }]], "expr" => { "klass" => "AST::SimpleElement", "name" => "div", "children" => [{ "klass" => "AST::EscapedElementExpr", "value" => { "klass" => "AST::IdLookup", "value" => "name", "start_pos" => 40, "end_pos" => 44 }, "start_pos" => 39, "end_pos" => 45 }], "start_pos" => 34, "end_pos" => 51 }, "start_pos" => 0, "end_pos" => 55 }])
  #   end
  #   it "2022-07-16 13:52:01 -0400" do
  #     ast = parse("class Parser
  #   function constructor(name)
  #     this.name := name
  #   end
  # end")
  #     expect(ast).to eq([{ "klass" => "AST::Class", "name" => "Parser", "parent_class" => nil, "entries" => [{ "klass" => "AST::ConstructorWithArgs", "name" => "constructor", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "name", "start_pos" => 36, "end_pos" => 40 }], "start_pos" => 35, "end_pos" => 41 }, "body" => [{ "klass" => "AST::DotAssignment", "lhs" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::This", "value" => nil, "start_pos" => 46, "end_pos" => 50 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "name", "start_pos" => 51, "end_pos" => 55 }, "start_pos" => 50, "end_pos" => 55 }, "expr" => { "klass" => "AST::IdLookup", "value" => "name", "start_pos" => 59, "end_pos" => 63 }, "start_pos" => 56, "end_pos" => 63 }], "start_pos" => 15, "end_pos" => 69 }], "start_pos" => 0, "end_pos" => 73 }])
  #   end
  #   it "2022-07-16 16:38:25 -0400" do
  #     ast = parse("class Parser
  #   static function from(that)
  #     new this(that.tokens, that.program_string, that.pos)
  #   end

  #   function constructor(tokens, program_string, pos)
  #     this.tokens := tokens
  #     this.program_string := program_string
  #     this.pos := pos
  #   end
  # end
  # ")
  #     expect(ast).to eq([{ "klass" => "AST::Class", "name" => "Parser", "parent_class" => nil, "entries" => [{ "klass" => "AST::StaticMethod", "name" => "from", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "that", "start_pos" => 36, "end_pos" => 40 }], "start_pos" => 35, "end_pos" => 41 }, "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::New", "class_expr" => { "klass" => "AST::This", "value" => nil, "start_pos" => 50, "end_pos" => 54 }, "args" => [{ "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "that", "start_pos" => 55, "end_pos" => 59 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "tokens", "start_pos" => 60, "end_pos" => 66 }, "start_pos" => 59, "end_pos" => 66 }, { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "that", "start_pos" => 68, "end_pos" => 72 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "program_string", "start_pos" => 73, "end_pos" => 87 }, "start_pos" => 72, "end_pos" => 87 }, { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "that", "start_pos" => 89, "end_pos" => 93 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "pos", "start_pos" => 94, "end_pos" => 97 }, "start_pos" => 93, "end_pos" => 97 }], "start_pos" => 46, "end_pos" => 98 }, "start_pos" => 46, "end_pos" => 98 }], "start_pos" => 15, "end_pos" => 104 }, { "klass" => "AST::ConstructorWithArgs", "name" => "constructor", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "tokens", "start_pos" => 129, "end_pos" => 135 }, { "klass" => "AST::SimpleArg", "name" => "program_string", "start_pos" => 137, "end_pos" => 151 }, { "klass" => "AST::SimpleArg", "name" => "pos", "start_pos" => 153, "end_pos" => 156 }], "start_pos" => 128, "end_pos" => 157 }, "body" => [{ "klass" => "AST::DotAssignment", "lhs" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::This", "value" => nil, "start_pos" => 162, "end_pos" => 166 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "tokens", "start_pos" => 167, "end_pos" => 173 }, "start_pos" => 166, "end_pos" => 173 }, "expr" => { "klass" => "AST::IdLookup", "value" => "tokens", "start_pos" => 177, "end_pos" => 183 }, "start_pos" => 174, "end_pos" => 183 }, { "klass" => "AST::DotAssignment", "lhs" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::This", "value" => nil, "start_pos" => 188, "end_pos" => 192 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "program_string", "start_pos" => 193, "end_pos" => 207 }, "start_pos" => 192, "end_pos" => 207 }, "expr" => { "klass" => "AST::IdLookup", "value" => "program_string", "start_pos" => 211, "end_pos" => 225 }, "start_pos" => 208, "end_pos" => 225 }, { "klass" => "AST::DotAssignment", "lhs" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::This", "value" => nil, "start_pos" => 230, "end_pos" => 234 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "pos", "start_pos" => 235, "end_pos" => 238 }, "start_pos" => 234, "end_pos" => 238 }, "expr" => { "klass" => "AST::IdLookup", "value" => "pos", "start_pos" => 242, "end_pos" => 245 }, "start_pos" => 239, "end_pos" => 245 }], "start_pos" => 108, "end_pos" => 251 }], "start_pos" => 0, "end_pos" => 255 }])
  #   end
  #   it "2022-07-16 18:02:41 -0400" do
  #     ast = parse("class Parser
  #   get current_token = this.tokens[this.pos]
  # end
  # ")
  #     expect(ast).to eq([{ "klass" => "AST::Class", "name" => "Parser", "parent_class" => nil, "entries" => [{ "klass" => "AST::OneLineGetter", "name" => "current_token", "expr" => { "klass" => "AST::DynamicLookup", "lhs" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::This", "value" => nil, "start_pos" => 35, "end_pos" => 39 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "tokens", "start_pos" => 40, "end_pos" => 46 }, "start_pos" => 39, "end_pos" => 46 }, "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::This", "value" => nil, "start_pos" => 47, "end_pos" => 51 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "pos", "start_pos" => 52, "end_pos" => 55 }, "start_pos" => 51, "end_pos" => 55 }, "start_pos" => 46, "end_pos" => 56 }, "start_pos" => 15, "end_pos" => 56 }], "start_pos" => 0, "end_pos" => 62 }])
  #   end
  #   it "2022-07-18 18:46:38 -0400" do
  #     ast = parse("class Parser
  #   body := []
  # end
  # ")
  #     expect(ast).to eq([{ "klass" => "AST::Class", "name" => "Parser", "parent_class" => nil, "entries" => [{ "klass" => "AST::InstanceProperty", "name" => "body", "expr" => { "klass" => "AST::ArrayLiteral", "value" => [], "start_pos" => 23, "end_pos" => 25 }, "start_pos" => 15, "end_pos" => 25 }], "start_pos" => 0, "end_pos" => 29 }])
  #   end
  #   it "2022-07-18 21:30:28 -0400" do
  #     ast = parse('function length
  #   this.length
  # end

  # console.log "abc"::length')
  #     expect(ast).to eq([{ "klass" => "AST::MultilineDefWithoutArgs", "name" => "length", "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::This", "value" => nil, "start_pos" => 18, "end_pos" => 22 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "length", "start_pos" => 23, "end_pos" => 29 }, "start_pos" => 22, "end_pos" => 29 }, "start_pos" => 22, "end_pos" => 29 }], "start_pos" => 0, "end_pos" => 33 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Bind", "lhs" => { "klass" => "AST::SimpleString", "value" => "abc", "start_pos" => 47, "end_pos" => 52 }, "function" => { "klass" => "AST::IdLookup", "value" => "length", "start_pos" => 54, "end_pos" => 60 }, "args" => [] }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 35, "end_pos" => 42 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 43, "end_pos" => 46 }, "start_pos" => 42, "end_pos" => 46 }, "start_pos" => 46, "end_pos" => nil }])
  #   end
  #   it "2022-07-18 21:30:42 -0400" do
  #     ast = parse('function length
  #   this.length
  # end

  # console.log "abc"::length(10, 20)')
  #     expect(ast).to eq([{ "klass" => "AST::MultilineDefWithoutArgs", "name" => "length", "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::This", "value" => nil, "start_pos" => 18, "end_pos" => 22 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "length", "start_pos" => 23, "end_pos" => 29 }, "start_pos" => 22, "end_pos" => 29 }, "start_pos" => 22, "end_pos" => 29 }], "start_pos" => 0, "end_pos" => 33 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Bind", "lhs" => { "klass" => "AST::SimpleString", "value" => "abc", "start_pos" => 47, "end_pos" => 52 }, "function" => { "klass" => "AST::IdLookup", "value" => "length", "start_pos" => 54, "end_pos" => 60 }, "args" => [{ "klass" => "AST::Int", "value" => 10, "start_pos" => 61, "end_pos" => 63 }, { "klass" => "AST::Int", "value" => 20, "start_pos" => 65, "end_pos" => 67 }] }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 35, "end_pos" => 42 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 43, "end_pos" => 46 }, "start_pos" => 42, "end_pos" => 46 }, "start_pos" => 46, "end_pos" => nil }])
  #   end
  #   it "2022-07-18 21:50:01 -0400" do
  #     ast = parse("a := {}

  # console.log a?.b")
  #     expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "a", "expr" => { "klass" => "AST::ObjectLiteral", "value" => [], "start_pos" => 5, "end_pos" => 7 }, "start_pos" => 0, "end_pos" => 7 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::OptionalChain", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "start_pos" => 21, "end_pos" => 22 }, "property" => "b", "start_pos" => 22, "end_pos" => 25 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 9, "end_pos" => 16 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 17, "end_pos" => 20 }, "start_pos" => 16, "end_pos" => 20 }, "start_pos" => 20, "end_pos" => 25 }])
  #   end
  #   it "2022-07-18 23:55:11 -0400" do
  #     ast = parse("function ten = 10")
  #     expect(ast).to eq([{ "klass" => "AST::SingleLineDefWithoutArgs", "name" => "ten", "return_value" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 15, "end_pos" => 17 }, "start_pos" => 0, "end_pos" => 17 }])
  #   end
  #   it "2022-07-21 20:26:07 -0400" do
  #     ast = parse("[a] := [1]")
  #     expect(ast).to eq([{ "klass" => "AST::ArrayAssignment", "variables" => ["a"], "expr" => { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 8, "end_pos" => 9 }], "start_pos" => 7, "end_pos" => 10 }, "start_pos" => 0, "end_pos" => 10 }])
  #   end
  #   it "2022-07-21 21:55:29 -0400" do
  #     ast = parse('obj := {
  #   a: 10,
  #   b: "str"
  # }

  # for key in obj
  #   console.log key
  # end')
  #     expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "obj", "expr" => { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "a", "value" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 14, "end_pos" => 16 }, "start_pos" => 11, "end_pos" => 16 }, { "klass" => "AST::SimpleObjectEntry", "key_name" => "b", "value" => { "klass" => "AST::SimpleString", "value" => "str", "start_pos" => 23, "end_pos" => 28 }, "start_pos" => 20, "end_pos" => 28 }], "start_pos" => 7, "end_pos" => 30 }, "start_pos" => 0, "end_pos" => 30 }, { "klass" => "AST::SimpleForInLoop", "variable" => "key", "object_expr" => { "klass" => "AST::IdLookup", "value" => "obj", "start_pos" => 43, "end_pos" => 46 }, "body" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "key", "start_pos" => 61, "end_pos" => 64 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 49, "end_pos" => 56 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 57, "end_pos" => 60 }, "start_pos" => 56, "end_pos" => 60 }, "start_pos" => 60, "end_pos" => 64 }], "start_pos" => 32, "end_pos" => 68 }])
  #   end
  #   it "2022-08-16 00:07:14 -0400" do
  #     ast = parse('double := #{ % * 2 }')
  #     expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "double", "expr" => { "klass" => "AST::ShortFn", "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::AnonIdLookup", "start_pos" => 13, "end_pos" => 14 }, "type" => :*, "rhs" => { "klass" => "AST::Int", "value" => 2, "start_pos" => 17, "end_pos" => 18 }, "start_pos" => 13, "end_pos" => 18 }, "start_pos" => 10, "end_pos" => 20 }, "start_pos" => 0, "end_pos" => 20 }])
  #   end
  #   it "2022-08-16 00:07:36 -0400" do
  #     ast = parse('schema User = { id: #{ % > 10 } }
  # ')
  #     expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "User", "schema_expr" => [["id", { "klass" => "AST::ShortFn", "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::AnonIdLookup", "start_pos" => 23, "end_pos" => 24 }, "type" => :>, "rhs" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 27, "end_pos" => 29 }, "start_pos" => 23, "end_pos" => 29 }, "start_pos" => 20, "end_pos" => 31 }]], "start_pos" => 0, "end_pos" => 33 }])
  #   end
  #   it "2022-08-16 01:04:33 -0400" do
  #     ast = parse('schema Gt1 = #{ % > 1 }

  # case function factorial
  # when (Gt1(n))
  #   factorial(n - 1) + factorial(n - 2)
  # when (1)
  #   1
  # when (0)
  #   0
  # end

  # console.log factorial(20)')
  #     expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "Gt1", "schema_expr" => { "klass" => "AST::ShortFn", "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::AnonIdLookup", "start_pos" => 16, "end_pos" => 17 }, "type" => :>, "rhs" => { "klass" => "AST::Int", "value" => 1, "start_pos" => 20, "end_pos" => 21 }, "start_pos" => 16, "end_pos" => 21 }, "start_pos" => 13, "end_pos" => 23 }, "start_pos" => 0, "end_pos" => 23 }, { "klass" => "AST::CaseFunctionDefinition", "name" => "factorial", "patterns" => [{ "klass" => "AST::CaseFnPattern", "this_pattern" => nil, "patterns" => [{ "klass" => "AST::SimpleSchemaArg", "schema_name" => "Gt1", "name" => "n", "start_pos" => 55, "end_pos" => 61 }], "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "n", "start_pos" => 75, "end_pos" => 76 }, "type" => :-, "rhs" => { "klass" => "AST::Int", "value" => 1, "start_pos" => 79, "end_pos" => 80 }, "start_pos" => 75, "end_pos" => 80 }], "expr" => { "klass" => "AST::IdLookup", "value" => "factorial", "start_pos" => 65, "end_pos" => 74 }, "start_pos" => 74, "end_pos" => 81 }, "type" => :+, "rhs" => { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "n", "start_pos" => 94, "end_pos" => 95 }, "type" => :-, "rhs" => { "klass" => "AST::Int", "value" => 2, "start_pos" => 98, "end_pos" => 99 }, "start_pos" => 94, "end_pos" => 99 }], "expr" => { "klass" => "AST::IdLookup", "value" => "factorial", "start_pos" => 84, "end_pos" => 93 }, "start_pos" => 93, "end_pos" => 100 }, "start_pos" => 74, "end_pos" => 100 }, "start_pos" => 74, "end_pos" => 100 }], "start_pos" => 49, "end_pos" => 100 }, { "klass" => "AST::CaseFnPattern", "this_pattern" => nil, "patterns" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 107, "end_pos" => 108 }], "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::Int", "value" => 1, "start_pos" => 112, "end_pos" => 113 }, "start_pos" => 112, "end_pos" => 113 }], "start_pos" => 101, "end_pos" => 113 }, { "klass" => "AST::CaseFnPattern", "this_pattern" => nil, "patterns" => [{ "klass" => "AST::Int", "value" => 0, "start_pos" => 120, "end_pos" => 121 }], "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::Int", "value" => 0, "start_pos" => 125, "end_pos" => 126 }, "start_pos" => 125, "end_pos" => 126 }], "start_pos" => 114, "end_pos" => 126 }], "start_pos" => 25, "end_pos" => 130 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Int", "value" => 20, "start_pos" => 154, "end_pos" => 156 }], "expr" => { "klass" => "AST::IdLookup", "value" => "factorial", "start_pos" => 144, "end_pos" => 153 }, "start_pos" => 153, "end_pos" => 157 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 132, "end_pos" => 139 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 140, "end_pos" => 143 }, "start_pos" => 139, "end_pos" => 143 }, "start_pos" => 143, "end_pos" => 157 }])
  #   end
  #   it "2022-08-16 01:04:42 -0400" do
  #     ast = parse('case function to_a
  # when Array::()
  #   this
  # when String::()
  #   Array.from this
  # when Object::()
  #   Object.entries this
  # end

  # console.log { a: 1 }::to_a
  # console.log "abc"::to_a
  # ')
  #     expect(ast).to eq([{ "klass" => "AST::CaseFunctionDefinition", "name" => "to_a", "patterns" => [{ "klass" => "AST::CaseFnPattern", "this_pattern" => { "klass" => "AST::ThisSchemaArg", "schema" => { "klass" => "AST::IdLookup", "value" => "Array", "start_pos" => 24, "end_pos" => 29 }, "start_pos" => 24, "end_pos" => 31 }, "patterns" => [], "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::This", "value" => nil, "start_pos" => 36, "end_pos" => 40 }, "start_pos" => 36, "end_pos" => 40 }], "start_pos" => 19, "end_pos" => 40 }, { "klass" => "AST::CaseFnPattern", "this_pattern" => { "klass" => "AST::ThisSchemaArg", "schema" => { "klass" => "AST::IdLookup", "value" => "String", "start_pos" => 46, "end_pos" => 52 }, "start_pos" => 46, "end_pos" => 54 }, "patterns" => [], "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::This", "value" => nil, "start_pos" => 70, "end_pos" => 74 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "Array", "start_pos" => 59, "end_pos" => 64 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "from", "start_pos" => 65, "end_pos" => 69 }, "start_pos" => 64, "end_pos" => 69 }, "start_pos" => 69, "end_pos" => 74 }, "start_pos" => 69, "end_pos" => 74 }], "start_pos" => 41, "end_pos" => 74 }, { "klass" => "AST::CaseFnPattern", "this_pattern" => { "klass" => "AST::ThisSchemaArg", "schema" => { "klass" => "AST::IdLookup", "value" => "Object", "start_pos" => 80, "end_pos" => 86 }, "start_pos" => 80, "end_pos" => 88 }, "patterns" => [], "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::This", "value" => nil, "start_pos" => 108, "end_pos" => 112 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "Object", "start_pos" => 93, "end_pos" => 99 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "entries", "start_pos" => 100, "end_pos" => 107 }, "start_pos" => 99, "end_pos" => 107 }, "start_pos" => 107, "end_pos" => 112 }, "start_pos" => 107, "end_pos" => 112 }], "start_pos" => 75, "end_pos" => 112 }], "start_pos" => 0, "end_pos" => 116 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Bind", "lhs" => { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "a", "value" => { "klass" => "AST::Int", "value" => 1, "start_pos" => 135, "end_pos" => 136 }, "start_pos" => 132, "end_pos" => 136 }], "start_pos" => 130, "end_pos" => 138 }, "function" => { "klass" => "AST::IdLookup", "value" => "to_a", "start_pos" => 140, "end_pos" => 144 }, "args" => [] }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 118, "end_pos" => 125 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 126, "end_pos" => 129 }, "start_pos" => 125, "end_pos" => 129 }, "start_pos" => 129, "end_pos" => nil }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Bind", "lhs" => { "klass" => "AST::SimpleString", "value" => "abc", "start_pos" => 157, "end_pos" => 162 }, "function" => { "klass" => "AST::IdLookup", "value" => "to_a", "start_pos" => 164, "end_pos" => 168 }, "args" => [] }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 145, "end_pos" => 152 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 153, "end_pos" => 156 }, "start_pos" => 152, "end_pos" => 156 }, "start_pos" => 156, "end_pos" => nil }])
  #   end
  #   it "2022-08-16 19:08:33 -0400" do
  #     ast = parse("function to_a = Array.from this

  # a := 1..5

  # console.log a
  # console.log a.filter(x => x > 3)::to_a
  # console.log a::to_a")
  #     expect(ast).to eq([{ "klass" => "AST::SingleLineDefWithoutArgs", "name" => "to_a", "return_value" => { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::This", "value" => nil, "start_pos" => 27, "end_pos" => 31 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "Array", "start_pos" => 16, "end_pos" => 21 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "from", "start_pos" => 22, "end_pos" => 26 }, "start_pos" => 21, "end_pos" => 26 }, "start_pos" => 26, "end_pos" => 31 }, "start_pos" => 0, "end_pos" => 31 }, { "klass" => "AST::SimpleAssignment", "name" => "a", "expr" => { "klass" => "AST::Range", "lhs" => { "klass" => "AST::Int", "value" => 1, "start_pos" => 38, "end_pos" => 39 }, "rhs" => { "klass" => "AST::Int", "value" => 5, "start_pos" => 41, "end_pos" => 42 }, "start_pos" => 38, "end_pos" => 42 }, "start_pos" => 33, "end_pos" => 42 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "a", "start_pos" => 56, "end_pos" => 57 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 44, "end_pos" => 51 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 52, "end_pos" => 55 }, "start_pos" => 51, "end_pos" => 55 }, "start_pos" => 55, "end_pos" => 57 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Bind", "lhs" => { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::SingleLineArrowFnWithOneArg", "arg" => "x", "return_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "x", "start_pos" => 84, "end_pos" => 85 }, "type" => :>, "rhs" => { "klass" => "AST::Int", "value" => 3, "start_pos" => 88, "end_pos" => 89 }, "start_pos" => 84, "end_pos" => 89 }, "start_pos" => 79, "end_pos" => 89 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "start_pos" => 70, "end_pos" => 71 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "filter", "start_pos" => 72, "end_pos" => 78 }, "start_pos" => 71, "end_pos" => 78 }, "start_pos" => 78, "end_pos" => 90 }, "function" => { "klass" => "AST::IdLookup", "value" => "to_a", "start_pos" => 92, "end_pos" => 96 }, "args" => [] }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 58, "end_pos" => 65 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 66, "end_pos" => 69 }, "start_pos" => 65, "end_pos" => 69 }, "start_pos" => 69, "end_pos" => nil }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Bind", "lhs" => { "klass" => "AST::IdLookup", "value" => "a", "start_pos" => 109, "end_pos" => 110 }, "function" => { "klass" => "AST::IdLookup", "value" => "to_a", "start_pos" => 112, "end_pos" => 116 }, "args" => [] }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 97, "end_pos" => 104 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 105, "end_pos" => 108 }, "start_pos" => 104, "end_pos" => 108 }, "start_pos" => 108, "end_pos" => nil }])
  #   end
  #   it "2022-08-16 19:08:47 -0400" do
  #     ast = parse('function times(callback)
  #   for item of this
  #     callback item
  #   end
  # end

  # 0..100::times(#{
  #   console.log %
  # })
  # ')
  #     expect(ast).to eq([{ "klass" => "AST::MultilineDefWithArgs", "name" => "times", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "callback", "start_pos" => 15, "end_pos" => 23 }], "start_pos" => 14, "end_pos" => 24 }, "body" => [{ "klass" => "AST::SimpleForOfLoop", "iter_name" => "item", "arr_expr" => { "klass" => "AST::This", "value" => nil, "start_pos" => 39, "end_pos" => 43 }, "body" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "item", "start_pos" => 57, "end_pos" => 61 }], "expr" => { "klass" => "AST::IdLookup", "value" => "callback", "start_pos" => 48, "end_pos" => 56 }, "start_pos" => 56, "end_pos" => 61 }], "start_pos" => 27, "end_pos" => 67 }], "start_pos" => 0, "end_pos" => 71 }, { "klass" => "AST::Bind", "lhs" => { "klass" => "AST::Range", "lhs" => { "klass" => "AST::Int", "value" => 0, "start_pos" => 73, "end_pos" => 74 }, "rhs" => { "klass" => "AST::Int", "value" => 100, "start_pos" => 76, "end_pos" => 79 }, "start_pos" => 73, "end_pos" => 79 }, "function" => { "klass" => "AST::IdLookup", "value" => "times", "start_pos" => 81, "end_pos" => 86 }, "args" => [{ "klass" => "AST::ShortFn", "return_expr" => { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::AnonIdLookup", "start_pos" => 104, "end_pos" => 105 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 92, "end_pos" => 99 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 100, "end_pos" => 103 }, "start_pos" => 99, "end_pos" => 103 }, "start_pos" => 103, "end_pos" => 105 }, "start_pos" => 87, "end_pos" => 107 }] }])
  #   end
  #   it "2022-08-16 19:32:26 -0400" do
  #     ast = parse('function times(callback)
  #   for item of this
  #     callback item
  #   end
  # end

  # 0..100::times #{
  #   console.log %
  # }
  # ')
  #     expect(ast).to eq([{ "klass" => "AST::MultilineDefWithArgs", "name" => "times", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "callback", "start_pos" => 15, "end_pos" => 23 }], "start_pos" => 14, "end_pos" => 24 }, "body" => [{ "klass" => "AST::SimpleForOfLoop", "iter_name" => "item", "arr_expr" => { "klass" => "AST::This", "value" => nil, "start_pos" => 39, "end_pos" => 43 }, "body" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "item", "start_pos" => 57, "end_pos" => 61 }], "expr" => { "klass" => "AST::IdLookup", "value" => "callback", "start_pos" => 48, "end_pos" => 56 }, "start_pos" => 56, "end_pos" => 61 }], "start_pos" => 27, "end_pos" => 67 }], "start_pos" => 0, "end_pos" => 71 }, { "klass" => "AST::Bind", "lhs" => { "klass" => "AST::Range", "lhs" => { "klass" => "AST::Int", "value" => 0, "start_pos" => 73, "end_pos" => 74 }, "rhs" => { "klass" => "AST::Int", "value" => 100, "start_pos" => 76, "end_pos" => 79 }, "start_pos" => 73, "end_pos" => 79 }, "function" => { "klass" => "AST::IdLookup", "value" => "times", "start_pos" => 81, "end_pos" => 86 }, "args" => [{ "klass" => "AST::ShortFn", "return_expr" => { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::AnonIdLookup", "start_pos" => 104, "end_pos" => 105 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 92, "end_pos" => 99 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 100, "end_pos" => 103 }, "start_pos" => 99, "end_pos" => 103 }, "start_pos" => 103, "end_pos" => 105 }, "start_pos" => 87, "end_pos" => 107 }] }])
  #   end
  #   it "2022-08-16 19:48:19 -0400" do
  #     ast = parse('function times(callback)
  #   for item of this
  #     callback item
  #   end
  # end

  # 0..100::times #{ |num|
  #   console.log num
  # }
  # ')
  #     expect(ast).to eq([{ "klass" => "AST::MultilineDefWithArgs", "name" => "times", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "callback", "start_pos" => 15, "end_pos" => 23 }], "start_pos" => 14, "end_pos" => 24 }, "body" => [{ "klass" => "AST::SimpleForOfLoop", "iter_name" => "item", "arr_expr" => { "klass" => "AST::This", "value" => nil, "start_pos" => 39, "end_pos" => 43 }, "body" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "item", "start_pos" => 57, "end_pos" => 61 }], "expr" => { "klass" => "AST::IdLookup", "value" => "callback", "start_pos" => 48, "end_pos" => 56 }, "start_pos" => 56, "end_pos" => 61 }], "start_pos" => 27, "end_pos" => 67 }], "start_pos" => 0, "end_pos" => 71 }, { "klass" => "AST::Bind", "lhs" => { "klass" => "AST::Range", "lhs" => { "klass" => "AST::Int", "value" => 0, "start_pos" => 73, "end_pos" => 74 }, "rhs" => { "klass" => "AST::Int", "value" => 100, "start_pos" => 76, "end_pos" => 79 }, "start_pos" => 73, "end_pos" => 79 }, "function" => { "klass" => "AST::IdLookup", "value" => "times", "start_pos" => 81, "end_pos" => 86 }, "args" => [{ "klass" => "AST::ShortFnWithArgs", "args" => ["num"], "return_expr" => { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "num", "start_pos" => 110, "end_pos" => 113 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 98, "end_pos" => 105 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 106, "end_pos" => 109 }, "start_pos" => 105, "end_pos" => 109 }, "start_pos" => 109, "end_pos" => 113 }, "start_pos" => 87, "end_pos" => 115 }] }])
  #   end
  #   it "2022-08-16 22:35:35 -0400" do
  #     ast = parse("case function fib
  # when (0)
  #   0
  # when (1)
  #   1
  # when (n)
  #   fib(n - 1) + fib(n - 2)
  # end

  # console.log fib(14)
  # ")
  #     expect(ast).to eq([{ "klass" => "AST::CaseFunctionDefinition", "name" => "fib", "patterns" => [{ "klass" => "AST::CaseFnPattern", "this_pattern" => nil, "patterns" => [{ "klass" => "AST::Int", "value" => 0, "start_pos" => 24, "end_pos" => 25 }], "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::Int", "value" => 0, "start_pos" => 29, "end_pos" => 30 }, "start_pos" => 29, "end_pos" => 30 }], "start_pos" => 18, "end_pos" => 30 }, { "klass" => "AST::CaseFnPattern", "this_pattern" => nil, "patterns" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 37, "end_pos" => 38 }], "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::Int", "value" => 1, "start_pos" => 42, "end_pos" => 43 }, "start_pos" => 42, "end_pos" => 43 }], "start_pos" => 31, "end_pos" => 43 }, { "klass" => "AST::CaseFnPattern", "this_pattern" => nil, "patterns" => [{ "klass" => "AST::SimpleArg", "name" => "n", "start_pos" => 50, "end_pos" => 51 }], "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "n", "start_pos" => 59, "end_pos" => 60 }, "type" => :-, "rhs" => { "klass" => "AST::Int", "value" => 1, "start_pos" => 63, "end_pos" => 64 }, "start_pos" => 59, "end_pos" => 64 }], "expr" => { "klass" => "AST::IdLookup", "value" => "fib", "start_pos" => 55, "end_pos" => 58 }, "start_pos" => 58, "end_pos" => 65 }, "type" => :+, "rhs" => { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "n", "start_pos" => 72, "end_pos" => 73 }, "type" => :-, "rhs" => { "klass" => "AST::Int", "value" => 2, "start_pos" => 76, "end_pos" => 77 }, "start_pos" => 72, "end_pos" => 77 }], "expr" => { "klass" => "AST::IdLookup", "value" => "fib", "start_pos" => 68, "end_pos" => 71 }, "start_pos" => 71, "end_pos" => 78 }, "start_pos" => 58, "end_pos" => 78 }, "start_pos" => 58, "end_pos" => 78 }], "start_pos" => 44, "end_pos" => 78 }], "start_pos" => 0, "end_pos" => 82 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Int", "value" => 14, "start_pos" => 100, "end_pos" => 102 }], "expr" => { "klass" => "AST::IdLookup", "value" => "fib", "start_pos" => 96, "end_pos" => 99 }, "start_pos" => 99, "end_pos" => 103 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 84, "end_pos" => 91 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 92, "end_pos" => 95 }, "start_pos" => 91, "end_pos" => 95 }, "start_pos" => 95, "end_pos" => 103 }])
  #   end
  #   it "2022-08-17 17:41:54 -0400" do
  #     ast = parse("console.log 31 mod 10")
  #     expect(ast).to eq([{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Op", "lhs" => { "klass" => "AST::Int", "value" => 31, "start_pos" => 12, "end_pos" => 14 }, "type" => :mod, "rhs" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 19, "end_pos" => 21 }, "start_pos" => 12, "end_pos" => 21 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 0, "end_pos" => 7 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 8, "end_pos" => 11 }, "start_pos" => 7, "end_pos" => 11 }, "start_pos" => 11, "end_pos" => 21 }])
  #   end
  #   it "2022-08-17 18:01:27 -0400" do
  #     ast = parse("console.log [1]::zip [2]")
  #     expect(ast).to eq([{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Bind", "lhs" => { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 13, "end_pos" => 14 }], "start_pos" => 12, "end_pos" => 15 }, "function" => { "klass" => "AST::IdLookup", "value" => "zip", "start_pos" => 17, "end_pos" => 20 }, "args" => [{ "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 2, "start_pos" => 22, "end_pos" => 23 }], "start_pos" => 21, "end_pos" => 24 }] }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 0, "end_pos" => 7 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 8, "end_pos" => 11 }, "start_pos" => 7, "end_pos" => 11 }, "start_pos" => 11, "end_pos" => nil }])
  #   end
  #   it "2022-08-17 18:15:29 -0400" do
  #     ast = parse("[1]::test [2], [1]")
  #     expect(ast).to eq([{ "klass" => "AST::Bind", "lhs" => { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 1, "end_pos" => 2 }], "start_pos" => 0, "end_pos" => 3 }, "function" => { "klass" => "AST::IdLookup", "value" => "test", "start_pos" => 5, "end_pos" => 9 }, "args" => [{ "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 2, "start_pos" => 11, "end_pos" => 12 }], "start_pos" => 10, "end_pos" => 13 }, { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 16, "end_pos" => 17 }], "start_pos" => 15, "end_pos" => 18 }] }])
  #   end
  #   it "2022-08-19 00:22:49 -0400" do
  #     ast = parse("function a(null) = 1

  # console.log a(null)")
  #     expect(ast).to eq([{ "klass" => "AST::SingleLineDefWithArgs", "name" => "a", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::NullSchema", "start_pos" => 11, "end_pos" => 15 }], "start_pos" => 10, "end_pos" => 16 }, "return_value" => { "klass" => "AST::Int", "value" => 1, "start_pos" => 19, "end_pos" => 20 }, "start_pos" => 0, "end_pos" => 20 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Null", "start_pos" => 36, "end_pos" => 40 }], "expr" => { "klass" => "AST::IdLookup", "value" => "a", "start_pos" => 34, "end_pos" => 35 }, "start_pos" => 35, "end_pos" => 41 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 22, "end_pos" => 29 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 30, "end_pos" => 33 }, "start_pos" => 29, "end_pos" => 33 }, "start_pos" => 33, "end_pos" => 41 }])
  #   end
  #   it "2022-08-29 21:55:37 -0400" do
  #     ast = parse('map := new Map([
  #   ["a", [1, 2, { a: 11 }]]
  # ])

  # console.log ["a", [1, 2, { a: 11 }]] in map
  # console.log new Map([["a", [1, 2, { a: 11 }]]]) == map')
  #     expect(ast).to eq([{ "klass" => "AST::SimpleAssignment", "name" => "map", "expr" => { "klass" => "AST::New", "class_expr" => { "klass" => "AST::IdLookup", "value" => "Map", "start_pos" => 11, "end_pos" => 14 }, "args" => [{ "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::SimpleString", "value" => "a", "start_pos" => 20, "end_pos" => 23 }, { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 26, "end_pos" => 27 }, { "klass" => "AST::Int", "value" => 2, "start_pos" => 29, "end_pos" => 30 }, { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "a", "value" => { "klass" => "AST::Int", "value" => 11, "start_pos" => 37, "end_pos" => 39 }, "start_pos" => 34, "end_pos" => 39 }], "start_pos" => 32, "end_pos" => 41 }], "start_pos" => 25, "end_pos" => 42 }], "start_pos" => 19, "end_pos" => 43 }], "start_pos" => 15, "end_pos" => 45 }], "start_pos" => 7, "end_pos" => 46 }, "start_pos" => 0, "end_pos" => 46 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Op", "lhs" => { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::SimpleString", "value" => "a", "start_pos" => 61, "end_pos" => 64 }, { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 67, "end_pos" => 68 }, { "klass" => "AST::Int", "value" => 2, "start_pos" => 70, "end_pos" => 71 }, { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "a", "value" => { "klass" => "AST::Int", "value" => 11, "start_pos" => 78, "end_pos" => 80 }, "start_pos" => 75, "end_pos" => 80 }], "start_pos" => 73, "end_pos" => 82 }], "start_pos" => 66, "end_pos" => 83 }], "start_pos" => 60, "end_pos" => 84 }, "type" => :in, "rhs" => { "klass" => "AST::IdLookup", "value" => "map", "start_pos" => 88, "end_pos" => 91 }, "start_pos" => 60, "end_pos" => 91 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 48, "end_pos" => 55 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 56, "end_pos" => 59 }, "start_pos" => 55, "end_pos" => 59 }, "start_pos" => 59, "end_pos" => 91 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Op", "lhs" => { "klass" => "AST::New", "class_expr" => { "klass" => "AST::IdLookup", "value" => "Map", "start_pos" => 108, "end_pos" => 111 }, "args" => [{ "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::SimpleString", "value" => "a", "start_pos" => 114, "end_pos" => 117 }, { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 120, "end_pos" => 121 }, { "klass" => "AST::Int", "value" => 2, "start_pos" => 123, "end_pos" => 124 }, { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "a", "value" => { "klass" => "AST::Int", "value" => 11, "start_pos" => 131, "end_pos" => 133 }, "start_pos" => 128, "end_pos" => 133 }], "start_pos" => 126, "end_pos" => 135 }], "start_pos" => 119, "end_pos" => 136 }], "start_pos" => 113, "end_pos" => 137 }], "start_pos" => 112, "end_pos" => 138 }], "start_pos" => 104, "end_pos" => 139 }, "type" => :==, "rhs" => { "klass" => "AST::IdLookup", "value" => "map", "start_pos" => 143, "end_pos" => 146 }, "start_pos" => 104, "end_pos" => 146 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 92, "end_pos" => 99 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 100, "end_pos" => 103 }, "start_pos" => 99, "end_pos" => 103 }, "start_pos" => 103, "end_pos" => 146 }])
  #   end
  #   it "2022-08-29 22:14:55 -0400" do
  #     ast = parse("schema A = 1 | 2 | 3

  # for a of A
  #   console.log a
  # end")
  #     expect(ast).to eq([{ "klass" => "AST::SchemaDefinition", "name" => "A", "schema_expr" => { "klass" => "AST::SchemaUnion", "schema_exprs" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 11, "end_pos" => 12 }, { "klass" => "AST::Int", "value" => 2, "start_pos" => 15, "end_pos" => 16 }, { "klass" => "AST::Int", "value" => 3, "start_pos" => 19, "end_pos" => 20 }], "start_pos" => 11, "end_pos" => 20 }, "start_pos" => 0, "end_pos" => 20 }, { "klass" => "AST::SimpleForOfLoop", "iter_name" => "a", "arr_expr" => { "klass" => "AST::IdLookup", "value" => "A", "start_pos" => 31, "end_pos" => 32 }, "body" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "a", "start_pos" => 47, "end_pos" => 48 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 35, "end_pos" => 42 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 43, "end_pos" => 46 }, "start_pos" => 42, "end_pos" => 46 }, "start_pos" => 46, "end_pos" => 48 }], "start_pos" => 22, "end_pos" => 52 }])
  #   end
  #   it "2022-08-29 22:42:57 -0400" do
  #     ast = parse("a = 11
  # ")
  #     expect(ast).to eq([{ "klass" => "AST::SimpleReassignment", "name" => "a", "expr" => { "klass" => "AST::Int", "value" => 11, "start_pos" => 4, "end_pos" => 6 }, "start_pos" => 0, "end_pos" => 6 }])
  #   end
  #   it "2022-08-29 23:22:36 -0400" do
  #     ast = parse("console.log [...[1, 2, 3]]
  # ")
  #     expect(ast).to eq([{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::SpreadExpr", "value" => { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 17, "end_pos" => 18 }, { "klass" => "AST::Int", "value" => 2, "start_pos" => 20, "end_pos" => 21 }, { "klass" => "AST::Int", "value" => 3, "start_pos" => 23, "end_pos" => 24 }], "start_pos" => 16, "end_pos" => 25 }, "start_pos" => 13, "end_pos" => 25 }], "start_pos" => 12, "end_pos" => 26 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 0, "end_pos" => 7 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 8, "end_pos" => 11 }, "start_pos" => 7, "end_pos" => 11 }, "start_pos" => 11, "end_pos" => 26 }])
  #   end
  #   it "2022-08-29 23:49:29 -0400" do
  #     ast = parse("function Array::append(item) = [...this, item]

  # console.log [1]::append(10)")
  #     expect(ast).to eq([{ "klass" => "AST::SingleLineBindFunctionDefinition", "object_name" => "Array", "function_name" => "append", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "item", "start_pos" => 23, "end_pos" => 27 }], "start_pos" => 22, "end_pos" => 28 }, "return_expr" => { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::SpreadExpr", "value" => { "klass" => "AST::This", "value" => nil, "start_pos" => 35, "end_pos" => 39 }, "start_pos" => 32, "end_pos" => 39 }, { "klass" => "AST::IdLookup", "value" => "item", "start_pos" => 41, "end_pos" => 45 }], "start_pos" => 31, "end_pos" => 46 }, "start_pos" => 0, "end_pos" => 46 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Bind", "lhs" => { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::Int", "value" => 1, "start_pos" => 61, "end_pos" => 62 }], "start_pos" => 60, "end_pos" => 63 }, "function" => { "klass" => "AST::IdLookup", "value" => "append", "start_pos" => 65, "end_pos" => 71 }, "args" => [{ "klass" => "AST::Int", "value" => 10, "start_pos" => 72, "end_pos" => 74 }] }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 48, "end_pos" => 55 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 56, "end_pos" => 59 }, "start_pos" => 55, "end_pos" => 59 }, "start_pos" => 59, "end_pos" => nil }])
  #   end
  #   it "2022-08-30 00:10:58 -0400" do
  #     ast = parse('console.log [..."a".."z"]
  # console.log [...0..10]
  # ')
  #     expect(ast).to eq([{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::SpreadExpr", "value" => { "klass" => "AST::Range", "lhs" => { "klass" => "AST::SimpleString", "value" => "a", "start_pos" => 16, "end_pos" => 19 }, "rhs" => { "klass" => "AST::SimpleString", "value" => "z", "start_pos" => 21, "end_pos" => 24 }, "start_pos" => 16, "end_pos" => 24 }, "start_pos" => 13, "end_pos" => 24 }], "start_pos" => 12, "end_pos" => 25 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 0, "end_pos" => 7 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 8, "end_pos" => 11 }, "start_pos" => 7, "end_pos" => 11 }, "start_pos" => 11, "end_pos" => 25 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::SpreadExpr", "value" => { "klass" => "AST::Range", "lhs" => { "klass" => "AST::Int", "value" => 0, "start_pos" => 42, "end_pos" => 43 }, "rhs" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 45, "end_pos" => 47 }, "start_pos" => 42, "end_pos" => 47 }, "start_pos" => 39, "end_pos" => 47 }], "start_pos" => 38, "end_pos" => 48 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 26, "end_pos" => 33 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 34, "end_pos" => 37 }, "start_pos" => 33, "end_pos" => 37 }, "start_pos" => 37, "end_pos" => 48 }])
  #   end
  #   it "2022-08-30 01:28:16 -0400" do
  #     ast = parse("console.log [num * 10 for num in 0..10]
  # ")
  #     expect(ast).to eq([{ "klass" => "AST::FnCall", "args" => [{ "if_expr" => nil, "klass" => "AST::ArrayComprehension", "expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "num", "start_pos" => 13, "end_pos" => 16 }, "type" => :*, "rhs" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 19, "end_pos" => 21 }, "start_pos" => 13, "end_pos" => 21 }, "variable" => "num", "array_expr" => { "klass" => "AST::Range", "lhs" => { "klass" => "AST::Int", "value" => 0, "start_pos" => 33, "end_pos" => 34 }, "rhs" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 36, "end_pos" => 38 }, "start_pos" => 33, "end_pos" => 38 }, "start_pos" => 12, "end_pos" => 39 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 0, "end_pos" => 7 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 8, "end_pos" => 11 }, "start_pos" => 7, "end_pos" => 11 }, "start_pos" => 11, "end_pos" => 39 }])
  #   end
  #   it "2022-08-30 01:36:41 -0400" do
  #     ast = parse("console.log [num * 10 for num in 0..10 if num > 3]
  # ")
  #     expect(ast).to eq([{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::ArrayComprehension", "expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "num", "start_pos" => 13, "end_pos" => 16 }, "type" => :*, "rhs" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 19, "end_pos" => 21 }, "start_pos" => 13, "end_pos" => 21 }, "variable" => "num", "array_expr" => { "klass" => "AST::Range", "lhs" => { "klass" => "AST::Int", "value" => 0, "start_pos" => 33, "end_pos" => 34 }, "rhs" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 36, "end_pos" => 38 }, "start_pos" => 33, "end_pos" => 38 }, "if_expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::IdLookup", "value" => "num", "start_pos" => 42, "end_pos" => 45 }, "type" => :>, "rhs" => { "klass" => "AST::Int", "value" => 3, "start_pos" => 48, "end_pos" => 49 }, "start_pos" => 42, "end_pos" => 49 }, "start_pos" => 12, "end_pos" => 50 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 0, "end_pos" => 7 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 8, "end_pos" => 11 }, "start_pos" => 7, "end_pos" => 11 }, "start_pos" => 11, "end_pos" => 50 }])
  #   end
  #   it "2022-09-07 21:01:13 -0400" do
  #     ast = parse("function Array::group_by(key)

  # end")
  #     expect(ast).to eq([{ "klass" => "AST::MultiLineBindFunctionDefinition", "object_name" => "Array", "function_name" => "group_by", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "key", "start_pos" => 25, "end_pos" => 28 }], "start_pos" => 24, "end_pos" => 29 }, "body" => [], "start_pos" => 0, "end_pos" => 36 }])
  #   end
  #   it "2022-09-07 21:20:51 -0400" do
  #     ast = parse('function Array::group_by(key)
  #   result := {}
  #   for obj of this
  #     result[obj[key]] ||= []
  #     result[obj[key]].push(obj)
  #   end

  #   return result
  # end

  # arr := [{ id: 1, value: 10 }, { id: 1, value: 10 }]

  # console.log arr::group_by "id"
  # ')
  #     expect(ast).to eq([{ "klass" => "AST::MultiLineBindFunctionDefinition", "object_name" => "Array", "function_name" => "group_by", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "key", "start_pos" => 25, "end_pos" => 28 }], "start_pos" => 24, "end_pos" => 29 }, "body" => [{ "klass" => "AST::SimpleAssignment", "name" => "result", "expr" => { "klass" => "AST::ObjectLiteral", "value" => [], "start_pos" => 42, "end_pos" => 44 }, "start_pos" => 32, "end_pos" => 44 }, { "klass" => "AST::SimpleForOfLoop", "iter_name" => "obj", "arr_expr" => { "klass" => "AST::This", "value" => nil, "start_pos" => 58, "end_pos" => 62 }, "body" => [{ "klass" => "AST::DefaultAssignment", "lhs" => { "klass" => "AST::DynamicLookup", "lhs" => { "klass" => "AST::IdLookup", "value" => "result", "start_pos" => 67, "end_pos" => 73 }, "expr" => { "klass" => "AST::DynamicLookup", "lhs" => { "klass" => "AST::IdLookup", "value" => "obj", "start_pos" => 74, "end_pos" => 77 }, "expr" => { "klass" => "AST::IdLookup", "value" => "key", "start_pos" => 78, "end_pos" => 81 }, "start_pos" => 77, "end_pos" => 82 }, "start_pos" => 73, "end_pos" => 83 }, "expr" => { "klass" => "AST::ArrayLiteral", "value" => [], "start_pos" => 88, "end_pos" => 90 }, "start_pos" => 73, "end_pos" => 90 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::IdLookup", "value" => "obj", "start_pos" => 117, "end_pos" => 120 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::DynamicLookup", "lhs" => { "klass" => "AST::IdLookup", "value" => "result", "start_pos" => 95, "end_pos" => 101 }, "expr" => { "klass" => "AST::DynamicLookup", "lhs" => { "klass" => "AST::IdLookup", "value" => "obj", "start_pos" => 102, "end_pos" => 105 }, "expr" => { "klass" => "AST::IdLookup", "value" => "key", "start_pos" => 106, "end_pos" => 109 }, "start_pos" => 105, "end_pos" => 110 }, "start_pos" => 101, "end_pos" => 111 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "push", "start_pos" => 112, "end_pos" => 116 }, "start_pos" => 111, "end_pos" => 116 }, "start_pos" => 116, "end_pos" => 121 }], "start_pos" => 47, "end_pos" => 127 }, { "klass" => "AST::Return", "value" => { "klass" => "AST::IdLookup", "value" => "result", "start_pos" => 138, "end_pos" => 144 }, "start_pos" => 131, "end_pos" => 144 }], "start_pos" => 0, "end_pos" => 148 }, { "klass" => "AST::SimpleAssignment", "name" => "arr", "expr" => { "klass" => "AST::ArrayLiteral", "value" => [{ "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "id", "value" => { "klass" => "AST::Int", "value" => 1, "start_pos" => 164, "end_pos" => 165 }, "start_pos" => 160, "end_pos" => 165 }, { "klass" => "AST::SimpleObjectEntry", "key_name" => "value", "value" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 174, "end_pos" => 176 }, "start_pos" => 167, "end_pos" => 176 }], "start_pos" => 158, "end_pos" => 178 }, { "klass" => "AST::ObjectLiteral", "value" => [{ "klass" => "AST::SimpleObjectEntry", "key_name" => "id", "value" => { "klass" => "AST::Int", "value" => 1, "start_pos" => 186, "end_pos" => 187 }, "start_pos" => 182, "end_pos" => 187 }, { "klass" => "AST::SimpleObjectEntry", "key_name" => "value", "value" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 196, "end_pos" => 198 }, "start_pos" => 189, "end_pos" => 198 }], "start_pos" => 180, "end_pos" => 200 }], "start_pos" => 157, "end_pos" => 201 }, "start_pos" => 150, "end_pos" => 201 }, { "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::Bind", "lhs" => { "klass" => "AST::IdLookup", "value" => "arr", "start_pos" => 215, "end_pos" => 218 }, "function" => { "klass" => "AST::IdLookup", "value" => "group_by", "start_pos" => 220, "end_pos" => 228 }, "args" => [{ "klass" => "AST::SimpleString", "value" => "id", "start_pos" => 229, "end_pos" => 233 }] }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 203, "end_pos" => 210 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 211, "end_pos" => 214 }, "start_pos" => 210, "end_pos" => 214 }, "start_pos" => 214, "end_pos" => nil }])
  #   end
  #   it "2022-09-08 00:07:39 -0400" do
  #     ast = parse('if 10 == 11
  #   console.log "true"
  # else if false

  # else
  #   console.log "false"
  # end
  # ')
  #     expect(ast).to eq([{ "klass" => "AST::If", "cond" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::Int", "value" => 10, "start_pos" => 3, "end_pos" => 5 }, "type" => :==, "rhs" => { "klass" => "AST::Int", "value" => 11, "start_pos" => 9, "end_pos" => 11 }, "start_pos" => 3, "end_pos" => 11 }, "pass" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::SimpleString", "value" => "true", "start_pos" => 26, "end_pos" => 32 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 14, "end_pos" => 21 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 22, "end_pos" => 25 }, "start_pos" => 21, "end_pos" => 25 }, "start_pos" => 25, "end_pos" => 32 }], "branches" => [{ "klass" => "AST::ElseIf", "cond" => { "klass" => "AST::Bool", "value" => false, "start_pos" => 41, "end_pos" => 46 }, "body" => [], "start_pos" => 33, "end_pos" => nil }, { "klass" => "AST::Else", "body" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::SimpleString", "value" => "false", "start_pos" => 67, "end_pos" => 74 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 55, "end_pos" => 62 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 63, "end_pos" => 66 }, "start_pos" => 62, "end_pos" => 66 }, "start_pos" => 66, "end_pos" => 74 }], "start_pos" => 48, "end_pos" => 74 }], "start_pos" => 0, "end_pos" => 78 }])
  #   end
  #   it "2022-09-08 14:44:17 -0400" do
  #     ast = parse("class Token
  #   function constructor(@raw_token, @type, @value = null, @captures = null)
  # end

  # class Lexer
  #   function constructor(@str)

  #   function tokenize

  #   end
  # end")
  #     expect(ast).to eq([{ "klass" => "AST::Class", "name" => "Token", "parent_class" => nil, "entries" => [{ "klass" => "AST::ShortHandConstructor", "args" => [{ "klass" => "AST::SimpleConstructorArg", "name" => "raw_token", "start_pos" => 35, "end_pos" => 45 }, { "klass" => "AST::SimpleConstructorArg", "name" => "type", "start_pos" => 47, "end_pos" => 52 }, { "klass" => "AST::DefaultConstructorArg", "name" => "value", "expr" => { "klass" => "AST::Null", "start_pos" => 63, "end_pos" => 67 }, "start_pos" => 54, "end_pos" => 67 }, { "klass" => "AST::DefaultConstructorArg", "name" => "captures", "expr" => { "klass" => "AST::Null", "start_pos" => 81, "end_pos" => 85 }, "start_pos" => 69, "end_pos" => 85 }], "start_pos" => 14, "end_pos" => 86 }], "start_pos" => 0, "end_pos" => 90 }, { "klass" => "AST::Class", "name" => "Lexer", "parent_class" => nil, "entries" => [{ "klass" => "AST::ShortHandConstructor", "args" => [{ "klass" => "AST::SimpleConstructorArg", "name" => "str", "start_pos" => 127, "end_pos" => 131 }], "start_pos" => 106, "end_pos" => 132 }, { "klass" => "AST::MultilineDefWithoutArgs", "name" => "tokenize", "body" => [], "start_pos" => 136, "end_pos" => 160 }], "start_pos" => 92, "end_pos" => 164 }])
  #   end
  #   it "2022-09-08 14:46:12 -0400" do
  #     ast = parse("class Parser
  #   function constructor(@tokens, @program_string, @pos)

  #   static function from(that)
  #     new this(that.tokens, that.program_string, that.pos)
  #   end
  # end")
  #     expect(ast).to eq([{ "klass" => "AST::Class", "name" => "Parser", "parent_class" => nil, "entries" => [{ "klass" => "AST::ShortHandConstructor", "args" => [{ "klass" => "AST::SimpleConstructorArg", "name" => "tokens", "start_pos" => 36, "end_pos" => 43 }, { "klass" => "AST::SimpleConstructorArg", "name" => "program_string", "start_pos" => 45, "end_pos" => 60 }, { "klass" => "AST::SimpleConstructorArg", "name" => "pos", "start_pos" => 62, "end_pos" => 66 }], "start_pos" => 15, "end_pos" => 67 }, { "klass" => "AST::StaticMethod", "name" => "from", "args" => { "klass" => "AST::SimpleFnArgs", "value" => [{ "klass" => "AST::SimpleArg", "name" => "that", "start_pos" => 92, "end_pos" => 96 }], "start_pos" => 91, "end_pos" => 97 }, "body" => [{ "klass" => "AST::Return", "value" => { "klass" => "AST::New", "class_expr" => { "klass" => "AST::This", "value" => nil, "start_pos" => 106, "end_pos" => 110 }, "args" => [{ "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "that", "start_pos" => 111, "end_pos" => 115 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "tokens", "start_pos" => 116, "end_pos" => 122 }, "start_pos" => 115, "end_pos" => 122 }, { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "that", "start_pos" => 124, "end_pos" => 128 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "program_string", "start_pos" => 129, "end_pos" => 143 }, "start_pos" => 128, "end_pos" => 143 }, { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "that", "start_pos" => 145, "end_pos" => 149 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "pos", "start_pos" => 150, "end_pos" => 153 }, "start_pos" => 149, "end_pos" => 153 }], "start_pos" => 102, "end_pos" => 154 }, "start_pos" => 102, "end_pos" => 154 }], "start_pos" => 71, "end_pos" => 160 }], "start_pos" => 0, "end_pos" => 164 }])
  #   end
  #   it "2022-09-08 15:58:22 -0400" do
  #     ast = parse('case
  # when true && false
  #   console.log("true")
  # when false || true && false
  #   console.log("false")
  # else
  #   console.log("else")
  # end')
  #     expect(ast).to eq([{ "klass" => "AST::EmptyCaseExpr", "cases" => [{ "klass" => "AST::SimpleWhen", "expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::Bool", "value" => true, "start_pos" => 10, "end_pos" => 14 }, "type" => :"&&", "rhs" => { "klass" => "AST::Bool", "value" => false, "start_pos" => 18, "end_pos" => 23 }, "start_pos" => 10, "end_pos" => 23 }, "body" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::SimpleString", "value" => "true", "start_pos" => 38, "end_pos" => 44 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 26, "end_pos" => 33 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 34, "end_pos" => 37 }, "start_pos" => 33, "end_pos" => 37 }, "start_pos" => 37, "end_pos" => 45 }], "start_pos" => 5, "end_pos" => 45 }, { "klass" => "AST::SimpleWhen", "expr" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::Bool", "value" => false, "start_pos" => 51, "end_pos" => 56 }, "type" => :"||", "rhs" => { "klass" => "AST::Op", "lhs" => { "klass" => "AST::Bool", "value" => true, "start_pos" => 60, "end_pos" => 64 }, "type" => :"&&", "rhs" => { "klass" => "AST::Bool", "value" => false, "start_pos" => 68, "end_pos" => 73 }, "start_pos" => 60, "end_pos" => 73 }, "start_pos" => 51, "end_pos" => 73 }, "body" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::SimpleString", "value" => "false", "start_pos" => 88, "end_pos" => 95 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 76, "end_pos" => 83 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 84, "end_pos" => 87 }, "start_pos" => 83, "end_pos" => 87 }, "start_pos" => 87, "end_pos" => 96 }], "start_pos" => 46, "end_pos" => 96 }, { "klass" => "AST::CaseElse", "body" => [{ "klass" => "AST::FnCall", "args" => [{ "klass" => "AST::SimpleString", "value" => "else", "start_pos" => 116, "end_pos" => 122 }], "expr" => { "klass" => "AST::Dot", "lhs" => { "klass" => "AST::IdLookup", "value" => "console", "start_pos" => 104, "end_pos" => 111 }, "type" => ".", "rhs" => { "klass" => "AST::IdLookup", "value" => "log", "start_pos" => 112, "end_pos" => 115 }, "start_pos" => 111, "end_pos" => 115 }, "start_pos" => 115, "end_pos" => 123 }], "start_pos" => 97, "end_pos" => 123 }], "start_pos" => 0, "end_pos" => 127 }])
  #   end
  #   it "2022-09-08 18:16:12 -0400" do
  #     ast = parse('!true')
  #     expect(ast).to eq([{"klass"=>"AST::Not", "expr"=>{"klass"=>"AST::Bool", "value"=>true, "start_pos"=>1, "end_pos"=>5}, "start_pos"=>0, "end_pos"=>5}])
  #   end
end
