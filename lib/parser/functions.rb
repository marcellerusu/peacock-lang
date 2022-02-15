module Functions
  def parse_bang!
    consume! :bang
    expr = parse_expr!
    AST::function_call [], AST::dot(expr, "bang")
  end

  def property_accessor?
    current_token.is_a?(:open_square_bracket) &&
      end_of_last_token == current_token.position
  end

  def function_call?(sym_expr)
    return true if current_token&.is_a? :open_parenthesis
    is_dot_expr = sym_expr[:node_type] == :property_lookup ||
                  sym_expr[:node_type] == :instance_method_lookup
    return false if !is_dot_expr
    return true if is_dot_expr && end_of_expr?
    cloned = clone
    begin
      cloned.parse_function_call_args_without_paren!
    rescue AssertionError
      return false
    else
      return true
    end
  end

  def parse_anon_function_shorthand!
    fn_start_token = consume! :anon_short_fn_start
    # binding.pry
    expr = parse_expr!
    assert { expr[:node_type] != :return }
    expr = AST::return(expr, fn_start_token.position) unless expr[:node_type] == :if
    consume! :close_brace
    args = [AST::function_argument(ANON_SHORTHAND_ID, fn_start_token.position)]
    AST::function args, [expr], fn_start_token.position
  end

  def parse_anon_short_id!
    id_token = consume! :anon_short_id
    sym_expr = AST::identifier_lookup(ANON_SHORTHAND_ID, id_token.position)
    parse_id_modifier_if_exists!(sym_expr)
  end

  def parse_function_args_schema!
    args = []
    matches = []
    # in case of
    # def f = 0
    # OR
    # def f
    #   function_code()
    # end
    if current_token.is_a?(:"=") || new_line?
      args_schema = function_call [AST::array(args)], schema_for
      return args_schema, matches
    end
    list_schema_index = 0
    consume! :open_parenthesis
    expr_context.push! :declare
    while current_token.is_not_a?(:close_parenthesis)
      schema, new_matches = parse_schema_literal! list_schema_index
      args.push schema
      consume! :comma if current_token.is_not_a? :close_parenthesis
      matches += new_matches
      list_schema_index += 1
    end
    expr_context.pop! :declare
    consume! :close_parenthesis
    args_schema = function_call [AST::array(args)], schema_for
    return args_schema, matches
  end

  def parse_function_def!
    consume! :def
    id_token = consume! :identifier
    args_schema, matches = parse_function_args_schema!
    is_single_expr = false
    if current_token.is_a? :"="
      is_single_expr = true
      consume! :"="
    end

    if new_line?
      assert { !is_single_expr }
      @token_index, body = clone(parser_context: parser_context.push(:function)).parse_with_position!
      consume! :end
    else
      expr = parse_expr!
      body = [AST::return(expr)]
    end
    body = matches.map do |path_and_sym|
      sym, path = path_and_sym.last, path_and_sym[0...-1]
      AST::assignment(
        sym,
        eval_path_on_expr(path, AST::identifier_lookup("__VALUE"))
      )
    end + body
    function = AST::function([AST::function_argument("__VALUE")], body, id_token.position)
    AST::declare(id_token.value, args_schema, function, id_token.position)
  end

  def parse_anon_function_def!
    do_token = consume! :do
    args = []
    if current_token.is_a? :"|"
      consume! :"|"
      while current_token.is_not_a?(:"|")
        id_token = consume! :identifier
        args.push AST::function_argument(id_token.value, id_token.position)
        consume! :comma if current_token.is_not_a? :"|"
      end
      consume! :"|"
    end
    @token_index, body = clone(parser_context: parser_context.push(:function)).parse_with_position!
    consume! :end
    AST::function args, body, do_token.position
  end

  def parse_function_call_args_with_paren!
    consume! :open_parenthesis
    args = []
    while current_token.is_not_a? :close_parenthesis
      args.push parse_expr!
      consume! :comma if current_token.is_not_a? :close_parenthesis
    end
    consume! :close_parenthesis
    args
  end

  def parse_function_call_args_without_paren!
    args = []
    return args if current_token&.is_a? :comma
    until end_of_expr?
      args.push parse_expr!
      # TODO: shouldn't this be a break?
      next if current_token&.is_a? :do
      break if end_of_expr?(:comma)
      consume! :comma
    end
    args
  end

  def parse_function_call!(fn_expr)
    args = if current_token&.is_a? :open_parenthesis
        parse_function_call_args_with_paren!
      else
        parse_function_call_args_without_paren!
      end
    return AST::or_lookup(fn_expr, args) if fn_expr[:node_type] == :instance_method_lookup
    return parse_match_assignment!(fn_expr, args[0]) if args.size == 1 && current_token&.is_a?(:assign)
    AST::function_call args, fn_expr, fn_expr[:position]
  end
end
