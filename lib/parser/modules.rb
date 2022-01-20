require "lexer"

module Modules
  def module_def
    AST::assignment "pea_module", AST::record([])
  end

  def parse_import!
    consume! :import
    expr_context.push! :schema
    pattern = parse_expr!
    expr_context.pop! :schema
    consume! :from
    line, c, file_name, _, tokens = consume! :str_lit
    file_name = "#{file_name}.pea" if !file_name.end_with? ".pea"
    assert { tokens.size == 0 }
    program = File.read(file_name)
    tokens = Lexer::tokenize program
    ast = Parser.new(tokens).parse!
    file_expr = AST::function_call(
      [],
      AST::function(
        [],
        [
          *ast,
          AST::return(AST::identifier_lookup("pea_module")),
        ]
      )
    )
    parse_match_assignment_without_schema! pattern, file_expr
  end

  def parse_export!
    line, c = consume! :export
    expr = parse_expr!
    assert { [:assign, :declare, :class].include?(expr[:node_type]) }
    assignment = AST::function_call(
      [
        AST::sym(expr[:sym], line, c),
        AST::identifier_lookup(expr[:sym]),
      ],
      AST::dot(
        AST::identifier_lookup("pea_module"),
        "__unsafe_insert__"
      )
    )

    [expr, assignment]
  end
end
