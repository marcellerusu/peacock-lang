require "lexer"
require "digest"

module Modules
  def module_def
    AST::assignment "pea_module", AST::record({})
  end

  def parse_import!
    consume! :import
    expr_context.push! :schema
    pattern = parse_expr!
    expr_context.pop! :schema
    consume! :from
    str_token = consume! :str_lit
    file_name = str_token.value
    file_name = "#{file_name}.pea" if !file_name.end_with? ".pea"
    assert { str_token.captures.size == 0 }
    program = File.read(file_name)
    # when we start doing hot reloading
    # we should use a mutation of the file name as the variable
    # store the sha somewhere else, that way we can invalidate old code
    var_name = Digest::SHA1.hexdigest program
    if !var_name[0].match(/[a-z]/)
      var_name = var_name.match(/[0-9]([a-z][a-z0-9]+)/)[1]
    end
    if computed_files.include? var_name
      return [parse_match_assignment_without_schema!(pattern, AST::identifier_lookup(var_name))]
    else
      computed_files.push var_name
      tokens = Lexer::tokenize program
      ast = Parser.new(tokens, program, 0, nil, nil, false).parse!
      file_expr = AST::function_call(
        [],
        AST::function(
          [],
          [*ast, AST::return(AST::identifier_lookup("pea_module"))]
        )
      )
      file_assign = AST::assignment(var_name, file_expr)
      match_expr = parse_match_assignment_without_schema! pattern, AST::identifier_lookup(var_name)
      return [file_assign, match_expr]
    end
  end

  def parse_export!
    export = consume! :export
    expr = parse_expr!
    assert { [:assign, :declare, :class].include?(expr[:node_type]) }
    assignment = AST::function_call(
      [
        AST::sym(expr[:sym], export.position),
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
