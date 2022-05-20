require "lexer"
require "parser"
require "ast"
require "compiler"

def parse(str)
  tokens = Lexer::tokenize(str.strip)
  ast = Parser.new(tokens, str).parse!
  ast.map(&:to_h)
end

def ast_eq(ast)
  eq(ast.map(&:to_h))
end

describe Parser do
  context "assignment" do
    it "a := 3" do
      ast = parse("a := 3")
      expect(ast).to ast_eq([
        AST::Assign.new("a", AST::Int.new(3, nil), nil),
      ])
    end
    it "a := \"3\"" do
      ast = parse("a := \"3\"")
      expect(ast).to ast_eq([
        AST::Assign.new("a", AST::Str.new("3", nil), nil),
      ])
    end
    it "a := 25.32" do
      ast = parse("a := 25.32")
      expect(ast).to ast_eq([
        AST::Assign.new("a", AST::Float.new(25.32, nil), nil),
      ])
    end
  end
  context "literals" do
    it "true" do
      ast = parse("true")
      expect(ast).to ast_eq([
        AST::Bool.new(true, nil),
      ])
    end
    it "false" do
      ast = parse("false")
      expect(ast).to ast_eq([
        AST::Bool.new(false, nil),
      ])
    end
    it "[]" do
      ast = parse("[]")
      expect(ast).to ast_eq([
        AST::ArrayLiteral.new([], nil),
      ])
    end
    it "[false]" do
      ast = parse("[false]")
      expect(ast).to ast_eq([
        AST::ArrayLiteral.new([AST::Bool.new(false, nil)], nil),
      ])
    end
    it "[false, 1, \"3\"]" do
      ast = parse("[false, 1, \"3\"]")
      expect(ast).to ast_eq([
        AST::ArrayLiteral.new([
          AST::Bool.new(false, nil),
          AST::Int.new(1, nil),
          AST::Str.new("3", nil),
        ], nil),
      ])
    end
    it "{ a: 3.5 }" do
      ast = parse("{ a: 3.5 }")
      expect(ast).to ast_eq([
        # TODO: shouldn't have to specify line & col #s
        AST::ObjectLiteral.new([
          [AST::Str.new("a", 2), AST::Float.new(3.5, nil)],
        ], [], 0),
      ])
    end
    it "{a: [false, 1, \"3\"]}" do
      ast = parse("{a: [false, 1, \"3\"]}")
      expect(ast).to ast_eq([
        AST::ObjectLiteral.new([
          [AST::Str.new("a", 1), AST::ArrayLiteral.new([
            AST::Bool.new(false, nil),
            AST::Int.new(1, nil),
            AST::Str.new("3", nil),
          ])],
        ], [], nil),
      ])
    end
    it "[{ a: 3.5 }]" do
      ast = parse("[{ a: 3.5 }]")
      expect(ast).to ast_eq([
        AST::ArrayLiteral.new([
          AST::ObjectLiteral.new(
            [[AST::Str.new("a", 3), AST::Float.new(3.5, nil)]],
            [], nil
          ),
        ]),
      ])
    end
  end
  context "functions" do
    it "a := do 1 end" do
      ast = parse("a := do 1 end")
      fn = AST::Fn.new([], [AST::Return.new(AST::Int.new(1, nil), nil)], nil)
      expect(ast).to ast_eq([
        AST::Assign.new("a", fn),
      ])
    end
    it "id := do |x| x end" do
      ast = parse("id := do |x| x end")
      fn = AST::Fn.new(
        ["x"],
        [AST::Return.new(AST::IdLookup.new("x", nil), nil)],
        nil
      )
      expect(ast).to ast_eq([
        AST::Assign.new("id", fn),
      ])
    end

    it "a + b" do
      ast = parse("a + b")
      expect(ast).to ast_eq([
        AST::Add.new(
          AST::IdLookup.new("a", nil),
          AST::IdLookup.new("b", nil),
          nil
        ),
      ])
    end

    it "1.5 + 2.4" do
      ast = parse("1.5 + 2.4")
      expect(ast).to ast_eq([
        AST::Add.new(
          AST::Float.new(1.5, nil),
          AST::Float.new(2.4, nil),
          nil
        ),

      ])
    end

    it "def add(a, b) = a + b", :f do
      ast = parse("def add(a, b) = a + b")
      expect(ast).to ast_eq([
        AST::Declare.new(
          "add",
          AST::ArrayLiteral.new([AST::schema_any("a"), AST::schema_any("b")]).to_schema,
          AST::Fn.new(
            ["__VALUE"],
            [
              AST::Assign.new("a", AST::IdLookup.new("__VALUE", nil).lookup(AST::Int.new(0, nil)), nil),
              AST::Assign.new("b", AST::IdLookup.new("__VALUE", nil).lookup(AST::Int.new(1, nil)), nil),
              AST::Return.new(
                AST::IdLookup.new("a", nil)
                  .dot("__plus__").call([AST::IdLookup.new("b", nil)])
              ),
            ],
            nil
          ),
          nil
        ),
      ])
    end
    it "def add(a, b)\n  return a + b\nend" do
      ast = parse("
        def add(a, b)
          return a + b
        end")
      expect(ast).to ast_eq([
        AST::Declare.new(
          "add",
          AST::ArrayLiteral.new([AST::schema_any("a"), AST::schema_any("b")]).to_schema,
          AST::Fn.new(
            ["__VALUE"],
            [
              AST::Assign.new("a", AST::IdLookup.new("__VALUE", nil).lookup(AST::Int.new(0, nil)), nil),
              AST::Assign.new("b", AST::IdLookup.new("__VALUE", nil).lookup(AST::Int.new(1, nil)), nil),
              AST::IdLookup.new("a", nil)
                .dot("__plus__")
                .call([AST::IdLookup.new("b", nil)])
                .to_return,
            ],
            nil
          ),
          nil
        ),
      ])
    end

    it "add(1, 2)" do
      ast = parse("add(1, 2)")
      expect(ast).to ast_eq(
        [
          AST::IdLookup.new("add", nil)
            .call([AST::Int.new(1, nil), AST::Int.new(2, nil)]),
        ]
      )
    end
  end

  context "schemas:", :i do
    it "[a] := [1]" do
      ast = parse("[a] := [1]")
      arr = AST::array([AST::int(1)])
      expect(ast).to ast_eq([
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
        AST::If.new(AST::Bool.new(true, nil), [], [], nil),
      ])
    end
    it "if true else end" do
      ast = parse("if true else end")
      expect(ast).to ast_eq([
        AST::If.new(AST::Bool.new(true, nil), [], [], nil),
      ])
    end
    it "if true else if false end" do
      ast = parse("if true else if false end")
      expect(ast).to ast_eq([
        AST::If.new(
          AST::Bool.new(true, nil),
          [],
          [AST::If.new(AST::Bool.new(false, nil), [], [], nil)],
          nil
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
