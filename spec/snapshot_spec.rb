require "ast"

def parse(str)
  tokens = Lexer::tokenize(str.strip)
  Parser.reset_unused_count!
  ast = Parser.new(tokens, str).parse!
  ast.map(&:to_h)
end

context "snapshot" do
  it "2022-02-16 10:32:03 -0500" do
    ast = parse("schema Point = [x, y]
Point([x, y]) := [1, 2]
print(x, y)")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "Point", :expr => { :args => [[{ :args => [{ :value => "x" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "y" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } } }, { :value => { :args => [[{ :value => 1 }, { :value => 2 }]], :expr => { :lhs_expr => { :value => "Point" }, :property => "valid_q" } }, :pass => [{ :name => "__VALUE", :expr => [{ :value => 1 }, { :value => 2 }] }, { :name => "x", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "y", :expr => { :args => [{ :value => 1 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }], :fail => [{ :expr => { :value => "Match error" } }] }, { :args => [{ :value => "x" }, { :value => "y" }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:32:16 -0500" do
    ast = parse("d := <h1></h1>")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "d", :expr => { :name => { :value => "h1" }, :attributes => { :value => [], :splats => [] }, :children => [] } }])
  end
  it "2022-02-16 10:32:22 -0500" do
    ast = parse("val := nil
print(val.nil?)")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "val", :expr => { :value => nil } }, { :args => [{ :args => [], :expr => { :lhs_expr => { :value => "val" }, :property => "nil?" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:32:36 -0500" do
    ast = parse("obj.add 1, 3")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :args => [{ :value => 1 }, { :value => 3 }], :expr => { :lhs_expr => { :value => "obj" }, :property => "add" } }])
  end
  it "2022-02-16 10:32:51 -0500" do
    ast = parse("num := 5.3
inspect.print num.to_i")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "num", :expr => { :value => 5.3 } }, { :args => [{ :args => [], :expr => { :lhs_expr => { :value => "num" }, :property => "to_i" } }], :expr => { :lhs_expr => { :value => "inspect" }, :property => "print" } }])
  end
  it "2022-02-16 10:33:00 -0500" do
    ast = parse('print("  ".trim)')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :args => [{ :args => [], :expr => { :lhs_expr => { :value => "  " }, :property => "trim" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:33:09 -0500" do
    ast = parse('a := 1

print("oh #{a} #{a + 1}")')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "a", :expr => { :value => 1 } }, { :args => [{ :args => [{ :value => "" }], :expr => { :lhs_expr => { :args => [{ :args => [], :expr => { :lhs_expr => { :args => [{ :value => 1 }], :expr => { :lhs_expr => { :value => "a" }, :property => "__plus__" } }, :property => "to_s" } }], :expr => { :lhs_expr => { :args => [{ :value => " " }], :expr => { :lhs_expr => { :args => [{ :args => [], :expr => { :lhs_expr => { :value => "a" }, :property => "to_s" } }], :expr => { :lhs_expr => { :value => "oh " }, :property => "__plus__" } }, :property => "__plus__" } }, :property => "__plus__" } }, :property => "__plus__" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:33:17 -0500" do
    ast = parse('v := {
  [1]: "this is ON",
  [false]: "off",
  sym: 3,
  ["str"]: 3
}
print(v)')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "v", :expr => { :value => [[{ :value => 1 }, { :value => "this is ON" }], [{ :value => false }, { :value => "off" }], [{ :value => "sym" }, { :value => 3 }], [{ :value => "str" }, { :value => 3 }]], :splats => [] } }, { :args => [{ :value => "v" }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:33:25 -0500" do
    ast = parse("[{ b: { a } }] := [{ b: { a: 1 } }]
print(a)")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :value => { :args => [[{ :value => [[{ :value => "b" }, { :value => [[{ :value => "a" }, { :value => 1 }]], :splats => [] }]], :splats => [] }]], :expr => { :lhs_expr => { :args => [[{ :value => [[{ :value => "b" }, { :value => [[{ :value => "a" }, { :value => "a" }]], :splats => [] }]], :splats => [] }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :property => "valid_q" } }, :pass => [{ :name => "__VALUE", :expr => [{ :value => [[{ :value => "b" }, { :value => [[{ :value => "a" }, { :value => 1 }]], :splats => [] }]], :splats => [] }] }, { :name => "a", :expr => { :args => [{ :value => "a" }], :expr => { :lhs_expr => { :args => [{ :value => "b" }], :expr => { :lhs_expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } }, :property => "__lookup__" } }, :property => "__lookup__" } } }], :fail => [{ :expr => { :value => "Match error" } }] }, { :args => [{ :value => "a" }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:33:33 -0500" do
    ast = parse("[x, y] := [1, 2]
print(x, y)")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :value => { :args => [[{ :value => 1 }, { :value => 2 }]], :expr => { :lhs_expr => { :args => [[{ :value => "x" }, { :value => "y" }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :property => "valid_q" } }, :pass => [{ :name => "__VALUE", :expr => [{ :value => 1 }, { :value => 2 }] }, { :name => "x", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "y", :expr => { :args => [{ :value => 1 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }], :fail => [{ :expr => { :value => "Match error" } }] }, { :args => [{ :value => "x" }, { :value => "y" }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:33:38 -0500" do
    ast = parse("{ a } := { a: 3 }
print(a)")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :value => { :args => [{ :value => [[{ :value => "a" }, { :value => 3 }]], :splats => [] }], :expr => { :lhs_expr => { :args => [{ :value => [[{ :value => "a" }, { :value => "a" }]], :splats => [] }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :property => "valid_q" } }, :pass => [{ :name => "__VALUE", :expr => { :value => [[{ :value => "a" }, { :value => 3 }]], :splats => [] } }, { :name => "a", :expr => { :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }], :fail => [{ :expr => { :value => "Match error" } }] }, { :args => [{ :value => "a" }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:33:56 -0500" do
    ast = parse('a := "#{if true then :result end}"
print(a)')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "a", :expr => { :args => [{ :value => "" }], :expr => { :lhs_expr => { :args => [{ :args => [], :expr => { :lhs_expr => { :args => [], :expr => { :args => [], :body => [{ :value => { :value => true }, :pass => [{ :value => { :value => "result" } }], :fail => [] }] } }, :property => "to_s" } }], :expr => { :lhs_expr => { :value => "" }, :property => "__plus__" } }, :property => "__plus__" } } }, { :args => [{ :value => "a" }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:34:02 -0500" do
    ast = parse('a := "string #{"inside"} outside"
print(a)')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "a", :expr => { :args => [{ :value => " outside" }], :expr => { :lhs_expr => { :args => [{ :args => [], :expr => { :lhs_expr => { :value => "inside" }, :property => "to_s" } }], :expr => { :lhs_expr => { :value => "string " }, :property => "__plus__" } }, :property => "__plus__" } } }, { :args => [{ :value => "a" }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:34:32 -0500" do
    ast = parse("console.log(<div>{[1, 2].map do |x| x * 3 end}</div>)")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :args => [{ :name => { :value => "div" }, :attributes => { :value => [], :splats => [] }, :children => [{ :args => [{ :args => ["x"], :body => [{ :value => { :args => [{ :value => 3 }], :expr => { :lhs_expr => { :value => "x" }, :property => "__mult__" } } }] }], :expr => { :lhs_expr => [{ :value => 1 }, { :value => 2 }], :property => "map" } }] }], :expr => { :lhs_expr => { :value => "console" }, :property => "log" } }])
  end
  it "2022-02-16 10:34:40 -0500" do
    ast = parse("a := (false == true) || [1, 2].has?(2)
print(a)")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "a", :expr => { :args => [{ :args => [{ :value => 2 }], :expr => { :lhs_expr => [{ :value => 1 }, { :value => 2 }], :property => "has?" } }], :expr => { :lhs_expr => { :value => { :args => [{ :value => true }], :expr => { :lhs_expr => { :value => false }, :property => "__eq__" } } }, :property => "__or__" } } }, { :args => [{ :value => "a" }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:34:46 -0500" do
    ast = parse("a := false == true || [1, 2]
print(a)")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "a", :expr => { :args => [[{ :value => 1 }, { :value => 2 }]], :expr => { :lhs_expr => { :args => [{ :value => true }], :expr => { :lhs_expr => { :value => false }, :property => "__eq__" } }, :property => "__or__" } } }, { :args => [{ :value => "a" }], :expr => { :value => "print" } }])
  end
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
  it "2022-02-16 10:36:29 -0500" do
    ast = parse("def f(a, b) = a + b

print(f(1, 2))")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "f", :schema => { :args => [[{ :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "b" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "a", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "b", :expr => { :args => [{ :value => 1 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :args => [{ :value => "b" }], :expr => { :lhs_expr => { :value => "a" }, :property => "__plus__" } } }] } }, { :args => [{ :args => [{ :value => 1 }, { :value => 2 }], :expr => { :value => "f" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:36:37 -0500" do
    ast = parse("class Test
  def f({ b }) = b
end

print(Test.new.f {b: 3})")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "Test", :super_class => nil, :methods => [{ :name => "f", :schema => { :args => [[{ :args => [{ :value => [[{ :value => "b" }, { :args => [{ :value => "b" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :splats => [] }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "b", :expr => { :args => [{ :value => "b" }], :expr => { :lhs_expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } }, :property => "__lookup__" } } }, { :value => { :lhs => { :value => { :name => "b" } }, :rhs => { :args => [], :expr => { :name => "b" } } } }] } }] }, { :args => [{ :args => [{ :value => [[{ :value => "b" }, { :value => 3 }]], :splats => [] }], :expr => { :lhs_expr => { :args => [], :expr => { :lhs_expr => { :value => "Test" }, :property => "new" } }, :property => "f" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:36:47 -0500" do
    ast = parse("def f
  return 2 if true
end
print(f())")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "f", :schema => { :args => [[]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :value => { :value => true }, :pass => [{ :value => { :value => 2 } }], :fail => [] }] } }, { :args => [{ :args => [], :expr => { :value => "f" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:36:54 -0500" do
    ast = parse('def f(3) = "oh"
def f(a) = a
def f(a, b) = a + b

print(f(3), f(5), f(3, 5))')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "f", :schema => { :args => [[{ :args => [{ :value => 3 }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :value => { :value => "oh" } }] } }, { :name => "f", :schema => { :args => [[{ :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "a", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :value => "a" } }] } }, { :name => "f", :schema => { :args => [[{ :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "b" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "a", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "b", :expr => { :args => [{ :value => 1 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :args => [{ :value => "b" }], :expr => { :lhs_expr => { :value => "a" }, :property => "__plus__" } } }] } }, { :args => [{ :args => [{ :value => 3 }], :expr => { :value => "f" } }, { :args => [{ :value => 5 }], :expr => { :value => "f" } }, { :args => [{ :value => 3 }, { :value => 5 }], :expr => { :value => "f" } }], :expr => { :value => "print" } }])
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
  it "2022-02-16 10:37:55 -0500" do
    File.write("rspec_child.pea", "export class Child < Element
      def style(_, is_on, _) = \"cursor: pointer;\"
      def view(_, _, _)
        <div>child tests!</div>
      end
    end
    ")
    ast = parse('import { Child } from "./rspec_child"

class Main < Element
  def style(_, is_on, _) = "cursor: pointer;"
  def view(_, _, _)
    <div>
      <Child />
    </div>
  end
end')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "e1808113a2c1ccc081859f92fe31494c177c71bc", :expr => { :args => [], :expr => { :args => [], :body => [{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "Child", :super_class => "Element", :methods => [{ :name => "style", :schema => { :args => [[{ :args => [{ :value => "_0" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "is_on" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "_1" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "_0", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "is_on", :expr => { :args => [{ :value => 1 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "_1", :expr => { :args => [{ :value => 2 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :value => "cursor: pointer;" } }] } }, { :name => "view", :schema => { :args => [[{ :args => [{ :value => "_2" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "_3" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "_4" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "_2", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "_3", :expr => { :args => [{ :value => 1 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "_4", :expr => { :args => [{ :value => 2 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :name => { :value => "div" }, :attributes => { :value => [], :splats => [] }, :children => [{ :value => { :value => "child tests!" } }] } }] } }] }, { :args => [{ :value => "Child" }, { :value => "Child" }], :expr => { :lhs_expr => { :value => "pea_module" }, :property => "__unsafe_insert__" } }, { :value => { :value => "pea_module" } }] } } }, { :value => { :args => [{ :value => "e1808113a2c1ccc081859f92fe31494c177c71bc" }], :expr => { :lhs_expr => { :args => [{ :value => [[{ :value => "Child" }, { :args => [{ :value => "Child" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :splats => [] }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :property => "valid_q" } }, :pass => [{ :name => "__VALUE", :expr => { :value => "e1808113a2c1ccc081859f92fe31494c177c71bc" } }, { :name => "Child", :expr => { :args => [{ :value => "Child" }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }], :fail => [{ :expr => { :value => "Match error" } }] }, { :name => "Main", :super_class => "Element", :methods => [{ :name => "style", :schema => { :args => [[{ :args => [{ :value => "_5" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "is_on" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "_6" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "_5", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "is_on", :expr => { :args => [{ :value => 1 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "_6", :expr => { :args => [{ :value => 2 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :value => "cursor: pointer;" } }] } }, { :name => "view", :schema => { :args => [[{ :args => [{ :value => "_7" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "_8" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "_9" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "_7", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "_8", :expr => { :args => [{ :value => 1 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "_9", :expr => { :args => [{ :value => 2 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :name => { :value => "div" }, :attributes => { :value => [], :splats => [] }, :children => [{ :args => [{ :value => [], :splats => [] }], :expr => { :lhs_expr => { :value => "Child" }, :property => "new" } }] } }] } }] }])
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
  it "2022-02-16 10:40:13 -0500" do
    ast = parse("class Test
  def a = 3
  def get_arg(a) = a
  def get_method = a
end

print(
  Test.new.get_arg(50),
  Test.new.get_method
)")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "Test", :super_class => nil, :methods => [{ :name => "a", :schema => { :args => [[]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :value => { :value => 3 } }] } }, { :name => "get_arg", :schema => { :args => [[{ :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "a", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :lhs => { :value => { :name => "a" } }, :rhs => { :args => [], :expr => { :name => "a" } } } }] } }, { :name => "get_method", :schema => { :args => [[]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :value => { :lhs => { :value => { :name => "a" } }, :rhs => { :args => [], :expr => { :name => "a" } } } }] } }] }, { :args => [{ :args => [{ :value => 50 }], :expr => { :lhs_expr => { :args => [], :expr => { :lhs_expr => { :value => "Test" }, :property => "new" } }, :property => "get_arg" } }, { :args => [], :expr => { :lhs_expr => { :args => [], :expr => { :lhs_expr => { :value => "Test" }, :property => "new" } }, :property => "get_method" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:40:25 -0500" do
    ast = parse('class Child < Element
  def init_state = false
  def view(props, state, _)
    <div>
      <button onclick=#{set_state !state}>click me</button>
      {state}
      {props[:hmm]}
    </div>
  end
end

class Main < Element
  def init_state = "wow"
  def view(_, state, _)
    set_timeout(#{set_state "oh"}, 2000)
    <div>
      <Child hmm={state}/>
    </div>
  end
end')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "Child", :super_class => "Element", :methods => [{ :name => "init_state", :schema => { :args => [[]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :value => { :value => false } }] } }, { :name => "view", :schema => { :args => [[{ :args => [{ :value => "props" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "state" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "_0" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "props", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "state", :expr => { :args => [{ :value => 1 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "_0", :expr => { :args => [{ :value => 2 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :name => { :value => "div" }, :attributes => { :value => [], :splats => [] }, :children => [{ :name => { :value => "button" }, :attributes => { :value => [[{ :value => "onclick" }, { :args => ["__ANON_SHORT_ID"], :body => [{ :value => { :args => [{ :args => [], :expr => { :lhs_expr => { :lhs => { :value => { :name => "state" } }, :rhs => { :args => [], :expr => { :name => "state" } } }, :property => "bang" } }], :expr => { :lhs => { :value => { :name => "set_state" } }, :rhs => { :name => "set_state" } } } }] }]], :splats => [] }, :children => [{ :value => { :value => "click me" } }] }, { :lhs => { :value => { :name => "state" } }, :rhs => { :args => [], :expr => { :name => "state" } } }, { :args => [{ :value => "hmm" }], :expr => { :lhs_expr => { :lhs => { :value => { :name => "props" } }, :rhs => { :args => [], :expr => { :name => "props" } } }, :property => "__lookup__" } }] } }] } }] }, { :name => "Main", :super_class => "Element", :methods => [{ :name => "init_state", :schema => { :args => [[]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :value => { :value => "wow" } }] } }, { :name => "view", :schema => { :args => [[{ :args => [{ :value => "_1" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "state" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "_2" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "_1", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "state", :expr => { :args => [{ :value => 1 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "_2", :expr => { :args => [{ :value => 2 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :args => [{ :args => ["__ANON_SHORT_ID"], :body => [{ :value => { :args => [{ :value => "oh" }], :expr => { :lhs => { :value => { :name => "set_state" } }, :rhs => { :name => "set_state" } } } }] }, { :value => 2000 }], :expr => { :lhs => { :value => { :name => "set_timeout" } }, :rhs => { :name => "set_timeout" } } }, { :value => { :name => { :value => "div" }, :attributes => { :value => [], :splats => [] }, :children => [{ :args => [{ :value => [[{ :value => "hmm" }, { :lhs => { :value => { :name => "state" } }, :rhs => { :args => [], :expr => { :name => "state" } } }]], :splats => [] }], :expr => { :lhs_expr => { :value => "Child" }, :property => "new" } }] } }] } }] }])
  end
  it "2022-02-16 10:40:39 -0500" do
    ast = parse('class Test
  def f({ a }) = a
  def f([a]) = a
end

print(Test.new.f([1]), Test.new.f({ a: "oh"}))')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "Test", :super_class => nil, :methods => [{ :name => "f", :schema => { :args => [[{ :args => [{ :value => [[{ :value => "a" }, { :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :splats => [] }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "a", :expr => { :args => [{ :value => "a" }], :expr => { :lhs_expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } }, :property => "__lookup__" } } }, { :value => { :lhs => { :value => { :name => "a" } }, :rhs => { :args => [], :expr => { :name => "a" } } } }] } }, { :name => "f", :schema => { :args => [[{ :args => [[{ :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "a", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } }, :property => "__lookup__" } } }, { :value => { :lhs => { :value => { :name => "a" } }, :rhs => { :args => [], :expr => { :name => "a" } } } }] } }] }, { :args => [{ :args => [[{ :value => 1 }]], :expr => { :lhs_expr => { :args => [], :expr => { :lhs_expr => { :value => "Test" }, :property => "new" } }, :property => "f" } }, { :args => [{ :value => [[{ :value => "a" }, { :value => "oh" }]], :splats => [] }], :expr => { :lhs_expr => { :args => [], :expr => { :lhs_expr => { :value => "Test" }, :property => "new" } }, :property => "f" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:40:47 -0500" do
    ast = parse('class Main < Element
  def style(_, is_on, _) = "
    cursor: pointer;
    background: #{if is_on then "#f00" else "#fff" end};
  "
  def init_state = false
  def text(val) = {
    [true]: "this is ON",
    [false]: "off like off"
  }[val]
  def view(_, is_on, _)
    <div onclick=#{set_state !is_on}>
      {text is_on}
    </div>
  end
end')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "Main", :super_class => "Element", :methods => [{ :name => "style", :schema => { :args => [[{ :args => [{ :value => "_0" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "is_on" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "_1" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "_0", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "is_on", :expr => { :args => [{ :value => 1 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "_1", :expr => { :args => [{ :value => 2 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :args => [{ :value => ";\n  " }], :expr => { :lhs_expr => { :args => [{ :args => [], :expr => { :lhs_expr => { :args => [], :expr => { :args => [], :body => [{ :value => { :lhs => { :value => { :name => "is_on" } }, :rhs => { :args => [], :expr => { :name => "is_on" } } }, :pass => [{ :value => { :value => "#f00" } }], :fail => [{ :value => { :value => "#fff" } }] }] } }, :property => "to_s" } }], :expr => { :lhs_expr => { :value => "\n    cursor: pointer;\n    background: " }, :property => "__plus__" } }, :property => "__plus__" } } }] } }, { :name => "init_state", :schema => { :args => [[]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :value => { :value => false } }] } }, { :name => "text", :schema => { :args => [[{ :args => [{ :value => "val" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "val", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :args => [{ :lhs => { :value => { :name => "val" } }, :rhs => { :args => [], :expr => { :name => "val" } } }], :expr => { :lhs_expr => { :value => [[{ :value => true }, { :value => "this is ON" }], [{ :value => false }, { :value => "off like off" }]], :splats => [] }, :property => "__lookup__" } } }] } }, { :name => "view", :schema => { :args => [[{ :args => [{ :value => "_2" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "is_on" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }, { :args => [{ :value => "_3" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "_2", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "is_on", :expr => { :args => [{ :value => 1 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :name => "_3", :expr => { :args => [{ :value => 2 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :name => { :value => "div" }, :attributes => { :value => [[{ :value => "onclick" }, { :args => ["__ANON_SHORT_ID"], :body => [{ :value => { :args => [{ :args => [], :expr => { :lhs_expr => { :lhs => { :value => { :name => "is_on" } }, :rhs => { :args => [], :expr => { :name => "is_on" } } }, :property => "bang" } }], :expr => { :lhs => { :value => { :name => "set_state" } }, :rhs => { :name => "set_state" } } } }] }]], :splats => [] }, :children => [{ :args => [{ :lhs => { :value => { :name => "is_on" } }, :rhs => { :args => [], :expr => { :name => "is_on" } } }], :expr => { :lhs => { :value => { :name => "text" } }, :rhs => { :name => "text" } } }] } }] } }] }])
  end
  it "2022-02-16 10:41:09 -0500" do
    ast = parse("class Test
  def f(a) = case a
    when {b}
      b
    end
end

print(Test.new.f {b: 3})")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "Test", :super_class => nil, :methods => [{ :name => "f", :schema => { :args => [[{ :args => [{ :value => "a" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "a", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :expr => { :lhs => { :value => { :name => "a" } }, :rhs => { :args => [], :expr => { :name => "a" } } }, :cases => [[{ :args => [{ :value => [[{ :value => "b" }, { :args => [{ :value => "b" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :splats => [] }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, { :args => ["match_expr"], :body => [{ :name => "b", :expr => { :args => [{ :value => "b" }], :expr => { :lhs_expr => { :value => "match_expr" }, :property => "__lookup__" } } }, { :value => { :lhs => { :value => { :name => "b" } }, :rhs => { :args => [], :expr => { :name => "b" } } } }] }]] } }] } }] }, { :args => [{ :args => [{ :value => [[{ :value => "b" }, { :value => 3 }]], :splats => [] }], :expr => { :lhs_expr => { :args => [], :expr => { :lhs_expr => { :value => "Test" }, :property => "new" } }, :property => "f" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:41:18 -0500" do
    ast = parse("class Num
  def init(val)
    @val := val
  end
  def add(other) = @val + other
end

print(Num.new(10).add 10)")
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "Num", :super_class => nil, :methods => [{ :name => "init", :schema => { :args => [[{ :args => [{ :value => "val" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "val", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :lhs => { :name => "val" }, :expr => { :lhs => { :value => { :name => "val" } }, :rhs => { :args => [], :expr => { :name => "val" } } } } }] } }, { :name => "add", :schema => { :args => [[{ :args => [{ :value => "other" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "other", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :args => [{ :lhs => { :value => { :name => "other" } }, :rhs => { :args => [], :expr => { :name => "other" } } }], :expr => { :lhs_expr => { :name => "val" }, :property => "__plus__" } } }] } }] }, { :args => [{ :args => [{ :value => 10 }], :expr => { :lhs_expr => { :args => [{ :value => 10 }], :expr => { :lhs_expr => { :value => "Num" }, :property => "new" } }, :property => "add" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-16 10:41:27 -0500" do
    ast = parse('class BaseNum
  def init(val)
    @val := val
  end
  def to_s = @val.to_s
end

class Num < BaseNum
  def to_s_2 = @to_s() + " oh wow"
end

print(Num.new(3).to_s_2)')
    expect(ast).to eq([{ :name => "pea_module", :expr => { :value => [], :splats => [] } }, { :name => "BaseNum", :super_class => nil, :methods => [{ :name => "init", :schema => { :args => [[{ :args => [{ :value => "val" }], :expr => { :lhs_expr => { :value => "Schema" }, :property => "any" } }]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :name => "val", :expr => { :args => [{ :value => 0 }], :expr => { :lhs_expr => { :value => "__VALUE" }, :property => "__lookup__" } } }, { :value => { :lhs => { :name => "val" }, :expr => { :lhs => { :value => { :name => "val" } }, :rhs => { :args => [], :expr => { :name => "val" } } } } }] } }, { :name => "to_s", :schema => { :args => [[]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :value => { :args => [], :expr => { :lhs_expr => { :name => "val" }, :property => "to_s" } } }] } }] }, { :name => "Num", :super_class => "BaseNum", :methods => [{ :name => "to_s_2", :schema => { :args => [[]], :expr => { :lhs_expr => { :value => "Schema" }, :property => "for" } }, :expr => { :args => ["__VALUE"], :body => [{ :value => { :args => [{ :value => " oh wow" }], :expr => { :lhs_expr => { :args => [], :expr => { :name => "to_s" } }, :property => "__plus__" } } }] } }] }, { :args => [{ :args => [], :expr => { :lhs_expr => { :args => [{ :value => 3 }], :expr => { :lhs_expr => { :value => "Num" }, :property => "new" } }, :property => "to_s_2" } }], :expr => { :value => "print" } }])
  end
  it "2022-02-18 19:52:16 -0500" do
    ast = parse('def create_nums
  while nums.size < 10 with nums := []
    next nums.push 1
  end
end

print(create_nums())')
    expect(ast).to eq([{:name=>"pea_module", :expr=>{:value=>[], :splats=>[]}}, {:name=>"create_nums", :schema=>{:args=>[[]], :expr=>{:lhs_expr=>{:value=>"Schema"}, :property=>"for"}}, :expr=>{:args=>["__VALUE"], :body=>[{:value=>{:value=>{:args=>[{:value=>10}], :expr=>{:lhs_expr=>{:args=>[], :expr=>{:lhs_expr=>{:value=>"nums"}, :property=>"size"}}, :property=>"__lt__"}}, :with_assignment=>{:name=>"nums", :expr=>[]}, :fail=>[{:value=>{:args=>[{:value=>1}], :expr=>{:lhs_expr=>{:value=>"nums"}, :property=>"push"}}}]}}]}}, {:args=>[{:args=>[], :expr=>{:value=>"create_nums"}}], :expr=>{:value=>"print"}}])
  end
  it "2022-03-12 10:40:02 -0500" do
    ast = parse('mutl_11 := item => item * 11

print(mutl_11(10))')
    expect(ast).to eq([{:name=>"pea_module", :expr=>{:value=>[], :splats=>[]}}, {:name=>"mutl_11", :expr=>{:args=>["item"], :body=>[{:value=>{:args=>[{:value=>11}], :expr=>{:lhs_expr=>{:value=>"item"}, :property=>"__mult__"}}}]}}, {:args=>[{:args=>[{:value=>10}], :expr=>{:value=>"mutl_11"}}], :expr=>{:value=>"print"}}])
  end
  it "2022-03-12 12:18:35 -0500" do
    ast = parse('(a, b) => a * b')
    expect(ast).to eq([{:name=>"pea_module", :expr=>{:value=>[], :splats=>[]}}, {:args=>["a", "b"], :body=>[{:value=>{:args=>[{:value=>"b"}], :expr=>{:lhs_expr=>{:value=>"a"}, :property=>"__mult__"}}}]}])
  end
end