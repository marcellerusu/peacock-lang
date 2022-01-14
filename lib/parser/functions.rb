module Functions
  def is_function?(skip = 0)
    return false if peek_token(-1 + skip)[0] != self.line
    return false if peek_type(-1 + skip) != :identifier
    # skip params
    i = 0
    t = peek_token(i + skip)
    return false if t.nil?

    while t && t[2] == :identifier
      i += 1
      t = peek_token(i + skip)
    end
    self.line == t[0] && peek_type(i + skip) == :declare
  end

  def parse_bang!
    consume! :bang
    expr = parse_expr!
    AST::function_call [], AST::dot(expr, "bang")
  end

  def property_accessor?
    peek_type == :open_square_bracket &&
    end_of_last_token == column
  end

  def is_function_call?(sym_expr)
    return true if peek_type == :open_parenthesis
    is_dot_expr = sym_expr[:node_type] == :property_lookup ||
                  sym_expr[:node_type] == :instance_method_lookup
    return false if !is_dot_expr
    return true if is_dot_expr && end_of_expr?
    cloned = clone
    begin
      while cloned.line == line
        cloned.parse_expr!
        break if cloned.end_of_expr?
        cloned.consume! :comma
      end
    rescue AssertionError
      return false
    else
      return true
    end
  end

  def parse_anon_function_shorthand!
    line, c = self.line, column
    consume! :anon_short_fn_start
    expr = parse_expr!
    assert { expr[:node_type] != :return }
    expr = AST::return(expr, line, c)
    consume! :close_brace
    args = [AST::function_argument(ANON_SHORTHAND_ID, line, c)]
    AST::function args, [expr], line, c
  end

  def parse_anon_short_id!
    line, c = consume! :anon_short_id
    sym_expr = AST::identifier_lookup(ANON_SHORTHAND_ID, line, c)
    parse_id_modifier_if_exists!(sym_expr)
  end

  def parse_function_arguments!(end_type)
    args = []
    while peek_type != end_type
      line, c1, sym = consume! :identifier
      args.push AST::function_argument(sym, line, c1)
    end
    args
  end

  def parse_function_def!(sym_expr)
    args = parse_function_arguments! :declare
    consume! :declare
    fn_line = line
    if new_line?
      @token_index, body = clone(
        indentation: @indentation + 2,
        parser_context: parser_context.clone.push!(:function),
      ).parse_with_position!
    else
      return_c = column
      expr = parse_expr!
      body = [AST::return(expr, self.line, return_c)]
    end

    function = AST::function(args, body, fn_line, sym_expr[:column])
    AST::declare(sym_expr, function)
  end

  def parse_anon_function_def!
    _, c, _ = consume! :fn
    args = parse_function_arguments! :arrow
    consume! :arrow
    fn_line = self.line
    expr_context.push! :function
    expr = parse_expr!
    expr_context.pop! :function
    body = [AST::return(expr, self.line, expr[:column])]
    # TODO: none 1-liners
    AST::function args, body, fn_line, c
  end

  def parse_function_call_args_with_paren!
    consume! :open_parenthesis
    args = []
    while peek_type != :close_parenthesis
      args.push parse_expr!
      consume! :comma unless peek_type == :close_parenthesis
    end
    consume! :close_parenthesis
    args
  end

  def parse_function_call_args_without_paren!
    args = []
    until end_of_expr?
      args.push parse_expr!
      break if end_of_expr?
      consume! :comma
    end
    args
  end

  def try_lookup(sym, line, c)
    raw_str = { node_type: :str_lit,
                line: line,
                column: c,
                value: sym }
    AST::function_call(
      [AST::function(
        [],
        [AST::return(AST::function_call([raw_str], AST::identifier_lookup("eval")))]
      )],
      AST::identifier_lookup("__try")
    )
  end

  def or_lookup(node)
    line, c = node[:line], node[:column]
    AST::naked_or(
      try_lookup(node[:sym], line, c),
      AST::function_call([], node, line, c)
    )
  end

  def parse_function_call!(fn_expr)
    args = if peek_type == :open_parenthesis
        parse_function_call_args_with_paren!
      else
        parse_function_call_args_without_paren!
      end
    return or_lookup(fn_expr) if args.size == 0 && fn_expr[:node_type] == :instance_method_lookup
    return parse_match_assignment!(fn_expr, args[0]) if args.size == 1 && peek_type == :assign
    AST::function_call args, fn_expr, fn_expr[:line], fn_expr[:column]
  end
end
