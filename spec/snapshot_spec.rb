require "ast"

def parse(str)
  tokens = Lexer::tokenize(str.strip)
  Parser.reset_unused_count!
  ast = Parser.new(tokens, str).parse!
  ast.map(&:to_h)
end

context "snapshot" do
  it "2022-02-16 10:34:57 -0500" do
    ast = parse("a := [3, 3]
b := nil
print(a&.size, b&.size)")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "a", :expr => [{ :value => 3 }, { :value => 3 }] }, { :name => "b", :expr => { :value => nil } }, { :args => [{ :args => [{ :args => [], :body => [{ :value => { :args => [], :expr => { :lhs_expr => { :value => "a" }, :property => "size" } } }] }], :expr => { :lhs_expr => { :value => "a" }, :property => "__and__" } }, { :args => [{ :args => [], :body => [{ :value => { :args => [], :expr => { :lhs_expr => { :value => "b" }, :property => "size" } } }] }], :expr => { :lhs_expr => { :value => "b" }, :property => "__and__" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:35:05 -0500" do
    ast = parse('<div>{arr.map #{<Child text={%} />}}</div>')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => { :value => "div" }, :attributes => { :value => [], :splats => [] }, :children => [{ :args => [{ :args => ["__ANON_SHORT_ID"], :body => [{ :value => { :args => [{ :value => [[{ :value => "text" }, { :value => "__ANON_SHORT_ID" }]], :splats => [] }], :expr => { :lhs_expr => { :value => "Child" }, :property => "new" } } }] }], :expr => { :lhs_expr => { :value => "arr" }, :property => "map" } }] }])
  end
  it "2022-02-16 10:35:15 -0500" do
    ast = parse("<Child margin={i < l.last_index} />")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :args => [{ :value => [[{ :value => "margin" }, { :args => [{ :args => [], :expr => { :lhs_expr => { :value => "l" }, :property => "last_index" } }], :expr => { :lhs_expr => { :value => "i" }, :property => "__lt__" } }]], :splats => [] }], :expr => { :lhs_expr => { :value => "Child" }, :property => "new" } }])
  end
  it "2022-02-16 10:35:27 -0500" do
    ast = parse("<Child margin={i < l.last_index} other_prop={3} />")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :args => [{ :value => [[{ :value => "margin" }, { :args => [{ :args => [], :expr => { :lhs_expr => { :value => "l" }, :property => "last_index" } }], :expr => { :lhs_expr => { :value => "i" }, :property => "__lt__" } }], [{ :value => "other_prop" }, { :value => 3 }]], :splats => [] }], :expr => { :lhs_expr => { :value => "Child" }, :property => "new" } }])
  end
  it "2022-02-16 10:35:41 -0500" do
    ast = parse('arr := [{ a: 5 }]
print(arr.find #{ %[:a] == 3 }&[:a])')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "arr", :expr => [{ :value => [[{ :value => "a" }, { :value => 5 }]], :splats => [] }] }, { :args => [{ :args => [{ :args => [], :body => [{ :value => { :args => [{ :value => "a" }], :expr => { :lhs_expr => { :args => [{ :args => ["__ANON_SHORT_ID"], :body => [{ :value => { :args => [{ :value => 3 }], :expr => { :lhs_expr => { :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "__ANON_SHORT_ID" }, :property => "__lookup__" } }, :property => "__eq__" } } }] }], :expr => { :lhs_expr => { :value => "arr" }, :property => "find" } }, :property => "__lookup__" } } }] }], :expr => { :lhs_expr => { :args => [{ :args => ["__ANON_SHORT_ID"], :body => [{ :value => { :args => [{ :value => 3 }], :expr => { :lhs_expr => { :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "__ANON_SHORT_ID" }, :property => "__lookup__" } }, :property => "__eq__" } } }] }], :expr => { :lhs_expr => { :value => "arr" }, :property => "find" } }, :property => "__and__" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:35:48 -0500" do
    ast = parse("console.log 1.to_js, 2.to_js")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :args => [{ :args => [], :expr => { :lhs_expr => { :value => 1 }, :property => "to_js" } }, { :args => [], :expr => { :lhs_expr => { :value => 2 }, :property => "to_js" } }], :expr => { :lhs_expr => { :value => "console" }, :property => "log" } }])
  end
  it "2022-02-16 10:35:55 -0500" do
    ast = parse("a := if true then 3 end
print(a)")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "a", :expr => { :args => [], :expr => { :args => [], :body => [{ :value => { :value => true }, :pass => [{ :value => { :value => 3 } }], :fail => [] }] } } }, { :args => [{ :value => "a" }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:36:04 -0500" do
    ast = parse("def f
  1 + 3
end
print(f())")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "f", :schema => { :args => [[]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :value => { :args => [{ :value => 3 }], :expr => { :lhs_expr => { :value => 1 }, :property => "__plus__" } } }] } }, { :args => [{ :args => [], :expr => { :value => "f" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:36:12 -0500" do
    ast = parse("def f(a, b)
  a + b
end

print(f(1, 2))")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "f", :schema => { :args => [[{ :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "b" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "a", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "b", :expr => { :args => [{ :value => 1 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :args => [{ :value => "b" }], :expr => { :lhs_expr => { :value => "a" }, :property => "__plus__" } } }] } }, { :args => [{ :args => [{ :value => 1 }, { :value => 2 }], :expr => { :value => "f" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:36:47 -0500" do
    ast = parse("def f
  return 2 if true
end
print(f())")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "f", :schema => { :args => [[]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :value => { :value => true }, :pass => [{ :value => { :value => 2 } }], :fail => [] }] } }, { :args => [{ :args => [], :expr => { :value => "f" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:37:04 -0500" do
    ast = parse('schema User = { id }

def f(User) = 3

print(f({ id: "value" }))')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "User", :expr => { :args => [{ :value => [[{ :value => "id" }, { :args => [{ :value => "id" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :splats => [] }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } } }, { :name => "f", :schema => { :args => [[{ :args => [{ :value => "User" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :value => { :value => 3 } }] } }, { :args => [{ :args => [{ :value => [[{ :value => "id" }, { :value => "value" }]], :splats => [] }], :expr => { :value => "f" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:37:28 -0500" do
    ast = parse("schema User = { id }

def f({ user: User }) = 3

print(f({ user: { id: 3 } }))")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "User", :expr => { :args => [{ :value => [[{ :value => "id" }, { :args => [{ :value => "id" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :splats => [] }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } } }, { :name => "f", :schema => { :args => [[{ :args => [{ :value => [[{ :value => "user" }, { :value => "User" }]], :splats => [] }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "user", :expr => { :args => [{ :value => "user" }], :expr => { :lhs_expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } }, :property => "__lookup__" } } }, { :value => { :value => 3 } }] } }, { :args => [{ :args => [{ :value => [[{ :value => "user" }, { :value => [[{ :value => "id" }, { :value => 3 }]], :splats => [] }]], :splats => [] }], :expr => { :value => "f" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:39:14 -0500" do
    ast = parse('test := case 1
when 1
  "test"
end

print(test)')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "test", :expr => { :expr => { :value => 1 }, :cases => [[{ :args => [{ :value => 1 }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, { :args => ["match_expr"], :body => [{ :value => { :value => "test" } }] }]] } }, { :args => [{ :value => "test" }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:39:22 -0500" do
    ast = parse("schema User = { id }

val := case { id: 4 }
when User({ id })
  id
end

print(val)")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "User", :expr => { :args => [{ :value => [[{ :value => "id" }, { :args => [{ :value => "id" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :splats => [] }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } } }, { :name => "val", :expr => { :expr => { :value => [[{ :value => "id" }, { :value => 4 }]], :splats => [] }, :cases => [[{ :args => [{ :value => "User" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, { :args => ["match_expr"], :body => [{ :name => "id", :expr => { :args => [{ :value => "id" }], :expr => { :lhs_expr => { :value => "match_expr" }, :property => "__lookup__" } } }, { :value => { :value => "id" } }] }]] } }, { :args => [{ :value => "val" }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:39:31 -0500" do
    ast = parse('schema User = { id, email }

User({ id, *user }) := { id: 10, email: "email" }

print(id, user)')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "User", :expr => { :args => [{ :value => [[{ :value => "id" }, { :args => [{ :value => "id" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }], [{ :value => "email" }, { :args => [{ :value => "email" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :splats => [] }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } } }, { :value => { :args => [{ :value => [[{ :value => "id" }, { :value => 10 }], [{ :value => "email" }, { :value => "email" }]], :splats => [] }], :expr => { :lhs_expr => { :value => "User" }, :property => "valid_q" } }, :pass => [{ :name => "__VALUE", :expr => { :value => [[{ :value => "id" }, { :value => 10 }], [{ :value => "email" }, { :value => "email" }]], :splats => [] } }, { :name => "id", :expr => { :args => [{ :value => "id" }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "user", :expr => { :value => "__VALUE" } }], :fail => [{ :expr => { :value => "Match error" } }] }, { :args => [{ :value => "id" }, { :value => "user" }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:40:03 -0500" do
    ast = parse("obj := { *{ a: 3 }, b: 10 }

print(obj)")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "obj", :expr => { :value => [[{ :value => "b" }, { :value => 10 }]], :splats => [{ :value => [[{ :value => "splat" }, { :value => [[{ :value => "a" }, { :value => 3 }]], :splats => [] }], [{ :value => "index" }, { :value => 0 }]], :splats => [] }] } }, { :args => [{ :value => "obj" }], :expr => { :value => "print" } }])
  end
  it "2022-03-12 10:40:02 -0500" do
    ast = parse("mutl_11 := item => item * 11

print(mutl_11(10))")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "mutl_11", :expr => { :args => ["item"], :body => [{ :value => { :args => [{ :value => 11 }], :expr => { :lhs_expr => { :value => "item" }, :property => "__mult__" } } }] } }, { :args => [{ :args => [{ :value => 10 }], :expr => { :value => "mutl_11" } }], :expr => { :value => "print" } }])
  end
  it "2022-03-12 12:18:35 -0500" do
    ast = parse("(a, b) => a * b")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :args => ["a", "b"], :body => [{ :value => { :args => [{ :value => "b" }], :expr => { :lhs_expr => { :value => "a" }, :property => "__mult__" } } }] }])
  end
  it "2022-04-28 23:45:22 -0400" do
    ast = parse("schema Point = [x, y]
Point([x, y]) := [1, 2]
console.log(x, y)")
    expect(ast).to eq([{ :name => "Point", :expr => [{ :name => "x" }, { :name => "y" }] }, { :schema => { :value => "Point" }, :pattern => [{ :value => "x" }, { :value => "y" }], :value => [{ :value => 1 }, { :value => 2 }] }, { :args => [{ :value => "x" }, { :value => "y" }], :expr => { :lhs_expr => { :value => "console" }, :property => "log" } }])
  end
  it "2022-04-28 23:46:48 -0400" do
    ast = parse("d := <h1></h1>")
    expect(ast).to eq([{ :name => "d", :expr => { :name => { :value => "h1" }, :attributes => { :value => [], :splats => [] }, :children => [] } }])
  end
  it "2022-04-28 23:47:17 -0400" do
    ast = parse("obj.add 1, 3")
    expect(ast).to eq([{ :args => [{ :value => 1 }, { :value => 3 }], :expr => { :lhs_expr => { :value => "obj" }, :property => "add" } }])
  end
  it "2022-04-28 23:48:02 -0400" do
    ast = parse('console.log("  ".trim)')
    expect(ast).to eq([{ :args => [{ :args => [], :expr => { :lhs_expr => { :value => "  " }, :property => "trim" } }], :expr => { :lhs_expr => { :value => "console" }, :property => "log" } }])
  end
  it "2022-04-28 23:56:57 -0400" do
    ast = parse('a := 1

console.log "oh #{a} #{a + 1}"')
    expect(ast).to eq([{ :name => "a", :expr => { :value => 1 } }, { :args => [{ :lhs => { :lhs => { :lhs => { :lhs => { :value => "oh " }, :rhs => { :value => "a" } }, :rhs => { :value => " " } }, :rhs => { :lhs => { :value => "a" }, :rhs => { :value => 1 } } }, :rhs => { :value => "" } }], :expr => { :lhs_expr => { :value => "console" }, :property => "log" } }])
  end
  it "2022-04-28 23:57:42 -0400" do
    ast = parse('v := {
  [1]: "this is ON",
  [false]: "off",
  sym: 3,
  ["str"]: 3
}
console.log v')
    expect(ast).to eq([{ :name => "v", :expr => { :value => [[{ :value => 1 }, { :value => "this is ON" }], [{ :value => false }, { :value => "off" }], [{ :value => "sym" }, { :value => 3 }], [{ :value => "str" }, { :value => 3 }]], :splats => [] } }, { :args => [{ :value => "v" }], :expr => { :lhs_expr => { :value => "console" }, :property => "log" } }])
  end
  it "2022-04-29 00:01:05 -0400" do
    ast = parse("[{ b: { a } }] := [{ b: { a: 1 } }]
console.log a")
    expect(ast).to eq([{ :schema => [{ :value => [[{ :value => "b" }, { :value => [[{ :value => "a" }, { :name => "a" }]], :splats => [] }]], :splats => [] }], :pattern => [{ :value => [[{ :value => "b" }, { :value => [[{ :value => "a" }, { :value => "a" }]], :splats => [] }]], :splats => [] }], :value => [{ :value => [[{ :value => "b" }, { :value => [[{ :value => "a" }, { :value => 1 }]], :splats => [] }]], :splats => [] }] }, { :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "console" }, :property => "log" } }])
  end
  it "2022-04-29 00:01:22 -0400" do
    ast = parse("[x, y] := [1, 2]
console.log x, y")
    expect(ast).to eq([{ :schema => [{ :name => "x" }, { :name => "y" }], :pattern => [{ :value => "x" }, { :value => "y" }], :value => [{ :value => 1 }, { :value => 2 }] }, { :args => [{ :value => "x" }, { :value => "y" }], :expr => { :lhs_expr => { :value => "console" }, :property => "log" } }])
  end
  it "2022-04-29 00:07:14 -0400" do
    ast = parse("{ a } := { a: 3 }
console.log a")
    expect(ast).to eq([{ :schema => { :value => [[{ :value => "a" }, { :name => "a" }]], :splats => [] }, :pattern => { :value => [[{ :value => "a" }, { :value => "a" }]], :splats => [] }, :value => { :value => [[{ :value => "a" }, { :value => 3 }]], :splats => [] } }, { :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "console" }, :property => "log" } }])
  end
  it "2022-04-29 00:16:53 -0400" do
    ast = parse('a := "#{if true then :result end}"
console.log a')
    expect(ast).to eq([{ :name => "a", :expr => { :lhs => { :lhs => { :value => "" }, :rhs => { :args => [], :expr => { :lhs_expr => { :args => [], :expr => { :args => [], :body => [{ :value => { :value => true }, :pass => [{ :value => { :value => "result" } }], :fail => [] }] } }, :property => "toString" } } }, :rhs => { :value => "" } } }, { :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "console" }, :property => "log" } }])
  end
  it "2022-04-29 00:17:36 -0400" do
    ast = parse('a := "string #{"inside"} outside"
console.log a')
    expect(ast).to eq([{ :name => "a", :expr => { :lhs => { :lhs => { :value => "string " }, :rhs => { :args => [], :expr => { :lhs_expr => { :value => "inside" }, :property => "toString" } } }, :rhs => { :value => " outside" } } }, { :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "console" }, :property => "log" } }])
  end
  it "2022-04-29 00:19:14 -0400" do
    ast = parse("console.log(<div>{[1, 2].map do |x| x * 3 end}</div>)")
    expect(ast).to eq([{ :args => [{ :name => { :value => "div" }, :attributes => { :value => [], :splats => [] }, :children => [{ :args => [{ :args => ["x"], :body => [{ :value => { :lhs => { :value => "x" }, :rhs => { :value => 3 } } }] }], :expr => { :lhs_expr => [{ :value => 1 }, { :value => 2 }], :property => "map" } }] }], :expr => { :lhs_expr => { :value => "console" }, :property => "log" } }])
  end
  it "2022-04-29 00:19:42 -0400" do
    ast = parse("a := (false == true) || [1, 2].includes(2)
console.log a")
    expect(ast).to eq([{ :name => "a", :expr => { :lhs => { :value => { :lhs => { :value => false }, :rhs => { :value => true } } }, :rhs => { :args => [{ :value => 2 }], :expr => { :lhs_expr => [{ :value => 1 }, { :value => 2 }], :property => "includes" } } } }, { :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "console" }, :property => "log" } }])
  end
  it "2022-04-29 00:20:20 -0400" do
    ast = parse("a := false == true || [1, 2]
console.log(a)")
    expect(ast).to eq([{ :name => "a", :expr => { :lhs => { :lhs => { :value => false }, :rhs => { :value => true } }, :rhs => [{ :value => 1 }, { :value => 2 }] } }, { :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "console" }, :property => "log" } }])
  end
  it "2022-05-03 21:40:02 -0400" do
    ast = parse('def f(3) = "oh"
def f(a) = a
def f(a, b) = a + b

console.log f(3), f(10), f(13, 17)')
    expect(ast).to eq([{ :name => "f", :schema => [{ :value => 3 }], :expr => { :args => ["__VALUE"], :body => [{ :value => { :value => "oh" } }] } }, { :name => "f", :schema => [{ :name => "a" }], :expr => { :args => ["__VALUE"], :body => [{ :value => { :value => "a" } }] } }, { :name => "f", :schema => [{ :name => "a" }, { :name => "b" }], :expr => { :args => ["__VALUE"], :body => [{ :value => { :lhs => { :value => "a" }, :rhs => { :value => "b" } } }] } }, { :args => [{ :args => [{ :value => 3 }], :expr => { :value => "f" } }, { :args => [{ :value => 10 }], :expr => { :value => "f" } }, { :args => [{ :value => 13 }, { :value => 17 }], :expr => { :value => "f" } }], :expr => { :lhs_expr => { :value => "console" }, :property => "log" } }])
  end
  it "2022-05-09 20:02:42 -0400" do
    ast = parse("<Child margin={i < l.length - 1} />")
    expect(ast).to eq([{ :name => "Child", :attributes => { :value => [[{ :value => "margin" }, { :lhs => { :lhs => { :value => "i" }, :rhs => { :lhs_expr => { :value => "l" }, :property => "length" } }, :rhs => { :value => 1 } }]], :splats => {} }, :children => [] }])
  end
end
