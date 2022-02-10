require "lexer"
require "parser"
require "ast"
require "compiler"

def dot(lhs, name)
  AST::dot(lhs, name)
end

def try_eval(name)
  AST::function_call(
    [
      AST::function(
        [],
        [
          AST::return(
            AST::function_call(
              [{ node_type: :str_lit, value: name }],
              AST::identifier_lookup("eval")
            )
          ),
        ]
      ),
    ],
    AST::identifier_lookup("__try")
  )
end

def schema
  AST::identifier_lookup "Schema"
end

def schema_valid(schema, expr)
  AST::function_call(
    [expr],
    dot(schema, "valid_q")
  )
end

def lookup(expr, key)
  key = case key
    when String
      AST::str(key)
    when Integer
      AST::int(key)
    else
      assert { false }
    end
  AST::function_call [key], dot(expr, "__lookup__")
end

def schema_for(expr)
  AST::function_call [expr], dot(schema, "for")
end

def schema_any(name)
  AST::function_call [AST::sym(name)], dot(schema, "any")
end

def throw_match_error
  AST::throw(AST::str("Match error"))
end

def parse(str)
  tokens = Lexer::tokenize(str.strip)
  ast = Parser.new(tokens).parse!
  AST::remove_numbers(ast)
end

def ast_eq(ast)
  eq(AST::remove_numbers(ast))
end

def init_module
  AST::assignment("pea_module", AST::record({}))
end

describe Parser do
  context "assignment" do
    it "a := 3" do
      ast = parse("a := 3")
      expect(ast).to ast_eq([
        init_module,
        AST::assignment("a", AST::int(3)),
      ])
    end
    it "a := \"3\"" do
      ast = parse("a := \"3\"")
      expect(ast).to ast_eq([
        init_module,
        AST::assignment("a", AST::str("3")),
      ])
    end
    it "a := 25.32" do
      ast = parse("a := 25.32")
      expect(ast).to ast_eq([
        init_module,
        AST::assignment("a", AST::float(25.32)),
      ])
    end
  end
  context "literals" do
    it "true" do
      ast = parse("true")
      expect(ast).to ast_eq([
        init_module,
        AST::bool(true),
      ])
    end
    it "false" do
      ast = parse("false")
      expect(ast).to ast_eq([
        init_module,
        AST::bool(false),
      ])
    end
    it ":symbol" do
      ast = parse(":symbol")
      expect(ast).to ast_eq([
        init_module,
        AST::sym("symbol"),
      ])
    end
    it "[]" do
      ast = parse("[]")
      expect(ast).to ast_eq([
        init_module,
        AST::array([]),
      ])
    end
    it "[false]" do
      ast = parse("[false]")
      expect(ast).to ast_eq([
        init_module,
        AST::array([AST::bool(false)]),
      ])
    end
    it "[false, 1, \"3\"]" do
      ast = parse("[false, 1, \"3\"]")
      expect(ast).to ast_eq([
        init_module,
        AST::array([
          AST::bool(false),
          AST::int(1),
          AST::str("3"),
        ]),
      ])
    end
    it "{ a: 3.5 }" do
      ast = parse("{ a: 3.5 }")
      expect(ast).to ast_eq([
        init_module,
        # TODO: shouldn't have to specify line & col #s
        AST::record({ AST::sym("a", 0, 2) => AST::float(3.5) }),
      ])
    end
    it "{a: [false, 1, \"3\"]}" do
      ast = parse("{a: [false, 1, \"3\"]}")
      expect(ast).to ast_eq([
        init_module,
        AST::record({ AST::sym("a", 0, 1) => AST::array([
          AST::bool(false),
          AST::int(1),
          AST::str("3"),
        ]) }),
      ])
    end
    it "[{ a: 3.5 }]" do
      ast = parse("[{ a: 3.5 }]")
      expect(ast).to ast_eq([
        init_module,
        AST::array([
          AST::record({ AST::sym("a", 0, 3) => AST::float(3.5) }),
        ]),
      ])
    end
  end
  context "functions" do
    it "a := do 1 end" do
      ast = parse("a := do 1 end")
      fn = AST::function([], [AST::return(AST::int(1))])
      expect(ast).to ast_eq([
        init_module,
        AST::assignment("a", fn),
      ])
    end
    it "id := do |x| x end" do
      ast = parse("id := do |x| x end")
      fn = AST::function(
        [AST::function_argument("x")],
        [AST::return(AST::identifier_lookup("x"))]
      )
      expect(ast).to ast_eq([
        init_module,
        AST::assignment("id", fn),
      ])
    end

    it "a + b" do
      ast = parse("a + b")
      expect(ast).to ast_eq([
        init_module,
        AST::function_call(
          [AST::identifier_lookup("b")],
          AST::dot(AST::identifier_lookup("a"), "__plus__"),
        ),
      ])
    end

    it "1.5 + 2.4" do
      ast = parse("1.5 + 2.4")
      expect(ast).to ast_eq([
        init_module,
        AST::function_call(
          [AST::float(2.4)],
          AST::dot(AST::float(1.5), "__plus__"),
        ),
      ])
    end

    it "def add(a, b) = a + b" do
      ast = parse("def add(a, b) = a + b")
      expect(ast).to ast_eq([
        init_module,
        AST::declare(
          "add",
          schema_for(AST::array([schema_any("a"), schema_any("b")])),
          AST::function(
            [AST::function_argument("__VALUE")],
            [
              AST::assignment("a", lookup(AST::identifier_lookup("__VALUE"), 0)),
              AST::assignment("b", lookup(AST::identifier_lookup("__VALUE"), 1)),
              AST::return(AST::function_call(
                [AST::identifier_lookup("b")],
                AST::dot(AST::identifier_lookup("a"), "__plus__"),
              )),
            ]
          )
        ),
      ])
    end
    it "def add(a, b)\n  return a + b\nend" do
      ast = parse("
        def add(a, b)
          return a + b
        end")
      expect(ast).to ast_eq([
        init_module,
        AST::declare(
          "add",
          schema_for(AST::array([schema_any("a"), schema_any("b")])),
          AST::function(
            [AST::function_argument("__VALUE")],
            [
              AST::assignment("a", lookup(AST::identifier_lookup("__VALUE"), 0)),
              AST::assignment("b", lookup(AST::identifier_lookup("__VALUE"), 1)),
              AST::return(AST::function_call(
                [AST::identifier_lookup("b")],
                AST::dot(AST::identifier_lookup("a"), "__plus__"),
              )),
            ]
          )
        ),
      ])
    end

    it "add(1, 2)" do
      ast = parse("add(1, 2)")
      expect(ast).to ast_eq(
        [
          init_module,
          AST::function_call(
            [AST::int(1), AST::int(2)],
            AST::identifier_lookup("add")
          ),
        ]
      )
    end
  end

  context "schemas:", :i do
    it "[a] := [1]" do
      ast = parse("[a] := [1]")
      arr = AST::array([AST::int(1)])
      expect(ast).to ast_eq([
        init_module,
        AST::if(
          schema_valid(schema_for(
            AST::array([schema_any("a")])
          ), arr),
          [AST::assignment("a", AST::lookup(arr, AST::int(0)))],
          [throw_match_error]
        ),
      ])
    end
    it "[a, b] := [1, :two]" do
      ast = parse("[a, b] := [1, :two]")
      arr = AST::array([AST::int(1), AST::sym("two")])
      expect(ast).to ast_eq([
        init_module,
        AST::if(
          schema_valid(schema_for(
            AST::array([schema_any("a"), schema_any("b")])
          ), arr),
          [
            AST::assignment("a", AST::lookup(arr, AST::int(0))),
            AST::assignment("b", AST::lookup(arr, AST::int(1))),
          ],
          [throw_match_error]
        ),
      ])
    end
    it "[[a]] := [[1]]" do
      ast = parse("[[a]] := [[1]]")
      arr = AST::array([AST::array([AST::int(1)])])
      expect(ast).to ast_eq([
        init_module,
        AST::if(
          schema_valid(schema_for(
            AST::array([AST::array([schema_any("a")])])
          ), arr),
          [
            AST::assignment("a", AST::lookup(AST::lookup(arr, AST::int(0)), AST::int(0))),
          ],
          [throw_match_error]
        ),
      ])
    end

    it "{a} := {a: 3}" do
      ast = parse("{a} := {a: 3}")
      obj = AST::record({ "a" => AST::int(3) })
      expect(ast).to ast_eq([
        init_module,
        AST::if(
          schema_valid(schema_for(
            AST::record({ "a" => schema_any("a") })
          ), obj),
          [AST::assignment("a", dot(obj, "a"))],
          [throw_match_error]
        ),
      ])
    end
  end

  context "if expressions" do
    it "if true end" do
      ast = parse("if true end")
      expect(ast).to ast_eq([
        init_module,
        AST::if(AST::bool(true), [], []),
      ])
    end
    it "if true else end" do
      ast = parse("if true else end")
      expect(ast).to ast_eq([
        init_module,
        AST::if(AST::bool(true), [], []),
      ])
    end
    it "if true else if false end" do
      ast = parse("if true else if false end")
      expect(ast).to ast_eq([
        init_module,
        AST::if(
          AST::bool(true),
          [],
          [AST::if(AST::bool(false), [], [])]
        ),
      ])
    end
  end

  context "case", :i do
    it "array single element" do
      ast = parse("
case [1] of
  [a] => a
end")
      value =
        expect(ast).to ast_eq(
          [
            init_module,
            AST::case(
              AST::array([AST::int(1)]),
              AST::array([
                AST::array([
                  schema_for(AST::array([schema_any("a")])),
                  AST::function(
                    [AST::function_argument("match_expr")],
                    [
                      AST::assignment("a", AST::lookup(AST::identifier_lookup("match_expr"), AST::int(0))),
                      AST::return(AST::identifier_lookup("a")),
                    ]
                  ),
                ]),
              ]),
            ),
          ]
        )
    end
  end
end
