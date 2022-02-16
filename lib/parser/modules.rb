require "lexer"
require "digest"

module Modules
  def module_def
    AST::Assign.new "pea_module", AST::Record.new([], AST::List.new([]), 0), 0
  end

  def parse_import!
    import = consume! :import
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
      file_expr = AST::IdLookup.new("pea_module", import.position)
        .to_return
        .wrap_in_fn_with(ast)
        .call
      file_assign = AST::Assign.new(var_name, file_expr)
      match_expr = parse_match_assignment_without_schema! pattern, AST::IdLookup.new(var_name, import.position)
      return [file_assign, match_expr]
    end
  end

  def parse_export!
    export = consume! :export
    expr = parse_expr!
    assert { expr.exportable? }
    assignment = AST::IdLookup.new("pea_module", expr.position)
      .dot("__unsafe_insert__")
      .call([
        AST::Sym.new(expr.name, export.position),
        AST::IdLookup.new(expr.name, expr.position),
      ])

    [expr, assignment]
  end
end
