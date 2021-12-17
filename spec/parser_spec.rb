require "lexer"
require "parser"
require "ast"

def add(line = nil, column = nil)
  { node_type: :property_lookup,
   line: line,
   column: nil, # TODO
   lhs_expr: {
    column: nil, # TODO
    line: line,
    node_type: :identifier_lookup,
    sym: "Peacock",
  },
   property: {
    column: column,
    line: line,
    node_type: :str_lit,
    value: "plus",
  } }
end

def parse(str)
  tokens = Lexer::tokenize(str.strip)
  ast = Parser.new(tokens).parse!
  AST::remove_numbers(ast)
end

def ast_eq(ast)
  eq(AST::remove_numbers(ast))
end

describe Parser do
  context "assignment" do
    it "a := 3" do
      ast = parse("a := 3")
      expect(ast).to ast_eq([
        AST::assignment("a", AST::int(3)),
      ])
    end
    it "a := \"3\"" do
      ast = parse("a := \"3\"")
      expect(ast).to ast_eq([
        AST::assignment("a", AST::str("3")),
      ])
    end
    it "a := 25.32" do
      ast = parse("a := 25.32")
      expect(ast).to ast_eq([
        AST::assignment("a", AST::float(25.32)),
      ])
    end
  end
  context "literals" do
    it "true" do
      ast = parse("true")
      expect(ast).to ast_eq([
        AST::bool(true),
      ])
    end
    it "false" do
      ast = parse("false")
      expect(ast).to ast_eq([
        AST::bool(false),
      ])
    end
    it ":symbol" do
      ast = parse(":symbol")
      expect(ast).to ast_eq([
        AST::sym("symbol"),
      ])
    end
    it "[]" do
      ast = parse("[]")
      expect(ast).to ast_eq([
        AST::array([]),
      ])
    end
    it "[false]" do
      ast = parse("[false]")
      expect(ast).to ast_eq([
        AST::array([AST::bool(false)]),
      ])
    end
    it "[false, 1, \"3\"]" do
      ast = parse("[false, 1, \"3\"]")
      expect(ast).to ast_eq([
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
        AST::record({ "a" => AST::float(3.5) }),
      ])
    end
    it "{a: [false, 1, \"3\"]}" do
      ast = parse("{a: [false, 1, \"3\"]}")
      expect(ast).to ast_eq([
        AST::record({ "a" => AST::array([
          AST::bool(false),
          AST::int(1),
          AST::str("3"),
        ]) }),
      ])
    end
    it "[{ a: 3.5 }]" do
      ast = parse("[{ a: 3.5 }]")
      expect(ast).to ast_eq([
        AST::array([
          AST::record({ "a" => AST::float(3.5) }),
        ]),
      ])
    end
  end
  context "functions" do
    it "a := fn => 1" do
      ast = parse("a := fn => 1")
      fn = AST::function([], [AST::return(AST::int(1))])
      expect(ast).to ast_eq([
        AST::assignment("a", fn),
      ])
    end
    it "id := fn x => x" do
      ast = parse("id := fn x => x")
      fn = AST::function(
        [AST::function_argument("x")],
        [AST::return(AST::identifier_lookup("x"))]
      )
      expect(ast).to ast_eq([
        AST::assignment("id", fn),
      ])
    end

    it "a + b" do
      ast = parse("a + b")
      expect(ast).to ast_eq([
        AST::function_call(
          [AST::identifier_lookup("a"), AST::identifier_lookup("b")],
          add(0, 2),
        ),
      ])
    end

    it "1.5 + 2.4" do
      ast = parse("1.5 + 2.4")
      expect(ast).to ast_eq([
        AST::function_call(
          [AST::float(1.5), AST::float(2.4)],
          add,
        ),
      ])
    end

    it "add a b = a + b" do
      ast = parse("add a b = a + b")
      expect(ast).to ast_eq([
        AST::declare(
          { sym: "add" },
          AST::function(
            [AST::function_argument("a"), AST::function_argument("b")],
            [AST::return(AST::function_call(
              [AST::identifier_lookup("a"), AST::identifier_lookup("b")],
              add
            ))]
          )
        ),
      ])
    end
    it "add a b =\n  return a + b" do
      ast = parse("
        add a b =
          return a + b")
      expect(ast).to ast_eq([
        AST::declare(
          { sym: "add" },
          AST::function(
            [AST::function_argument("a"), AST::function_argument("b")],
            [AST::return(AST::function_call(
              [AST::identifier_lookup("a"), AST::identifier_lookup("b")],
              add
            ))]
          )
        ),
      ])
    end

    it "add(1, 2)" do
      ast = parse("add(1, 2)")
      expect(ast).to ast_eq(
        [
          AST::function_call(
            [AST::int(1), AST::int(2)],
            AST::identifier_lookup("add")
          ),
        ]
      )
    end
  end

  context "if expressions" do
    it "if true end" do
      ast = parse("if true end")
      expect(ast).to ast_eq([
        AST::if(AST::bool(true), [], []),
      ])
    end
    it "if true else end" do
      ast = parse("if true else end")
      expect(ast).to ast_eq([
        AST::if(AST::bool(true), [], []),
      ])
    end
    it "if true else if false end" do
      ast = parse("if true else if false end")
      expect(ast).to ast_eq([
        AST::if(
          AST::bool(true),
          [],
          [AST::if(AST::bool(false), [], [])]
        ),
      ])
    end
  end
end
