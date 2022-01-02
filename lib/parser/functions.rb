module Functions
  def is_function?
    # skip params
    i = 0
    t, line = peek_token(i)
    while t && t[1] == :identifier
      i += 1
      t, line = peek_token(i)
    end
    @line == line && peek_type(i) == :declare
  end

  def is_function_call?(sym_expr)
    return true if peek_type == :open_parenthesis
    is_dot_expr = sym_expr[:node_type] == :property_lookup
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
    line, c = @line, @column
    consume! :anon_short_fn_start
    expr = parse_expr!
    expr = AST::return(expr, line, c) unless expr[:node_type] == :return
    consume! :close_brace
    args = [AST::function_argument(ANON_SHORTHAND_ID, line, c)]
    AST::function args, [expr], line, c
  end

  def parse_anon_short_id!
    consume! :anon_short_id
    sym_expr = AST::identifier_lookup(ANON_SHORTHAND_ID, @line, @column)
    parse_id_modifier_if_exists!(sym_expr)
  end

  def parse_function_arguments!(end_type)
    args = []
    while peek_type != end_type
      c1, sym = consume! :identifier
      args.push AST::function_argument(sym, @line, c1)
    end
    args
  end

  def parse_function_def!(sym_expr)
    args = parse_function_arguments! :declare
    consume! :declare
    fn_line = @line
    if new_line?
      next_line!
      @line, @token_index, body = Parser.new(@statements, @line, @token_index, @indentation + 2, :declare).parse_with_position!
    else
      return_c = column
      expr = parse_expr!
      body = [AST::return(expr, @line, return_c)]
    end

    function = AST::function(args, body, fn_line, sym_expr[:column])
    AST::declare(sym_expr, function)
  end

  def parse_anon_function_def!
    c, _ = consume! :fn
    args = parse_function_arguments! :arrow
    consume! :arrow
    fn_line = @line
    expr = parse_expr!
    body = [AST::return(expr, @line, expr[:column])]
    # TODO: none 1-liners
    # @line, @token_index, body = Parser.new(@statements, @line, @token_index).parse_with_position!
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

  def parse_function_call!(fn_expr)
    args = if peek_type == :open_parenthesis
        parse_function_call_args_with_paren!
      else
        parse_function_call_args_without_paren!
      end
    return parse_match_assignment!(fn_expr, args[0]) if args.size == 1 && peek_type == :assign
    AST::function_call args, fn_expr, fn_expr[:line], fn_expr[:column]
  end
end
